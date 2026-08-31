import json
from pathlib import Path
import re

txt_path = Path("./AI/models/anhviet109K.txt")
json_path = Path("./AI/models/en_vi_dict.json")

def convert_dict():
    en_vi_dict = {}
    print("Đang phân tích file từ điển...")
    
    current_word = None
    current_meanings = []
    
    with open(txt_path, "r", encoding="utf-8", errors="ignore") as f:
        for line in f:
            line_str = line.strip()
            if line_str.startswith("@"):
                if current_word and current_meanings:
                    en_vi_dict[current_word.lower()] = ["; ".join(current_meanings)]
                
                clean_line = line_str[1:].split("/")[0].strip()
                current_word = clean_line
                current_meanings = []
            elif line_str.startswith("*") or line_str.startswith("!"):
                continue
            elif line_str.startswith("-") and current_word:
                current_meanings.append(line_str[1:].strip())
            elif line_str and current_word and not current_meanings:
                current_meanings.append(line_str)

        if current_word and current_meanings:
            en_vi_dict[current_word.lower()] = ["; ".join(current_meanings)]

    json_path.parent.mkdir(exist_ok=True)
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(en_vi_dict, f, ensure_ascii=False, indent=2)
        
    print(f"Đã tạo thành công file JSON với {len(en_vi_dict):,} từ tại '{json_path}'!")

if __name__ == "__main__":
    convert_dict()