import os
os.environ["HF_HUB_DISABLE_PROGRESS_BARS"] = "1"
from pathlib import Path
from revision_engine import RevisionEngine
from flashcard_cli import run_flashcard_session, clear_screen
import nltk

# Import background model preloader
from model_preloader import start_preload, get_ocr_engine, get_vocab_engine

PROJECT_DIR = Path(__file__).resolve().parent
DB_DIR = PROJECT_DIR / "../user_history" / "vocab_app.db"
IMAGES_DIR = PROJECT_DIR / "../images"
MODELS_DIR = PROJECT_DIR / "models"
NLTK_DATA_DIR = MODELS_DIR / "nltk_data"
KEYBERT_MODEL_DIR = MODELS_DIR / "keybert" / "all-MiniLM-L6-v2"

MODELS_DIR.mkdir(exist_ok=True)
NLTK_DATA_DIR.mkdir(exist_ok=True)
KEYBERT_MODEL_DIR.parent.mkdir(exist_ok=True)
os.environ.setdefault("HF_HOME", str(MODELS_DIR))
if str(NLTK_DATA_DIR) not in nltk.data.path:
    nltk.data.path.append(str(NLTK_DATA_DIR))

LEVEL_OPTIONS = {
    "1": {"label": "Beginner", "cefr": "A1"},
    "2": {"label": "Amateur", "cefr": "B2"},
    "3": {"label": "Expert", "cefr": "C1"},
}

def choose_user_level() -> str:
    while True:
        clear_screen()
        print("==========================================")
        print("      🎯 CHỌN MỨC ĐỘ TỪ VỰNG")
        print("==========================================")
        print("  [1] 👶 Beginner  -> A1")
        print("  [2] 🧑‍🎓 Amateur   -> B2")
        print("  [3] 🧠 Expert    -> C1")
        print("==========================================")

        choice = input("\n👉 Chọn mức độ của bạn (1-3): ").strip()
        if choice in LEVEL_OPTIONS:
            selected = LEVEL_OPTIONS[choice]
            print(f"\n✅ Đã chọn: {selected['label']} ({selected['cefr']})")
            input("\n👉 Nhấn [Enter] để tiếp tục...")
            return selected["cefr"]

        input("⚠️ Lựa chọn không hợp lệ. Nhấn [Enter] để thử lại...")

def main():
    USER_ID = "user_dev_01"

    db = RevisionEngine(DB_DIR)
    selected_level = db.get_user_level(USER_ID)
    if selected_level is None:
        selected_level = choose_user_level()
        db.save_user_level(USER_ID, selected_level)

    start_preload()

    while True:
        clear_screen()
        print("==========================================")
        print("      🤖 QUESTLEX - AI VOCAB APP          ")
        print("==========================================")
        print("  [1] 📸 Quét toàn bộ ảnh trong thư mục 'images'")
        print("  [2] 🧠 Ôn tập Flashcard (Spaced Repetition)")
        print("  [3] 📚 Xem toàn bộ lịch sử từ vựng")
        print("  [4] ❌ Thoát ứng dụng")
        print("==========================================")

        choice = input("\n👉 Nhập lựa chọn của bạn (1-4): ")

        if choice == '1':
            clear_screen()
            print("⏳ Đang tiến hành OCR & Trích xuất từ vựng từ thư mục 'images'...\n")

            image_dir = IMAGES_DIR
            if not os.path.exists(image_dir):
                print(f"⚠️ Không tìm thấy thư mục '{image_dir}'!")
                input("\n👉 Nhấn [Enter] để quay lại Menu chính...")
                continue

            valid_extensions = ('.png', '.jpg', '.jpeg', '.bmp', '.webp')
            image_files = [f for f in os.listdir(image_dir) if f.lower().endswith(valid_extensions)]

            if not image_files:
                print(f"⚠️ Không tìm thấy file ảnh nào trong thư mục '{image_dir}'!")
                input("\n👉 Nhấn [Enter] để quay lại Menu chính...")
                continue

            # Fetch preloaded engines (blocks briefly only if background load isn't finished yet)
            print("🧠 Đang kiểm tra/nạp mô hình AI...")
            ocr_engine = get_ocr_engine()
            vocab_engine = get_vocab_engine()

            if ocr_engine is None or vocab_engine is None:
                print("❌ Không thể nạp các mô hình AI. Vui lòng kiểm tra lại log.")
                input("\n👉 Nhấn [Enter] để quay lại Menu chính...")
                continue

            for img_name in image_files:
                image_path = os.path.join(image_dir, img_name)
                print(f"🖼️  --- ĐANG XỬ LÝ: {img_name} ---")

                # 1. OCR trích xuất text từ ảnh
                extracted_text, conf = ocr_engine.extract_text_from_image(image_path)
                print(f"📄 Văn bản OCR đọc được: \"{extracted_text}\"\n")

                if not extracted_text.strip():
                    print("⚠️ Không tìm thấy văn bản trong ảnh này, bỏ qua.\n")
                    continue

                # 2. Lấy lịch sử user để thuật toán chấm điểm ưu tiên
                user_profile = db.get_user_history_for_extractor(USER_ID)

                # 3. Phân tích và lấy tất cả từ phù hợp với mức độ người dùng
                top_vocab = vocab_engine.process_text(
                    text=extracted_text,
                    user_history=user_profile,
                    top_k=None,
                    score_threshold=0.45,
                    level=selected_level
                )

                print("✅ ĐÃ TÌM THẤY & TRA TỪ ĐIỂN XONG:")
                print("-" * 50)
                for item in top_vocab:
                    word = item['word']
                    print(f"📌 {word.upper()} ({item['pos']})")
                    print(f"   📊 Level: {item.get('level', 'N/A')}")
                    print(f"   📌 Loại từ   : {item.get('pos', 'N/A')}")
                    print(f"   📖 Nghĩa: {item['definition']}")
                    print(f"   🔗 Đồng nghĩa: {', '.join(item['synonyms']) if item['synonyms'] else 'N/A'}")
                    print(f"   📝 Ví dụ: \"{item['context_example']}\"")
                    print(f"   📈 Mastery: {item.get('mastery_score', 0.0)}/1.0\n")

                    # 4. Lưu vào Database
                    db.add_word_to_study(
                        user_id=USER_ID,
                        word=word,
                        pos=item['pos'],
                        definition=item['definition'],
                        synonyms=item['synonyms'],
                        context_example=item['context_example'],
                        level=item.get('level', 'A1'),
                        mastery_score=item.get('mastery_score', 0.0)
                    )

                print("-" * 50 + "\n")

            print("💾 Đã tự động lưu các từ này vào kho Flashcard!")
            input("\n👉 Nhấn [Enter] để quay lại Menu chính...")

        elif choice == '2':
            run_flashcard_session(USER_ID)

        elif choice == '3':
            clear_screen()
            history = db.get_all_user_history(USER_ID)
            if not history:
                print("📚 Bạn chưa có từ vựng nào trong lịch sử.")
                input("\n👉 Nhấn [Enter] để quay lại Menu chính...")
                continue

            print("📚 TOÀN BỘ LỊCH SỬ TỪ VỰNG CỦA BẠN")
            print("-" * 60)
            for index, item in enumerate(history, start=1):
                print(f"{index}. {item['word'].upper()} ({item['pos']})")
                print(f"   Level: {item.get('level', 'N/A')}")
                print(f"   Nghĩa: {item['definition']}")
                print(f"   Đồng nghĩa: {', '.join(item['synonyms']) if item['synonyms'] else 'N/A'}")
                print(f"   Ví dụ: \"{item['context_example']}\"")
                print(f"   Mastery: {item.get('mastery', 0.0)}/1.0\n")

            print("-" * 60)
            input("\n👉 Nhấn [Enter] để quay lại Menu chính...")

        elif choice == '4':
            clear_screen()
            print("👋 Hẹn gặp lại bạn lần sau!")
            break

        else:
            input("⚠️ Lựa chọn không hợp lệ. Nhấn [Enter] để thử lại...")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        import traceback
        print("\n❌ CHƯƠNG TRÌNH GẶP LỖI:")
        traceback.print_exc()
        input("\nNhấn Enter để thoát...")