# QuestLex AI Backend Report

**Ngày cập nhật:** 2026-09-06  
**Thư mục:** `C:\Nhatlampoke\QuestLex\AI`  
**Trạng thái:** mã nguồn đã có FastAPI backend; cần kiểm tra môi trường model trước khi kết luận server sẵn sàng.

## 1. Phạm vi và kiến trúc

Backend AI chạy độc lập với Flutter và dùng chung dữ liệu ở thư mục cha:

```text
QuestLex/
├── AI/                    # Python backend
├── images/                # ảnh Flutter chụp, backend đọc rồi xóa
└── user_history/
    └── vocab_app.db      # SQLite vocabulary database
```

Có hai entry point:

| Entry point | Vai trò |
|---|---|
| `api_server.py` | FastAPI server cho Flutter, cổng `8000` |
| `main.py` | CLI độc lập để quét ảnh và ôn flashcard |

Pipeline chính:

```text
images/*.png|jpg|jpeg
    -> OCRExtractor (EasyOCR/OpenCV)
    -> VocabularyExtractor (spaCy/KeyBERT/CEFR/dictionary)
    -> RevisionEngine (SQLite + spaced repetition)
    -> user_history/vocab_app.db
```

## 2. API hiện có

Base URL: `http://127.0.0.1:8000`

| Method | Endpoint | Chức năng |
|---|---|---|
| `GET` | `/` | Health check và đường dẫn `images` |
| `GET` | `/api/user/level?user_id=...` | Đọc CEFR level |
| `POST` | `/api/user/level` | Lưu CEFR level |
| `POST` | `/api/scan-images-folder?user_id=...` | Quét toàn bộ ảnh trong `QuestLex/images` |
| `POST` | `/api/process-image` | Upload và xử lý một ảnh |
| `GET` | `/api/learning?user_id=...` | Từ đang học, mastery dưới 1.0 |
| `GET` | `/api/inventory?user_id=...` | Từ đã thuộc, mastery từ 1.0 |
| `GET` | `/api/flashcards?user_id=...&limit=30&mode=study` | Lấy flashcard |
| `POST` | `/api/flashcards/review` | Ghi kết quả ôn theo SM-2 |
| `GET` | `/api/history?user_id=...` | Lịch sử từ vựng |

### Hợp đồng scan folder

`/api/scan-images-folder` nhận `user_id`. Mỗi ảnh hợp lệ được OCR, trích xuất từ, lưu vào SQLite rồi xóa trong khối `finally`, kể cả khi xử lý lỗi. Kết quả thành công có:

```json
{
  "success": true,
  "processed_images_count": 1,
  "total_vocab_found": 3,
  "vocabulary": []
}
```

Backend hiện **không khai báo tham số `duration_ms`**, dù Flutter có thể gửi query parameter này. Tham số đó hiện bị bỏ qua.

## 3. Các module chính

- `ocr_extractor.py`: tiền xử lý ảnh, EasyOCR tiếng Anh, lọc confidence và sửa văn bản OCR.
- `vocab_extractor.py`: lấy token/phrase, lọc từ, chấm điểm, lọc CEFR và bổ sung nghĩa, đồng nghĩa, ví dụ.
- `offline_dictionary.py`: tra từ Anh-Việt local và fallback qua WordNet/dịch online.
- `revision_engine.py`: SQLite, lịch sử user, flashcard và thuật toán ôn cách quãng.
- `model_preloader.py`: preload model cho CLI.
- `flashcard_cli.py`: giao diện ôn tập terminal.
- `download_models.py`, `setup_offline_environment.py`, `setup_en_vi_dict.py`: chuẩn bị model, corpus và dữ liệu từ điển.

## 4. Khởi tạo và tài nguyên

Khi import `api_server.py`, backend ngay lập tức:

1. Ép `CUDA_VISIBLE_DEVICES=-1`, tức mặc định chạy CPU.
2. Tạo `images`, `user_history` và `temp_uploads` nếu thiếu.
3. Khởi tạo `OCRExtractor`, `VocabularyExtractor` và `RevisionEngine`.
4. Nâng process xuống `BELOW_NORMAL` trên Windows.

Vì model được nạp lúc khởi động, lần chạy đầu có thể lâu và cần nhiều RAM. Các tài nguyên cần có:

- Python environment có các package trong `requirements.txt`.
- spaCy model `en_core_web_sm`.
- NLTK data cần cho WordNet/corpus ví dụ.
- model SentenceTransformer/KeyBERT và từ điển trong `AI/models`.
- `models/en_vi_dict.json` nếu muốn tra Anh-Việt offline.

## 5. Chạy backend

Từ thư mục `C:\Nhatlampoke\QuestLex\AI`:

```powershell
$env:PYTHONUTF8 = "1"
python api_server.py
```

Hoặc dùng đúng Python của environment:

```powershell
$env:PYTHONUTF8 = "1"
C:\Users\ADMIN\anaconda3\envs\questlex_env\python.exe api_server.py
```

Kiểm tra server sau khi khởi động:

```powershell
Invoke-RestMethod http://127.0.0.1:8000/
```

Kết quả mong đợi có `status: online` và `message: QuestLex Local AI Server is running`.

## 6. Tích hợp với Flutter

Flutter dùng `http://127.0.0.1:8000/api` trong `lib/services/ai_service.dart`. Luồng tự động là:

1. Home bật AI Scan.
2. Trigger timer/click/scroll yêu cầu chụp màn hình.
3. Flutter lưu ảnh vào `QuestLex/images`.
4. Flutter gọi `POST /api/scan-images-folder`.
5. Backend trả `job_id`, sau đó xử lý ảnh bằng background task.
6. Flutter polling `GET /api/scan-status?job_id=...`.
7. Khi job hoàn tất, backend lưu từ mới vào SQLite và Flutter tải lại dashboard statistics.

Shortcut `Ctrl+Shift+S` cũng chụp ảnh và kích hoạt scan folder theo luồng riêng.

## 7. Rủi ro và điểm cần kiểm tra

### Mức cao

- Server có thể không khởi động nếu thiếu package, spaCy model, NLTK corpus hoặc model local. Cần xem traceback đầu tiên khi chạy `api_server.py`.
- `api_server.py` dùng import dạng `from ocr_extractor import ...`, vì vậy phải chạy từ thư mục `AI` hoặc cấu hình Python path tương ứng.
- OCR dùng CPU và EasyOCR/KeyBERT có thể tiêu thụ nhiều RAM; worker scan bị giới hạn tối đa 4 nhưng mỗi model engine vẫn được khởi tạo toàn cục.
- Quick Filter nhẹ trong `image_quick_filter.py` loại ảnh gần trùng và ảnh gần như rỗng trước OCR, không dùng thêm AI model.
- Status scan có `job_id`, `processed_images_count`, `skipped_duplicate_count` và `skipped_low_quality_count`.
- Backend và Flutter có log prefix `[AI DEBUG]` cho các bước reserve job, preload model, quick filter, OCR, extract vocabulary, ghi database, polling và cleanup.

### Mức trung bình

- CORS đang cho phép mọi origin (`*`), phù hợp local development nhưng không nên giữ nguyên khi expose ra mạng.
- File ảnh bị xóa sau xử lý. Đây là hành vi hiện tại, cần backup/log nếu muốn giữ dữ liệu gốc.
- `temp_uploads` được tạo cho upload đơn nhưng file upload chỉ tồn tại tạm thời.
- Flutter vẫn gửi `duration_ms`, nhưng background scan hiện chưa dùng giá trị này để thay đổi scoring.
- API chưa có authentication; `user_id` hiện nhận trực tiếp từ query/body.

## 8. Checklist chẩn đoán khi backend không chạy

1. Kiểm tra đang đứng tại `C:\Nhatlampoke\QuestLex\AI`.
2. Kích hoạt đúng environment và chạy `python api_server.py`.
3. Ghi lại traceback trong bước import model/package đầu tiên bị lỗi.
4. Xác nhận `models`, `images` và `user_history` tồn tại hoặc cho phép backend tự tạo.
5. Khi server đã báo sẵn sàng, gọi `Invoke-RestMethod http://127.0.0.1:8000/`.
6. Chỉ sau health check mới thử `POST /api/scan-images-folder`.

## 9. Kết luận hiện tại

Backend đã có đầy đủ khung xử lý OCR -> vocabulary extraction -> SQLite và REST API phục vụ Flutter. Vấn đề “không hoạt động” chưa thể kết luận là lỗi logic chỉ từ source code; điểm kiểm tra quyết định là traceback khi khởi động trong Python environment. Report này ghi nhận trạng thái code hiện tại và các khác biệt quan trọng để lần debug tiếp theo bắt đầu từ log thật, không dựa vào giả định ONNX còn chưa tích hợp.
