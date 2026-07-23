import os
from revision_engine import RevisionEngine

def clear_screen():
    """Xóa màn hình Terminal để giao diện gọn gàng hơn."""
    os.system('cls' if os.name == 'nt' else 'clear')

def run_flashcard_session(user_id: str, limit: int = 10):
    # Khởi tạo kết nối CSDL
    db = RevisionEngine("vocab_app.db")
    
    # Lấy danh sách từ đến hạn ôn tập
    words_to_review = db.get_due_words(user_id, limit)

    if not words_to_review:
        clear_screen()
        print("🎉 Tuyệt vời! Bạn không có từ vựng nào đến hạn ôn tập lúc này.")
        return

    clear_screen()
    print("==========================================")
    print(f"📚 BẮT ĐẦU PHIÊN ÔN TẬP ({len(words_to_review)} từ)")
    print("==========================================\n")
    input("👉 Nhấn [Enter] để bắt đầu...")

    for i, item in enumerate(words_to_review, 1):
        clear_screen()
        word = item["word"]
        
        # ----------------------------------------
        # MẶT TRƯỚC (FRONT OF FLASHCARD)
        # ----------------------------------------
        print(f"========== THẺ {i}/{len(words_to_review)} ==========")
        print(f"\nTừ vựng:   [{word.upper()}]\n")
        print("====================================\n")
        
        # Tạm dừng để người dùng cố gắng nhớ (Active Recall)
        input("🤔 Cố gắng nhớ nghĩa và nhấn [Enter] để lật thẻ...")
        
        # ----------------------------------------
        # MẶT SAU (BACK OF FLASHCARD)
        # ----------------------------------------
        synonyms_str = ", ".join(item.get("synonyms", [])) if item.get("synonyms") else "N/A"
        
        print("\n---------------- LỜI GIẢI ----------------")
        print(f"📌 Loại từ   : {item.get('pos', 'N/A')}")
        print(f"📖 Định nghĩa: {item.get('definition', 'N/A')}")
        print(f"🔗 Đồng nghĩa: {synonyms_str}")
        print(f"📝 Ví dụ     : \"{item.get('context_example', 'N/A')}\"")
        print("------------------------------------------\n")
        
        # ----------------------------------------
        # NHẬN ĐÁNH GIÁ (USER RATING)
        # ----------------------------------------
        print("Bạn đánh giá độ khó của từ này thế nào?")
        print("  [1] 🔴 Quên hẳn (Phải học lại ngay)")
        print("  [2] 🟠 Hơi khó (Nhớ mang máng)")
        print("  [3] 🟢 Tốt (Nhớ rõ nhưng cần suy nghĩ một chút)")
        print("  [4] 🔵 Rất dễ (Phản xạ tức thì)")
        
        while True:
            try:
                choice = int(input("\n👉 Nhập lựa chọn (1-4): "))
                if choice in [1, 2, 3, 4]:
                    break
                print("⚠️ Vui lòng chỉ nhập số từ 1 đến 4.")
            except ValueError:
                print("⚠️ Lỗi: Vui lòng nhập một con số hợp lệ.")
        
        # ----------------------------------------
        # CẬP NHẬT DATABASE
        # ----------------------------------------
        result = db.review_word(user_id, word, quality=choice)
        
        print(f"\n✅ Đã lưu kết quả!")
        print(f"   ⏳ Lần ôn tập tiếp theo: Sau {result['next_review_in_days']} ngày")
        print(f"   📈 Điểm Mastery mới: {result['mastery_score']} / 1.0")
        
        input("\nNhấn [Enter] để học từ tiếp theo...")

    clear_screen()
    print("==========================================")
    print("🎉 BẠN ĐÃ HOÀN THÀNH PHIÊN ÔN TẬP! CHÚC MỪNG!")
    print("==========================================")

if __name__ == "__main__":
    USER = "user_dev_01"
    run_flashcard_session(USER, limit=15)