import os
import pickle
from pathlib import Path

import easyocr
import nltk
from keybert import KeyBERT
from sentence_transformers import SentenceTransformer

PROJECT_DIR = Path(__file__).resolve().parent
MODELS_DIR = PROJECT_DIR / "models"
NLTK_DATA_DIR = MODELS_DIR / "nltk_data"
EASYOCR_DIR = MODELS_DIR / "easyocr"
KEYBERT_DIR = MODELS_DIR / "keybert"
KEYBERT_MODEL_DIR = KEYBERT_DIR / "all-MiniLM-L6-v2"
NLTK_INDEX_CACHE_PATH = MODELS_DIR / "nltk_index_cache.pkl"


def ensure_model_paths():
    MODELS_DIR.mkdir(exist_ok=True)
    NLTK_DATA_DIR.mkdir(exist_ok=True)
    EASYOCR_DIR.mkdir(exist_ok=True)
    KEYBERT_DIR.mkdir(exist_ok=True)
    if not NLTK_INDEX_CACHE_PATH.exists():
        with NLTK_INDEX_CACHE_PATH.open("wb") as handle:
            pickle.dump({}, handle)


def setup_offline_environment():
    print("🚀 === BẮT ĐẦU CHUẨN BỊ MÔ HÌNH & DỮ LIỆU LOCAL ===")

    ensure_model_paths()

    if not NLTK_INDEX_CACHE_PATH.exists():
        with NLTK_INDEX_CACHE_PATH.open("wb") as handle:
            pickle.dump({}, handle)

    if str(NLTK_DATA_DIR) not in nltk.data.path:
        nltk.data.path.append(str(NLTK_DATA_DIR))

    os.environ["EASYOCR_MODULE_PATH"] = str(EASYOCR_DIR)
    os.environ["HF_HOME"] = str(KEYBERT_DIR.parent)

    nltk_resources = [
        ("corpora/brown", "brown"),
        ("corpora/gutenberg", "gutenberg"),
        ("tokenizers/punkt", "punkt"),
        ("tokenizers/punkt_tab", "punkt_tab"),
        ("corpora/wordnet", "wordnet"),
        ("corpora/omw-1.4", "omw-1.4"),
    ]

    print("\n⏳ [1/3] Đang kiểm tra dữ liệu NLTK...")
    for resource_path, resource_id in nltk_resources:
        try:
            nltk.data.find(resource_path)
            print(f"  ✓ {resource_id}: Đã có sẵn.")
        except LookupError:
            print(f"  ⬇️ {resource_id}: Đang tải về '{NLTK_DATA_DIR}'...")
            nltk.download(resource_id, download_dir=str(NLTK_DATA_DIR), quiet=True)
            print(f"  ✅ {resource_id}: Tải thành công!")

    print("\n⏳ [2/3] Đang kiểm tra mô hình EasyOCR...")
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

    model_name = "all-MiniLM-L6-v2"
    save_path = KEYBERT_MODEL_DIR

    print(f"\n⏳ [3/3] Đang kiểm tra mô hình KeyBERT ({model_name})...")
    if save_path.exists() and any(save_path.iterdir()):
        print(f"  ✓ Model đã có sẵn tại '{save_path}'.")
    else:
        print("  ⬇️ Đang tải mô hình weights từ Hugging Face Hub...")
        model = SentenceTransformer(model_name, cache_folder=str(KEYBERT_DIR))
        model.save(str(save_path))
        KeyBERT(model=str(save_path))
        print(f"  ✅ Đã lưu mô hình thành công tại '{save_path}'!")

    print("\n🎉 === HOÀN TẤT! TẤT CẢ DỮ LIỆU ĐÃ SẴN SÀNG CHO APP OFFLINE ===")


if __name__ == "__main__":
    setup_offline_environment()