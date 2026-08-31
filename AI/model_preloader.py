import threading

_ocr_engine = None
_vocab_engine = None

_ocr_ready = threading.Event()
_vocab_ready = threading.Event()

_start_lock = threading.Lock()
_started = False


def start_preload() -> None:
    global _started
    with _start_lock:
        if _started:
            return
        _started = True

    _ocr_ready.clear()
    _vocab_ready.clear()
    
    threading.Thread(
        target=_preload_all,
        name="questlex-model-preloader",
        daemon=True,
    ).start()


def _preload_all() -> None:
    t_ocr = threading.Thread(target=_preload_ocr, name="ocr-loader", daemon=True)
    t_vocab = threading.Thread(target=_preload_vocab, name="vocab-loader", daemon=True)

    t_ocr.start()
    t_vocab.start()

    t_ocr.join()
    t_vocab.join()


def _preload_ocr() -> None:
    global _ocr_engine
    try:
        import torch
        from ocr_extractor import OCRExtractor
        use_gpu = torch.cuda.is_available() or torch.backends.mps.is_available()
        _ocr_engine = OCRExtractor(languages=["en"], use_gpu=use_gpu)
    except Exception as exc:
        print(f"⚠️ Không thể nạp trước mô hình OCR: {exc}")
    finally:
        _ocr_ready.set()


def _preload_vocab() -> None:
    global _vocab_engine
    try:
        from vocab_extractor import VocabularyExtractor
        _vocab_engine = VocabularyExtractor(spacy_model="en_core_web_sm")
    except Exception as exc:
        print(f"⚠️ Không thể nạp trước mô hình từ vựng: {exc}")
    finally:
        _vocab_ready.set()


def is_ocr_ready() -> bool:
    return _ocr_ready.is_set()


def is_vocab_ready() -> bool:
    return _vocab_ready.is_set()


def get_ocr_engine():
    _ocr_ready.wait()
    return _ocr_engine


def get_vocab_engine():
    _vocab_ready.wait()
    return _vocab_engine