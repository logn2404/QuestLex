# download_models.py
import os
import nltk
from sentence_transformers import SentenceTransformer

def setup_offline_environment():
    print("🚀 === BẮT ĐẦU CHUẨN BỊ MÔ HÌNH & DỮ LIỆU LOCAL ===")
    
    # Thư mục lưu dữ liệu NLTK ngay trong dự án
    nltk_dir = "./nltk_data"
    os.makedirs(nltk_dir, exist_ok=True)
    if nltk_dir not in nltk.data.path:
        nltk.data.path.append(nltk_dir)

    # 1. DANH SÁCH TÀI NGUYÊN NLTK
    nltk_resources = [
        ("corpora/brown", "brown"),
        ("corpora/gutenberg", "gutenberg"),
        ("tokenizers/punkt", "punkt"),
        ("tokenizers/punkt_tab", "punkt_tab"),
        ("corpora/wordnet", "wordnet"),
        ("corpora/omw-1.4", "omw-1.4"),
    ]

    print("\n⏳ [1/2] Đang kiểm tra dữ liệu NLTK...")
    for resource_path, resource_id in nltk_resources:
        try:
            nltk.data.find(resource_path)
            print(f"  ✓ {resource_id}: Đã có sẵn.")
        except LookupError:
            print(f"  ⬇️ {resource_id}: Đang tải về '{nltk_dir}'...")
            nltk.download(resource_id, download_dir=nltk_dir, quiet=True)
            print(f"  ✅ {resource_id}: Tải thành công!")

    # 2. TẢI MÔ HÌNH KEYBERT / SENTENCE-TRANSFORMER
    model_name = "all-MiniLM-L6-v2"
    save_path = "./models/all-MiniLM-L6-v2"

    print(f"\n⏳ [2/2] Đang kiểm tra mô hình Hugging Face ({model_name})...")
    if os.path.exists(save_path) and os.listdir(save_path):
        print(f"  ✓ Model đã có sẵn tại '{save_path}'.")
    else:
        print(f"  ⬇️ Đang tải mô hình weights từ Hugging Face Hub...")
        model = SentenceTransformer(model_name)
        model.save(save_path)
        print(f"  ✅ Đã lưu mô hình thành công tại '{save_path}'!")

    print("\n🎉 === HOÀN TẤT! TẤT CẢ DỮ LIỆU ĐÃ SẴN SÀNG CHO APP OFFLINE ===")

if __name__ == "__main__":
    setup_offline_environment()