import os
import random
import string
from pathlib import Path
from typing import Dict, List, Optional, Any  # <--- Bổ sung dòng này
from revision_engine import RevisionEngine

PROJECT_DIR = Path(__file__).resolve().parent
DB_DIR = PROJECT_DIR / "../user_history" / "vocab_app.db"

def clear_screen():
    os.system('cls' if os.name == 'nt' else 'clear')

# ==========================================================
# PHƯƠNG PHÁP 1: FLASHCARD (LẬT THẺ TRUYỀN THỐNG)
# ==========================================================
def play_flashcard_item(db: RevisionEngine, user_id: str, item: Dict) -> bool:
    word = item["word"]
    synonyms_str = ", ".join(item.get("synonyms", [])) if item.get("synonyms") else "N/A"
    
    print("==========================================")
    print(f"📌 TỪ VỰNG:   [{word.upper()}]")
    print("==========================================\n")
    input("🤔 Cố gắng nhớ nghĩa và nhấn [Enter] để lật thẻ...")
    
    print("\n---------------- LỜI GIẢI ----------------")
    print(f"📊 Level     : {item.get('level', 'N/A')}")
    print(f"📌 Loại từ   : {item.get('pos', 'N/A')}")
    print(f"📖 Định nghĩa: {item.get('definition', 'N/A')}")
    print(f"🔗 Đồng nghĩa: {synonyms_str}")
    print(f"📝 Ví dụ     : \"{item.get('context_example', 'N/A')}\"")
    print(f"📈 Mastery   : {round(item.get('mastery', 0.0)*100)}%")
    print("------------------------------------------\n")
    
    print("Đánh giá độ khó:")
    print("  [1] 🔴 Quên hẳn")
    print("  [2] 🟠 Hơi khó")
    print("  [3] 🟢 Nhớ rõ")
    print("  [4] 🔵 Dễ ợt")
    
    while True:
        try:
            choice = int(input("\n👉 Nhập lựa chọn (1-4): "))
            if choice in [1, 2, 3, 4]:
                break
            print("⚠️ Nhập số từ 1 đến 4.")
        except ValueError:
            print("⚠️ Lỗi nhập liệu.")
            
    res = db.review_word(user_id, word, quality=choice)
    print(f"✅ Đã lưu! Lần ôn tiếp theo: {res['next_review_date']}")
    return choice >= 2  # Coi như trả lời đúng/nhớ nếu rating >= 2

# ==========================================================
# PHƯƠNG PHÁP 2: MATCHING (NỐI TỪ - ĐỊNH NGHĨA & ĐỒNG NGHĨA)
# ==========================================================
def play_matching_round(db: RevisionEngine, user_id: str, batch: List[Dict]) -> bool:
    clear_screen()
    print("==========================================")
    print("🧩 BÀI TẬP NỐI TỪ (MATCHING GAME)")
    print("==========================================\n")
    
    words = [item["word"] for item in batch]
    shuffled_words = words.copy()
    random.shuffle(shuffled_words)
    
    defs = []
    for item in batch:
        syns = f" (Đồng nghĩa: {', '.join(item['synonyms'])})" if item.get('synonyms') else ""
        defs.append((item["word"], f"{item['definition']}{syns}"))
    
    shuffled_defs = defs.copy()
    random.shuffle(shuffled_defs)
    
    letters = list(string.ascii_uppercase[:len(batch)])
    
    print("---- CỘT TỪ VỰNG ----")
    for idx, w in enumerate(shuffled_words, 1):
        print(f"  [{idx}] {w.upper()}")
        
    print("\n---- CỘT ĐỊNH NGHĨA & ĐỒNG NGHĨA ----")
    for idx, (target_w, d_text) in enumerate(shuffled_defs):
        print(f"  [{letters[idx]}] {d_text}")
        
    print("\n👉 Hãy ghép nối theo dạng: 1A, 2C, 3B...")
    all_correct = True
    
    for idx, w in enumerate(shuffled_words, 1):
        ans = input(f"Chọn đáp án cho [{idx}] {w.upper()} (VD: A, B, C...): ").strip().upper()
        if ans in letters:
            chosen_def_w = shuffled_defs[letters.index(ans)][0]
            if chosen_def_w.lower() == w.lower():
                print("  => ✅ CHÍNH XÁC!")
                db.update_word_result(user_id, w, is_correct=True)
            else:
                print(f"  => ❌ SAI RỒI! Đúng ra phải nối với từ '{chosen_def_w.upper()}'")
                db.update_word_result(user_id, w, is_correct=False)
                all_correct = False
        else:
            print("  => ❌ LỰA CHỌN KHÔNG HỢP LỆ (Tính sai)")
            db.update_word_result(user_id, w, is_correct=False)
            all_correct = False
            
    input("\nNhấn [Enter] để tiếp tục...")
    return all_correct

# ==========================================================
# PHƯƠNG PHÁP 3: TYPING (GÕ TỪ THEO ĐỊNH NGHĨA & ĐỒNG NGHĨA)
# ==========================================================
def play_typing_item(db: RevisionEngine, user_id: str, item: Dict) -> bool:
    clear_screen()
    word = item["word"]
    synonyms_str = ", ".join(item.get("synonyms", [])) if item.get("synonyms") else "Không có"
    
    print("==========================================")
    print("⌨️ BÀI TẬP GÕ TỪ (TYPING PRACTICE)")
    print("==========================================\n")
    print(f"📖 Định nghĩa: {item.get('definition')}")
    print(f"🔗 Đồng nghĩa: {synonyms_str}")
    print(f"💡 Gợi ý    : Loại từ [{item.get('pos')}] | Độ dài: {len(word)} ký tự")
    print("------------------------------------------")
    
    user_input = input("\n👉 Nhập từ vựng chính xác: ").strip().lower()
    
    if user_input == word.lower():
        print(f"\n🎉 CHÍNH XÁC! Kết quả: [{word.upper()}]")
        db.update_word_result(user_id, word, is_correct=True)
        input("\nNhấn [Enter] để tiếp tục...")
        return True
    else:
        print(f"\n❌ SAI RỒI! Đáp án đúng là: [{word.upper()}]")
        db.update_word_result(user_id, word, is_correct=False)
        input("\nNhấn [Enter] để tiếp tục...")
        return False

# ==========================================================
# CHẾ ĐỘ 1: STUDY MODE (GIỚI HẠN 30 TỪ MỤC LEARNING)
# ==========================================================
def run_study_mode(user_id: str, method_choice: str):
    db = RevisionEngine(DB_DIR)
    words = db.get_study_words(user_id, limit=30)
    
    if not words:
        clear_screen()
        print("🎉 Bạn không có từ vựng nào trong danh sách đang học (<100% mastery)!")
        input("\nNhấn [Enter] để quay lại...")
        return

    clear_screen()
    print(f"📚 BẮT ĐẦU CHẾ ĐỘ STUDY ({len(words)} TỪ VỰNG)")
    input("👉 Nhấn [Enter] để bắt đầu...")
    
    if method_choice == "1": # Flashcard
        for i, item in enumerate(words, 1):
            clear_screen()
            print(f"=== Thẻ {i}/{len(words)} ===")
            play_flashcard_item(db, user_id, item)
            
    elif method_choice == "2": # Matching
        batch_size = 4
        for i in range(0, len(words), batch_size):
            batch = words[i:i+batch_size]
            if len(batch) >= 2:
                play_matching_round(db, user_id, batch)
                
    elif method_choice == "3": # Typing
        for item in words:
            play_typing_item(db, user_id, item)
            
    clear_screen()
    print("🎉 BẠN ĐÃ HOÀN THÀNH PHIÊN STUDY 30 TỪ!")
    input("\nNhấn [Enter] để quay lại menu...")

# ==========================================================
# CHẾ ĐỘ 2: PRACTICE MODE (ENDLESS - SAI 1 CÂU DỪNG LẠI)
# ==========================================================
def run_practice_mode(user_id: str, method_choice: str):
    db = RevisionEngine(DB_DIR)
    recent_words = []
    score = 0

    clear_screen()
    print("🔥 BẮT ĐẦU CHẾ ĐỘ PRACTICE (ENDLESS)")
    print("⚠️ Luật chơi: Game sẽ kết thúc ngay khi bạn trả lời SAI 1 câu!")
    input("👉 Nhấn [Enter] để xuất phát...")

    while True:
        if method_choice in ["1", "3"]: # Flashcard hoặc Typing
            item = db.get_practice_word(user_id, recent_words)
            if not item:
                print("⚠️ Chưa có từ vựng nào trong CSDL để luyện tập!")
                break

            recent_words.append(item["word"])
            if len(recent_words) > 10:
                recent_words.pop(0)

            if method_choice == "1":
                clear_screen()
                print(f"🏆 Chuỗi đúng hiện tại: {score}")
                is_correct = play_flashcard_item(db, user_id, item)
            else:
                is_correct = play_typing_item(db, user_id, item)

            if is_correct:
                score += 1
            else:
                clear_screen()
                print(f"💥 GAME OVER! Bạn trả lời sai từ [{item['word'].upper()}].")
                print(f"🏆 Tổng số từ trả lời đúng liên tiếp: {score}")
                break

        elif method_choice == "2": # Matching (lấy batch 4 từ)
            batch = []
            for _ in range(4):
                w = db.get_practice_word(user_id, recent_words)
                if w and w["word"] not in [b["word"] for b in batch]:
                    batch.append(w)
                    recent_words.append(w["word"])

            if len(batch) < 2:
                print("⚠️ Không đủ dữ liệu từ vựng để chơi bài tập Nối!")
                break

            all_correct = play_matching_round(db, user_id, batch)
            if all_correct:
                score += len(batch)
            else:
                clear_screen()
                print("💥 GAME OVER! Bạn đã ghép sai ở phiên này.")
                print(f"🏆 Tổng điểm chuỗi đúng: {score}")
                break

    input("\nNhấn [Enter] để quay lại menu...")

# ==========================================================
# MAIN ENTRYPOINT DÀNH CHO MODULE FLASHCARD_CLI
# ==========================================================
def run_flashcard_session(user_id: str, limit: int = 10):
    while True:
        clear_screen()
        print("==========================================")
        print("       🧠 TÙY CHỌN CHẾ ĐỘ ÔN TẬP          ")
        print("==========================================")
        print("  [1] 📖 Study Mode (Chuẩn 30 từ mục Learning)")
        print("  [2] 🎯 Practice Mode (Endless - Sai 1 câu là dừng)")
        print("  [3] ↩️ Quay lại Menu chính")
        print("==========================================")
        
        mode = input("\n👉 Chọn chế độ (1-3): ").strip()
        if mode == "3":
            break
        if mode not in ["1", "2"]:
            continue

        clear_screen()
        print("==========================================")
        print("     🎮 CHỌN PHƯƠNG PHÁP HỌC CỦA BẠN      ")
        print("==========================================")
        print("  [1] 🃏 Flashcard (Lật thẻ chủ động)")
        print("  [2] 🧩 Matching (Nối Từ - Định nghĩa & Đồng nghĩa)")
        print("  [3] ⌨️ Typing (Gõ từ theo Định nghĩa & Đồng nghĩa)")
        print("  [4] ↩️ Quay lại")
        print("==========================================")
        
        method = input("\n👉 Chọn phương pháp (1-4): ").strip()
        if method == "4":
            continue
        if method not in ["1", "2", "3"]:
            continue

        if mode == "1":
            run_study_mode(user_id, method)
        elif mode == "2":
            run_practice_mode(user_id, method)

if __name__ == "__main__":
    run_flashcard_session("user_dev_01")