import os

# 1. Khấu trừ cờ môi trường ngay từ đầu để tránh lỗi PyTorch pin memory / GPU CUDA Allocation
os.environ["HF_HUB_DISABLE_PROGRESS_BARS"] = "1"
os.environ["CUDA_VISIBLE_DEVICES"] = "-1"  # Ép PyTorch/EasyOCR chạy CPU thuần 100%

import shutil
import traceback
import uuid
from datetime import datetime, timedelta
from pathlib import Path
from threading import Lock
from typing import Any, Dict, Optional, List

from fastapi import FastAPI, UploadFile, File, HTTPException, Form, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn

# 🎯 ĐỊNH NGHĨA CÁC ĐƯỜNG DẪN DỰ ÁN
PROJECT_DIR = Path(__file__).resolve().parent          # Thư mục QuestLex/AI
ROOT_DIR = PROJECT_DIR.parent                          # Thư mục gốc QuestLex
DB_DIR = ROOT_DIR / "user_history" / "vocab_app.db"     # Thư mục SQLite CSDL
IMAGES_DIR = ROOT_DIR / "images"                       # Thư mục chứa ảnh chụp màn hình dùng chung
TEMP_UPLOAD_DIR = PROJECT_DIR / "temp_uploads"

# Tự động tạo các thư mục nếu chưa có
DB_DIR.parent.mkdir(parents=True, exist_ok=True)
IMAGES_DIR.mkdir(parents=True, exist_ok=True)
TEMP_UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

# 🎯 IMPORT CÁC ENGINE DỮ LIỆU
from ocr_extractor import OCRExtractor
from vocab_extractor import VocabularyExtractor
from revision_engine import RevisionEngine
from model_preloader import start_preload, get_ocr_engine, get_vocab_engine  # Sử dụng bộ nạp ngầm từ AI_v4
from image_quick_filter import ImageQuickFilter

# 🎯 KHỞI TẠO FASTAPI APP
app = FastAPI(title="QuestLex AI Backend API - Background Scanning Enabled")

# Cấu hình CORS cho phép kết nối từ Flutter Windows
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 🎯 KHỞI TẠO AI ENGINES
print("⏳ [AI_v6 Preloader]: Đang khởi chạy nạp mô hình AI ngầm...")
start_preload()  # Kích hoạt preloader AI từ model_preloader.py

db = RevisionEngine(str(DB_DIR))
DEFAULT_USER_ID = "user_dev_01"

print(f"📍 Database path: {DB_DIR.resolve()}")
print(f"📍 Shared Images path: {IMAGES_DIR.resolve()}")
print("✅ Server API sẵn sàng nhận lệnh từ Flutter!")

# 🎯 TRẠNG THÁI QUÉT NGẦM TOÀN CỤC (GLOBAL STATE)
scan_state_lock = Lock()
active_scan_job_id: Optional[str] = None
scan_jobs: Dict[str, Dict[str, Any]] = {}


def _debug(message: str) -> None:
    print(f"[AI DEBUG] {message}", flush=True)


def _reserve_scan_job(user_id: str) -> tuple[str, bool]:
    global active_scan_job_id
    with scan_state_lock:
        active_job = scan_jobs.get(active_scan_job_id) if active_scan_job_id else None
        if active_job and active_job.get("status") in {"queued", "scanning"}:
            _debug(f"job_reused job_id={active_job['job_id']} status={active_job['status']}")
            return active_job["job_id"], False

        job_id = uuid.uuid4().hex
        active_scan_job_id = job_id
        scan_jobs[job_id] = {
            "job_id": job_id,
            "user_id": user_id,
            "status": "queued",
            "processed_images_count": 0,
            "total_images_count": 0,
            "skipped_duplicate_count": 0,
            "skipped_low_quality_count": 0,
            "total_vocab_found": 0,
            "last_error": None,
        }
        _debug(f"job_reserved job_id={job_id} user_id={user_id}")
        return job_id, True


def _update_scan_job(job_id: str, **changes: Any) -> None:
    with scan_state_lock:
        if job_id in scan_jobs:
            scan_jobs[job_id].update(changes)
            if "status" in changes:
                _debug(f"job_status job_id={job_id} status={changes['status']}")


def _get_scan_job(job_id: str) -> Optional[Dict[str, Any]]:
    with scan_state_lock:
        job = scan_jobs.get(job_id)
        return dict(job) if job else None

# ----------------------------------------------------
# SCHEMAS (REQUEST MODELS)
# ----------------------------------------------------
class SetLevelRequest(BaseModel):
    user_id: Optional[str] = DEFAULT_USER_ID
    level: str  # "A1", "A2", "B1", "B2", "C1", "C2"

class ReviewWordRequest(BaseModel):
    user_id: Optional[str] = DEFAULT_USER_ID
    word: str
    quality: int  # Chấm điểm nhớ từ (1 -> 4)

# ----------------------------------------------------
# BACKGROUND TASK FUNCTION
# ----------------------------------------------------
def perform_background_scan(user_id: str, job_id: str):
    """Tiến trình quét thư mục ảnh chạy độc lập dưới nền ngầm"""
    global active_scan_job_id
    _update_scan_job(job_id, status="scanning")
    _debug(f"scan_started job_id={job_id} user_id={user_id}")
    
    try:
        print(f"🧠 [Background Scanner]: Bắt đầu quét folder images/ ngầm cho user: {user_id}")
        
        if not IMAGES_DIR.exists():
            _debug(f"scan_failed job_id={job_id} reason=images_directory_missing")
            _update_scan_job(
                job_id,
                status="failed",
                last_error=f"Thư mục {IMAGES_DIR} chưa tồn tại!",
            )
            return

        valid_extensions = ('.png', '.jpg', '.jpeg', '.bmp', '.webp')
        image_files = [f for f in IMAGES_DIR.iterdir() if f.suffix.lower() in valid_extensions]
        _update_scan_job(job_id, total_images_count=len(image_files))
        _debug(f"images_discovered job_id={job_id} count={len(image_files)}")
        print(f"🖼️ [Background Scanner]: Phát hiện {len(image_files)} file ảnh trong thư mục images/")

        if not image_files:
            _debug(f"scan_empty job_id={job_id}")
            _update_scan_job(job_id, status="completed")
            return

        # Lấy các AI Engine đã ấm sẵn từ preloader (Tránh block RAM/CPU)
        _debug(f"models_waiting job_id={job_id}")
        ocr_engine = get_ocr_engine()
        vocab_engine = get_vocab_engine()
        _debug(
            f"models_ready job_id={job_id} ocr={ocr_engine is not None} "
            f"vocab={vocab_engine is not None}"
        )

        if ocr_engine is None or vocab_engine is None:
            _update_scan_job(
                job_id,
                status="failed",
                last_error="Mô hình AI chưa khởi động xong.",
            )
            return

        selected_level = db.get_user_level(user_id) or "A1"
        user_profile = db.get_user_history_for_extractor(user_id) or {}
        _debug(f"profile_loaded job_id={job_id} level={selected_level}")
        all_detected_vocab = []
        quick_filter = ImageQuickFilter()
        seen_hashes = []
        _debug(f"quick_filter_ready job_id={job_id}")

        for img_path in image_files:
            try:
                filter_result, image_hash = quick_filter.classify(img_path, seen_hashes)
                _debug(f"quick_filter_result job_id={job_id} file={img_path.name} result={filter_result}")
                if filter_result == "duplicate":
                    job = _get_scan_job(job_id) or {}
                    _update_scan_job(
                        job_id,
                        skipped_duplicate_count=job.get("skipped_duplicate_count", 0) + 1,
                    )
                    print(f"⏭️ [Quick Filter]: Bỏ ảnh trùng {img_path.name}")
                    continue

                if filter_result == "low_quality":
                    job = _get_scan_job(job_id) or {}
                    _update_scan_job(
                        job_id,
                        skipped_low_quality_count=job.get("skipped_low_quality_count", 0) + 1,
                    )
                    print(f"⏭️ [Quick Filter]: Bỏ ảnh chất lượng thấp {img_path.name}")
                    continue

                if image_hash is not None:
                    seen_hashes.append(image_hash)

                print(f"🔍 [Background OCR Processing]: {img_path.name}")
                _debug(f"ocr_started job_id={job_id} file={img_path.name}")
                extracted_text, conf = ocr_engine.extract_text_from_image(str(img_path))
                _debug(
                    f"ocr_finished job_id={job_id} file={img_path.name} "
                    f"confidence={conf:.4f} text_chars={len(extracted_text or '')}"
                )
                
                if extracted_text and extracted_text.strip():
                    _debug(f"vocab_extract_started job_id={job_id} file={img_path.name}")
                    top_vocab = vocab_engine.process_text(
                        text=extracted_text,
                        user_history=user_profile,
                        top_k=None,
                        score_threshold=0.45,
                        level=selected_level
                    )
                    _debug(
                        f"vocab_extract_finished job_id={job_id} file={img_path.name} "
                        f"count={len(top_vocab)}"
                    )
                    
                    for item in top_vocab:
                        db.add_word_to_study(
                            user_id=user_id,
                            word=item.get('word', ''),
                            pos=item.get('pos', 'NOUN'),
                            definition=item.get('definition', ''),
                            synonyms=item.get('synonyms', []),
                            context_example=item.get('context_example', ''),
                            level=item.get('level', 'A1'),
                            mastery_score=item.get('mastery_score', 0.0),
                            vietnamese_meaning=item.get('vietnamese_meaning', '')
                        )
                        all_detected_vocab.append(item)
                    _debug(f"database_write_finished job_id={job_id} file={img_path.name} count={len(top_vocab)}")
                else:
                    _debug(f"ocr_empty job_id={job_id} file={img_path.name}")
                
                job = _get_scan_job(job_id) or {}
                _update_scan_job(
                    job_id,
                    processed_images_count=job.get("processed_images_count", 0) + 1,
                )
            except Exception as file_err:
                _debug(f"file_failed job_id={job_id} file={img_path.name} error={file_err}")
                print(f"⚠️ [Background Scanner] Lỗi xử lý file {img_path.name}: {file_err}")
                traceback.print_exc()
            finally:
                # 🎯 XÓA ẢNH KHỎI FOLDER SAU KHI XỬ LÝ (Khối finally luôn xóa kể cả khi lỗi)
                try:
                    if img_path.exists():
                        img_path.unlink()
                        _debug(f"file_deleted job_id={job_id} file={img_path.name}")
                        print(f"🗑️ [Background Scanner]: Đã dọn dẹp ảnh tạm: {img_path.name}")
                except Exception as del_err:
                    print(f"⚠️ [Background Scanner]: Không thể xóa file {img_path.name}: {del_err}")

        _update_scan_job(
            job_id,
            status="completed",
            total_vocab_found=len(all_detected_vocab),
        )
        print(f"✅ [Background Scanner Hoàn tất]: Đã trích xuất & lưu {len(all_detected_vocab)} từ vựng mới vào DB.")
        _debug(f"scan_completed job_id={job_id} vocab_count={len(all_detected_vocab)}")

    except Exception as e:
        _debug(f"scan_failed job_id={job_id} error={e}")
        traceback.print_exc()
        _update_scan_job(job_id, status="failed", last_error=str(e))
    finally:
        with scan_state_lock:
            if active_scan_job_id == job_id:
                active_scan_job_id = None
        _debug(f"scan_released job_id={job_id}")

# ----------------------------------------------------
# API ENDPOINTS
# ----------------------------------------------------

@app.get("/")
def health_check():
    return {
        "status": "online",
        "message": "QuestLex Local AI Server is running",
        "images_path": str(IMAGES_DIR.resolve())
    }

# 🛠️ USER PROFILE & LEVEL
@app.get("/api/user/level")
def get_user_level(user_id: str = DEFAULT_USER_ID):
    level = db.get_user_level(user_id)
    return {"success": True, "level": level or "A1"}

@app.post("/api/user/level")
def set_user_level(data: SetLevelRequest):
    db.save_user_level(data.user_id, data.level)
    return {"success": True, "message": f"Đã cập nhật level thành {data.level}"}

# 🚀 1. TỰ ĐỘNG KHỞI CHẠY QUÉT THƯ MỤC IMAGES CHẠY LUỒNG NỀN BẤT ĐỒNG BỘ
@app.post("/api/scan-images-folder")
async def scan_images_folder(background_tasks: BackgroundTasks, user_id: str = DEFAULT_USER_ID):
    print(f"📥 [API RECEIVED]: Nhận lệnh quét folder images/ cho user: {user_id}")
    _debug(f"scan_request_received user_id={user_id}")

    job_id, created = _reserve_scan_job(user_id)
    if not created:
        active_job = _get_scan_job(job_id) or {}
        return {
            "success": False,
            "status": active_job.get("status", "scanning"),
            "job_id": job_id,
            "message": "Hệ thống đang trong quá trình quét ảnh trước đó. Vui lòng đợi.",
        }

    background_tasks.add_task(perform_background_scan, user_id, job_id)
    _debug(f"background_task_queued job_id={job_id}")

    return {
        "success": True,
        "status": "started",
        "job_id": job_id,
        "message": "Quá trình quét ảnh đã được khởi động chạy ngầm thành công.",
    }

# 📊 THEO DÕI TIẾN TRÌNH QUÉT CHẠY NGẦM DÀNH CHO FLUTTER POLLING
@app.get("/api/scan-status")
def get_scan_status(job_id: Optional[str] = None):
    _debug(f"status_requested job_id={job_id or 'active'}")
    with scan_state_lock:
        requested_job_id = job_id or active_scan_job_id
        job = scan_jobs.get(requested_job_id) if requested_job_id else None

    if job is None:
        return {
            "success": True,
            "job_id": job_id,
            "is_scanning": False,
            "status": "idle",
            "processed_images_count": 0,
            "total_images_count": 0,
            "skipped_duplicate_count": 0,
            "skipped_low_quality_count": 0,
            "total_vocab_found": 0,
            "last_error": None,
        }

    result = dict(job)
    result["success"] = True
    result["is_scanning"] = result["status"] in {"queued", "scanning"}
    return result

# 📸 2. XỬ LÝ UPLOAD 1 ẢNH ĐƠN
@app.post("/api/process-image")
async def process_image(
    file: UploadFile = File(...),
    user_id: str = Form(DEFAULT_USER_ID)
):
    try:
        temp_image_path = TEMP_UPLOAD_DIR / file.filename
        with open(temp_image_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        ocr_engine = get_ocr_engine()
        vocab_engine = get_vocab_engine()
        extracted_text, conf = ocr_engine.extract_text_from_image(str(temp_image_path))
        selected_level = db.get_user_level(user_id) or "A1"
        user_profile = db.get_user_history_for_extractor(user_id)

        top_vocab = vocab_engine.process_text(
            text=extracted_text,
            user_history=user_profile,
            top_k=None,
            score_threshold=0.45,
            level=selected_level
        )

        return {
            "success": True,
            "ocr_text": extracted_text,
            "ocr_confidence": conf,
            "vocabulary": top_vocab
        }
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

# 🎒 3. ENDPOINT CHO MODULE LEARNING_VOCAB (MASTERY < 1.0 HOẶC < 100)
@app.get("/api/learning")
def get_learning_vocab(user_id: str = DEFAULT_USER_ID):
    try:
        learning_words = db.get_learning_words(user_id) or []
        learning_items = []
        
        for index, item in enumerate(learning_words):
            raw_mastery = float(item.get("mastery_score", 0.0))
            if raw_mastery <= 1.0:
                calc_progress = int(round(raw_mastery * 100))
            else:
                calc_progress = int(round(raw_mastery))
                
            current_progress = min(max(calc_progress, 0), 99)
            meaning_vi = item.get("vietnamese_meaning") or "Chưa có nghĩa tiếng Việt"
            definition_en = item.get("definition") or "No definition available"
            created_at_val = item.get("created_at") or item.get("last_reviewed") or "2026-08-16T12:00:00"

            learning_items.append({
                "id": str(item.get("id", f"learn_{index + 1}")),
                "word": item.get("word", ""),
                "meaning": meaning_vi,
                "definition": definition_en,
                "vietnamese_meaning": meaning_vi,
                "cefrLevel": str(item.get("level", "A1")).upper(),
                "currentProgress": current_progress,
                "createdAt": str(created_at_val),
                "maxProgress": 100
            })

        _debug(
            f"learning_response user_id={user_id} count={len(learning_items)} "
            "fields=definition,vietnamese_meaning"
        )
            
        return {
            "success": True,
            "total": len(learning_items),
            "words": learning_items
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ⚖️ 4. ENDPOINT CHO MODULE INVENTORY_VOCAB (MASTERY >= 1.0 HOẶC >= 100)
@app.get("/api/inventory")
def get_inventory_vocab(user_id: str = DEFAULT_USER_ID):
    try:
        mastered_words = db.get_inventory_words(user_id) or []
        mastered_items = []

        for index, item in enumerate(mastered_words):
            meaning_vi = item.get("vietnamese_meaning") or "Chưa có nghĩa tiếng Việt"
            definition_en = item.get("definition") or "No definition available"
            mastered_date = (
                item.get("mastered_at")
                or item.get("next_review_date")
                or item.get("created_at")
                or "Vừa xong"
            )

            mastered_items.append({
                "id": str(item.get("id", f"inv_{index + 1}")),
                "word": item.get("word", ""),
                "meaning": meaning_vi,
                "definition": definition_en,
                "vietnamese_meaning": meaning_vi,
                "cefrLevel": str(item.get("level", "A1")).upper(),
                "pos": str(item.get("pos", "NOUN")).upper(),
                "masteredAt": str(mastered_date)
            })

            _debug(f"inventory_response user_id={user_id} count={len(mastered_items)}")

        return {
            "success": True,
            "total": len(mastered_items),
            "words": mastered_items
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 🔥 5. STREAK VÀ HOẠT ĐỘNG HỌC TẬP
@app.get("/api/streak")
def get_streak(user_id: str = DEFAULT_USER_ID):
    try:
        today = datetime.now().date()
        activity_by_date = {
            item["date"]: int(item["count"])
            for item in db.get_study_activity(user_id, days=28)
        }
        heatmap = [
            min(4, activity_by_date.get(
                (today - timedelta(days=27 - index)).isoformat(), 0
            ))
            for index in range(28)
        ]
        heatmap_word_reviews = [
            activity_by_date.get(
                (today - timedelta(days=27 - index)).isoformat(), 0
            )
            for index in range(28)
        ]

        streak_days = 0
        cursor_date = today
        while activity_by_date.get(cursor_date.isoformat(), 0) > 0:
            streak_days += 1
            cursor_date -= timedelta(days=1)

        current_exp = min(500, sum(activity_by_date.values()) * 20)
        today_word_reviews = activity_by_date.get(today.isoformat(), 0)
        return {
            "success": True,
            "currentExp": current_exp,
            "targetExp": 500,
            "streakDays": streak_days,
            "streakFreezeCount": 0,
            "availableChests": current_exp // 500,
            "milestoneProgress": current_exp / 500,
            "heatmapDailyActivity": heatmap,
            "heatmapWordReviews": heatmap_word_reviews,
            "todayWordReviews": today_word_reviews,
            "todayExp": today_word_reviews * 20,
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 🧠 5. FLASHCARDS & ÔN TẬP
@app.get("/api/flashcards")
def get_due_flashcards(user_id: str = DEFAULT_USER_ID, limit: int = 30, mode: str = "study"):
    try:
        if mode == "practice":
            words = []
            for _ in range(limit):
                w = db.get_practice_word(user_id, recent_words=[item['word'] for item in words if 'word' in item])
                if w and w not in words:
                    words.append(w)
            if not words:
                words = db.get_study_words(user_id, limit=limit)
        else:
            words = db.get_study_words(user_id, limit=limit)

        formatted_cards = []
        for item in words:
            definition_text = item.get("definition") or item.get("meaning") or "Chưa có định nghĩa"
            example_text = item.get("context_example") or "No example available."

            formatted_cards.append({
                "word": item.get("word", ""),
                "pos": str(item.get("pos", "NOUN")).upper(),
                "definition": definition_text,
                "meaning": item.get("vietnamese_meaning") or "Chưa có nghĩa tiếng Việt",
                "vietnamese_meaning": item.get("vietnamese_meaning") or "Chưa có nghĩa tiếng Việt",
                "context_example": example_text,
                "level": str(item.get("level", "A1")).upper(),
                "synonyms": item.get("synonyms", []),
                "mastery_score": item.get("mastery_score", 0.0)
            })

        return {
            "success": True,
            "total": len(formatted_cards),
            "flashcards": formatted_cards
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/flashcards/review")
def review_flashcard(data: ReviewWordRequest):
    try:
        result = db.review_word(data.user_id or DEFAULT_USER_ID, data.word, quality=data.quality)
        result["word_review"] = 1
        result["exp_earned"] = 20
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/history")
def get_history(user_id: str = DEFAULT_USER_ID):
    try:
        history = db.get_all_user_history(user_id)
        return {
            "success": True,
            "total": len(history) if history else 0,
            "history": history or []
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ----------------------------------------------------
# SCRIPT ENTRYPOINT
# ----------------------------------------------------
if __name__ == "__main__":
    uvicorn.run(
        "api_server:app",
        host="127.0.0.1",
        port=8000,
        reload=True,
        reload_dirs=[str(PROJECT_DIR), str(IMAGES_DIR)]
    )