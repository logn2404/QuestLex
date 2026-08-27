import os

# 1. Khấu trừ cờ môi trường ngay từ đầu để tránh lỗi PyTorch pin memory / GPU CUDA Allocation
os.environ["HF_HUB_DISABLE_PROGRESS_BARS"] = "1"
os.environ["CUDA_VISIBLE_DEVICES"] = "-1"  # Ép PyTorch/EasyOCR chạy CPU thuần 100%

import shutil
import traceback
from pathlib import Path
from typing import Optional, List
from concurrent.futures import ThreadPoolExecutor, as_completed

import psutil

from fastapi import FastAPI, UploadFile, File, HTTPException, Form
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

# 🎯 KHỞI TẠO FASTAPI APP
app = FastAPI(title="QuestLex AI Backend API")

# Cấu hình CORS cho phép kết nối từ Flutter Windows
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 🎯 HẠ PRIORITY PROCESS — nhường CPU cho game/app đang chạy
try:
    _proc = psutil.Process(os.getpid())
    if os.name == "nt":  # Windows
        _proc.nice(psutil.BELOW_NORMAL_PRIORITY_CLASS)
    else:               # Linux / macOS
        _proc.nice(10)
    print("🎮 Process priority hạ xuống BELOW_NORMAL — sẵn sàng chạy nền.")
except Exception as _prio_err:
    print(f"⚠️ Không thể hạ priority: {_prio_err}")

# ----------------------------------------------------
# ADAPTIVE WORKER CALCULATOR
# ----------------------------------------------------
def get_adaptive_workers() -> int:
    """
    Tính số OCR worker an toàn dựa trên tài nguyên máy thực tế lúc gọi.
    Chiến lược: chỉ dùng tối đa 25% CPU còn trống & giới hạn theo RAM.
    Hard cap = 4 để tránh OOM ngay cả khi máy dư tài nguyên.
    """
    cpu_count    = os.cpu_count() or 2
    cpu_free_pct = 100.0 - psutil.cpu_percent(interval=0.5)  # % CPU còn trống
    ram_free_gb  = psutil.virtual_memory().available / (1024 ** 3)

    # Chỉ lấy 25% CPU còn lại, tối thiểu 1 worker
    cpu_budget = max(1, int(cpu_count * (cpu_free_pct / 100.0) * 0.25))

    # Mỗi EasyOCR thread chiếm ~400-500 MB RAM
    ram_budget = max(1, int(ram_free_gb / 0.5))

    workers = min(cpu_budget, ram_budget, 4)  # Hard cap = 4
    print(
        f"🖥️  CPU trống: {cpu_free_pct:.0f}% | "
        f"RAM trống: {ram_free_gb:.1f} GB | "
        f"→ OCR workers = {workers}"
    )
    return workers

# 🎯 KHỞI TẠO AI ENGINES
print("⏳ Đang nạp các AI Models (EasyOCR CPU, spaCy, RevisionEngine)...")
print(f"📍 Database path: {DB_DIR.resolve()}")
print(f"📍 Shared Images path: {IMAGES_DIR.resolve()}")

ocr_engine = OCRExtractor(languages=['en'])
vocab_engine = VocabularyExtractor(spacy_model="en_core_web_sm")
db = RevisionEngine(str(DB_DIR))
DEFAULT_USER_ID = "user_dev_01"

print("✅ Nạp AI Models thành công! Backend sẵn sàng.")

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

# ----------------------------------------------------
# HELPER: XỬ LÝ 1 ẢNH (chạy trong thread worker)
# ----------------------------------------------------
def _process_single_image(
    img_path: Path,
    selected_level: str,
    user_profile: dict,
    user_id: str,
) -> list:
    """
    OCR + extract vocab từ 1 ảnh, lưu vào DB, xóa file sau khi xong.
    Trả về danh sách vocab tìm được (hoặc [] nếu lỗi).
    """
    vocab_found = []
    try:
        extracted_text, conf = ocr_engine.extract_text_from_image(str(img_path))
        if extracted_text and extracted_text.strip():
            top_vocab = vocab_engine.process_text(
                text=extracted_text,
                user_history=user_profile,
                top_k=None,
                score_threshold=0.45,
                level=selected_level
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
                    mastery_score=item.get('mastery_score', 0.0)
                )
                vocab_found.append(item)
    except Exception as ocr_err:
        print(f"⚠️ Lỗi OCR file {img_path.name}: {ocr_err}")
    finally:
        # 🗑️ Xóa ảnh sau khi xử lý (dù thành công hay lỗi)
        try:
            img_path.unlink()
            print(f"🗑️ Đã xóa ảnh đã xử lý: {img_path.name}")
        except Exception as del_err:
            print(f"⚠️ Không thể xóa {img_path.name}: {del_err}")
    return vocab_found


# 🚀 1. TỰ ĐỘNG QUÉT THƯ MỤC IMAGES/ CHUNG (WIN32 OVERLAY TRIGGER)
@app.post("/api/scan-images-folder")
async def scan_images_folder(user_id: str = DEFAULT_USER_ID):
    try:
        print(f"📥 [API RECEIVED]: Nhận lệnh quét folder images/ cho user: {user_id}")

        if not IMAGES_DIR.exists():
            return {"success": False, "message": f"Thư mục {IMAGES_DIR} chưa tồn tại!"}

        image_files = [
            f for f in IMAGES_DIR.iterdir()
            if f.suffix.lower() in ('.png', '.jpg', '.jpeg')
        ]
        print(f"🖼️ Tìm thấy {len(image_files)} ảnh trong thư mục images/")

        if not image_files:
            return {"success": True, "processed_images_count": 0, "total_vocab_found": 0, "vocabulary": []}

        selected_level = db.get_user_level(user_id) or "A1"
        user_profile   = db.get_user_history_for_extractor(user_id)
        workers        = get_adaptive_workers()  # 📊 Tính worker an toàn theo tài nguyên máy

        all_detected_vocab = []
        with ThreadPoolExecutor(max_workers=workers) as executor:
            futures = {
                executor.submit(
                    _process_single_image,
                    img_path, selected_level, user_profile, user_id
                ): img_path
                for img_path in image_files
            }
            for future in as_completed(futures):
                try:
                    all_detected_vocab.extend(future.result())
                except Exception as fut_err:
                    print(f"⚠️ Future lỗi [{futures[future].name}]: {fut_err}")

        return {
            "success": True,
            "processed_images_count": len(image_files),
            "total_vocab_found": len(all_detected_vocab),
            "vocabulary": all_detected_vocab
        }
    except Exception as e:
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

# 📸 2. XỬ LÝ UPLOAD 1 ẢNH ĐƠN
@app.post("/api/process-image")
async def process_image(
    file: UploadFile = File(...),
    user_id: str = Form(DEFAULT_USER_ID)
):
    temp_image_path = TEMP_UPLOAD_DIR / file.filename
    try:
        with open(temp_image_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

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
    finally:
        # 🗑️ Xóa file tạm sau khi xử lý (dù thành công hay lỗi)
        try:
            if temp_image_path.exists():
                temp_image_path.unlink()
                print(f"🗑️ Đã xóa file tạm: {temp_image_path.name}")
        except Exception as del_err:
            print(f"⚠️ Không thể xóa file tạm {temp_image_path.name}: {del_err}")

# 🎒 3. ENDPOINT CHO MODULE LEARNING_VOCAB (MASTERY < 1.0 HOẶC < 100)
@app.get("/api/learning")
def get_learning_vocab(user_id: str = DEFAULT_USER_ID):
    try:
        learning_words = db.get_learning_words(user_id) or []
        learning_items = []
        
        for index, item in enumerate(learning_words):
            raw_mastery = float(item.get("mastery_score", 0.0))
            
            # Xử lý quy đổi linh hoạt dù CSDL lưu thang 1.0 hay thang 100
            if raw_mastery <= 1.0:
                calc_progress = int(round(raw_mastery * 100))
            else:
                calc_progress = int(round(raw_mastery))
                
            current_progress = min(max(calc_progress, 0), 99)  # Giữ tối đa 99% cho từ đang học
            meaning_vi = item.get("definition") or "Chưa có nghĩa"
            created_at_val = item.get("created_at") or item.get("last_reviewed") or "2026-08-22T12:00:00"

            learning_items.append({
                "id": str(item.get("id", f"learn_{index + 1}")),
                "word": item.get("word", ""),
                "meaning": meaning_vi,
                "cefrLevel": str(item.get("level", "A1")).upper(),
                "currentProgress": current_progress,  # 🎯 Tính % tiến độ thực tế
                "createdAt": str(created_at_val),
                "maxProgress": 100
            })
            
        return {
            "success": True,
            "total": len(learning_items),
            "words": learning_items
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 📦 4. ENDPOINT CHO MODULE INVENTORY_VOCAB (MASTERY >= 1.0 HOẶC >= 100)
@app.get("/api/inventory")
def get_inventory_vocab(user_id: str = DEFAULT_USER_ID):
    try:
        mastered_words = db.get_inventory_words(user_id) or []
        mastered_items = []

        for index, item in enumerate(mastered_words):
            meaning_vi = item.get("definition") or "Chưa có nghĩa"
            mastered_date = item.get("last_reviewed") or item.get("created_at") or "Vừa xong"

            mastered_items.append({
                "id": str(item.get("id", f"inv_{index + 1}")),
                "word": item.get("word", ""),
                "meaning": meaning_vi,
                "cefrLevel": str(item.get("level", "A1")).upper(),
                "pos": str(item.get("pos", "NOUN")).upper(),
                "masteredAt": str(mastered_date)
            })

        return {
            "success": True,
            "total": len(mastered_items),
            "words": mastered_items
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 🧠 5. FLASHCARDS & ÔN TẬP (MODULE STUDY)
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

        return {
            "success": True,
            "total": len(words),
            "flashcards": words
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/flashcards/review")
def review_flashcard(data: ReviewWordRequest):
    try:
        result = db.review_word(data.user_id or DEFAULT_USER_ID, data.word, quality=data.quality)
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