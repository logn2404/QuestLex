from pathlib import Path
import urllib.request

PROJECT_DIR = Path(__file__).resolve().parent
WORDLISTS_DIR = PROJECT_DIR / "models" / "wordlists"
CEFR_TSV_PATH = WORDLISTS_DIR / "cefr.tsv"

# CEFR-J: CC BY 4.0 wordlist with CEFR levels per word.
CEFR_URLS = [
    "https://raw.githubusercontent.com/naist-nlp/cefr-spelling/master/source/cefr_lists.tsv",
]
# Fallback plain wordlists (A1..C2 sublists) from the CEFR project mirrors.
CEFR_FALLBACK_URLS = [
    "https://raw.githubusercontent.com/CEFR-Lists/cefr-list/main/cefr_list.tsv",
]

# Canonical Google 10000 most common English words (frequency proxy).
FREQ_URLS = [
    "https://raw.githubusercontent.com/first20hours/google-10000-english/master/google-10000-english-no-swears.txt",
]


def ensure_dirs():
    WORDLISTS_DIR.mkdir(parents=True, exist_ok=True)


def download(urls, dest: Path) -> bool:
    if dest.exists() and dest.stat().st_size > 0:
        print(f"  ✓ {dest.name}: đã có sẵn.")
        return True

    for url in urls:
        try:
            print(f"  ⬇️  Đang tải {Path(url).name} ...")
            urllib.request.urlretrieve(url, dest)
            print(f"  ✅ {dest.name}: tải thành công.")
            return True
        except Exception as exc:
            print(f"  ⚠️  Thất bại ({url}): {exc}")
    return False


def main():
    print("🚀 === CHUẨN BỊ WORDLIST OFFLINE ===")
    ensure_dirs()

    print("\n[1/1] Wordlist CEFR (word<TAB>level)...")
    download(CEFR_URLS + CEFR_FALLBACK_URLS, CEFR_TSV_PATH)

    print("\n🎉 === HOÀN TẤT! Dữ liệu từ vựng đã sẵn sàng ở 'models/wordlists/' ===")
    print("Bạn có thể xoá cefr.tsv nếu muốn tải lại; mọi dòng bắt đầu bằng '#' sẽ bị bỏ qua.")


if __name__ == "__main__":
    main()
