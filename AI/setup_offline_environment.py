import os
import pickle
import json
import urllib.request
from pathlib import Path
from collections import defaultdict

import easyocr
import nltk
from keybert import KeyBERT
from sentence_transformers import SentenceTransformer

# ==========================================
# CẤU HÌNH ĐƯỜNG DẪN BẰNG PATHLIB
# ==========================================
PROJECT_DIR = Path(__file__).resolve().parent
MODELS_DIR = PROJECT_DIR / "models"
NLTK_DATA_DIR = MODELS_DIR / "nltk_data"
EASYOCR_DIR = MODELS_DIR / "easyocr"
KEYBERT_DIR = MODELS_DIR / "keybert"
KEYBERT_MODEL_DIR = KEYBERT_DIR / "all-MiniLM-L6-v2"
NLTK_INDEX_CACHE_PATH = MODELS_DIR / "nltk_index_cache.pkl"

EN_VI_DICT_PATH = MODELS_DIR / "en_vi_dict.json" 

WORDLISTS_DIR = MODELS_DIR / "wordlists"
CEFR_TSV_PATH = WORDLISTS_DIR / "cefr.tsv"
FREQ_TXT_PATH = WORDLISTS_DIR / "google-10000-english.txt"

CEFR_URLS = [
    "https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/en/en_50k.txt",
    "https://raw.githubusercontent.com/open-language-data/cefr-levels/main/cefr_english.tsv",
]
FREQ_URLS = [
    "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-no-swears.txt",
]


def ensure_model_paths():
    MODELS_DIR.mkdir(exist_ok=True)
    NLTK_DATA_DIR.mkdir(exist_ok=True)
    EASYOCR_DIR.mkdir(exist_ok=True)
    KEYBERT_DIR.mkdir(exist_ok=True)
    WORDLISTS_DIR.mkdir(exist_ok=True)
    
    if not NLTK_INDEX_CACHE_PATH.exists():
        with NLTK_INDEX_CACHE_PATH.open("wb") as handle:
            pickle.dump({}, handle)

def build_en_vi_dict():
    """Hàm quét toàn bộ từ vựng từ WordNet và dịch sang tiếng Việt, xử lý lỗi an toàn từng từ"""
    print("\n⏳ [4/5] Đang xây dựng toàn bộ từ điển English-Vietnamese (en_vi_dict.json) từ WordNet...")
    
    if EN_VI_DICT_PATH.exists() and EN_VI_DICT_PATH.stat().st_size > 1024:
        print(f"  ✓ Từ điển đã có sẵn tại '{EN_VI_DICT_PATH}'.")
        return

    try:
        from deep_translator import GoogleTranslator
    except ImportError:
        print("  ⚠️ Thiếu thư viện 'deep-translator'. Vui lòng chạy lệnh: pip install deep-translator")
        return

    from nltk.corpus import wordnet as wn
    
    print("  ⬇️ Đang trích xuất toàn bộ từ vựng từ cơ sở dữ liệu WordNet...")
    all_words = sorted(list(set(
        lemma.name().replace('_', ' ').lower()
        for synset in wn.all_synsets()
        for lemma in synset.lemmas()
        if lemma.name().isalpha() and len(lemma.name()) > 1
    )))
    
    print(f"  📊 Tổng số từ vựng độc lập tìm thấy trong WordNet: {len(all_words):,} từ.")
    print("  🔄 Đang tiến hành dịch (quá trình này sẽ chạy nền và tự động bỏ qua các từ lỗi)...")

    translator = GoogleTranslator(source='en', target='vi')
    final_dict = {}
    
    for i, word in enumerate(all_words):
        try:
            res = translator.translate(word)
            if res:
                final_dict[word] = [res.lower()]
        except Exception:
            # Bỏ qua từ lỗi không dịch được để tiếp tục chạy mượt mà
            continue
            
        if (i + 1) % 100 == 0:
            print(f"  - Đã xử lý: {i + 1:,} / {len(all_words):,} từ...")

    with open(EN_VI_DICT_PATH, 'w', encoding='utf-8') as f:
        json.dump(final_dict, f, ensure_ascii=False, indent=2)
        
    print(f"  ✅ Đã build hoàn tất toàn bộ từ điển với {len(final_dict):,} từ vựng tại '{EN_VI_DICT_PATH}'!")


def download_wordlist(urls, dest: Path) -> bool:
    if dest.exists() and dest.stat().st_size > 0:
        print(f"  ✓ {dest.name}: Đã có sẵn.")
        return True

    for url in urls:
        try:
            print(f"  ⬇️ Đang tải {dest.name} từ {Path(url).name}...")
            urllib.request.urlretrieve(url, dest)
            print(f"  ✅ {dest.name}: Tải thành công.")
            return True
        except Exception as exc:
            print(f"  ⚠️ Thất bại ({url}): {exc}")
    return False


def setup_offline_environment():
    print("🚀 === BẮT ĐẦU CHUẨN BỊ MÔ HÌNH & DỮ LIỆU LOCAL ===")
    
    ensure_model_paths()

    if str(NLTK_DATA_DIR) not in nltk.data.path:
        nltk.data.path.insert(0, str(NLTK_DATA_DIR))

    os.environ["EASYOCR_MODULE_PATH"] = str(EASYOCR_DIR)
    os.environ["HF_HOME"] = str(KEYBERT_DIR.parent)

    # 1. Kiểm tra & tải NLTK Resources (Loại bỏ các gói ngôn ngữ phụ thuộc rườm rà không cần thiết)
    nltk_resources = [
        ("corpora/brown", "brown"),
        ("corpora/gutenberg", "gutenberg"),
        ("tokenizers/punkt", "punkt"),
        ("tokenizers/punkt_tab", "punkt_tab"),
        ("corpora/wordnet", "wordnet"),
        ("corpora/omw-1.4", "omw-1.4"),
    ]

    print("\n⏳ [1/5] Đang kiểm tra dữ liệu NLTK...")
    for resource_path, resource_id in nltk_resources:
        try:
            nltk.data.find(resource_path)
            print(f"  ✓ {resource_id}: Đã có sẵn.")
        except LookupError:
            print(f"  ⬇️ {resource_id}: Đang tải về...")
            nltk.download(resource_id, download_dir=str(NLTK_DATA_DIR), quiet=True)
            print(f"  ✅ {resource_id}: Tải thành công!")

    # 2. Kiểm tra EasyOCR
    print("\n⏳ [2/5] Đang kiểm tra mô hình EasyOCR...")
    try:
        reader = easyocr.Reader(
            ["en"],
            gpu=False,
            model_storage_directory=str(EASYOCR_DIR),
            download_enabled=True,
            verbose=False,
        )
        print(f"  ✓ EasyOCR models đã sẵn sàng tại '{EASYOCR_DIR}'.")
        del reader
    except Exception as exc:
        print(f"  ⚠️ Không thể tải EasyOCR hoàn toàn: {exc}")

    # 3. Kiểm tra KeyBERT & SentenceTransformers
    model_name = "all-MiniLM-L6-v2"
    save_path = KEYBERT_MODEL_DIR

    print(f"\n⏳ [3/5] Đang kiểm tra mô hình KeyBERT ({model_name})...")
    if save_path.exists() and any(save_path.iterdir()):
        print(f"  ✓ Model đã có sẵn tại '{save_path}'.")
    else:
        print("  ⬇️ Đang tải mô hình weights từ Hugging Face Hub...")
        model = SentenceTransformer(model_name, cache_folder=str(KEYBERT_DIR))
        model.save(str(save_path))
        KeyBERT(model=str(save_path))
        print(f"  ✅ Đã lưu mô hình thành công tại '{save_path}'!")

    # 4. Khởi tạo cấu trúc từ điển EN-VI an toàn
    build_en_vi_dict()

    # 5. Tải các bộ Wordlists (CEFR & Google Frequency)
    print("\n⏳ [5/5] Đang kiểm tra các bộ Wordlist (CEFR & Frequency)...")
    download_wordlist(CEFR_URLS, CEFR_TSV_PATH)
    download_wordlist(FREQ_URLS, FREQ_TXT_PATH)

    print("\n🎉 === HOÀN TẤT! TẤT CẢ DỮ LIỆU ĐÃ SẴN SÀNG CHO APP OFFLINE ===")


if __name__ == "__main__":
    setup_offline_environment()