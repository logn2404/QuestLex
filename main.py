import os
import json
from PIL import Image, ImageDraw

# Import các Module tự xây dựng
from ocr_extractor import OCRExtractor
from vocab_extractor import VocabularyExtractor
from revision_engine import RevisionEngine
from flashcard_cli import run_flashcard_session, clear_screen

def create_sample_screenshot(filename: str = "sample_screenshot.png") -> str:
    """Tạo một bức ảnh chứa văn bản tiếng Anh mẫu để test OCR."""
    text = (
        "Artificial intelligence relies heavily on complex algorithms to process data. "
        "Building a resilient system requires an understanding of ubiquitous network protocols. "
        "Engineers must continuously analyze potential vulnerabilities and optimize performance."
    )
    img = Image.new('RGB', (950, 200), color=(245, 247, 250))
    d = ImageDraw.Draw(img)
    d.text((30, 40), text, fill=(30, 30, 30))
    img.save(filename)
    return filename

def main():
    USER_ID = "user_dev_01"
    
    print("⏳ Đang khởi động AI Models (EasyOCR & KeyBERT) lên GPU... Vui lòng đợi trong giây lát...")
    ocr_engine = OCRExtractor(languages=['en'], gpu=True)
    vocab_engine = VocabularyExtractor(spacy_model="en_core_web_sm")
    db = RevisionEngine("vocab_app.db")
    
    while True:
        clear_screen()
        print("==========================================")
        print("      🤖 QUESTLEX - AI VOCAB APP          ")
        print("==========================================")
        print("  [1] 📸 Quét ảnh chụp màn hình (Ảnh mẫu)")
        print("  [2] 🧠 Ôn tập Flashcard (Spaced Repetition)")
        print("  [3] ❌ Thoát ứng dụng")
        print("==========================================")
        
        choice = input("\n👉 Nhập lựa chọn của bạn (1-3): ")
        
        if choice == '1':
            clear_screen()
            print("⏳ Đang tạo ảnh mẫu và tiến hành OCR & Trích xuất từ vựng...\n")
            
            image_path = "sample_screenshot.png"
            # create_sample_screenshot(image_path)
            
            # 1. OCR trích xuất text từ ảnh
            extracted_text, conf = ocr_engine.extract_text_from_image(image_path, use_preprocessing=False)
            print(f"📄 Văn bản OCR đọc được: \"{extracted_text}\"\n")
            
            # 2. Lấy lịch sử user để thuật toán chấm điểm ưu tiên
            user_profile = db.get_user_history_for_extractor(USER_ID)
            
            # 3. Phân tích và lấy Top 3 từ quan trọng nhất kèm Định nghĩa + Ví dụ
            top_vocab = vocab_engine.process_text(
                text=extracted_text, 
                user_history=user_profile, 
                top_k=3 
            )
            
            print("✅ ĐÃ TÌM THẤY & TRA TỪ ĐIỂN XONG:")
            print("-" * 50)
            for item in top_vocab:
                word = item['word']
                print(f"📌 {word.upper()} ({item['pos']})")
                print(f"   📖 Nghĩa: {item['definition']}")
                print(f"   🔗 Đồng nghĩa: {', '.join(item['synonyms']) if item['synonyms'] else 'N/A'}")
                print(f"   📝 Ví dụ: \"{item['context_example']}\"\n")
                
                # 4. Lưu vào Database
                db.add_word_to_study(
                    user_id=USER_ID, 
                    word=word, 
                    pos=item['pos'], 
                    definition=item['definition'], 
                    synonyms=item['synonyms'], 
                    context_example=item['context_example']
                )
            
            print("-" * 50)
            print("💾 Đã tự động lưu các từ này vào kho Flashcard!")
            input("\n👉 Nhấn [Enter] để quay lại Menu chính...")
            
        elif choice == '2':
            # Chuyển sang màn hình ôn tập Flashcard
            run_flashcard_session(USER_ID)
            
        elif choice == '3':
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