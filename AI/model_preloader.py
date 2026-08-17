"""
AI/model_preloader.py — prepare heavy AI engines in the background.

Turns the first-scan 1-minute model load into a background task that starts
as soon as the app opens. The menu, flashcard and history stay instant; by the
time the user picks "scan", EasyOCR/torch and spaCy/KeyBERT are usually warm.

Usage:
    import model_preloader
    model_preloader.start_preload()           # at app startup, returns instantly
    ocr   = model_preloader.get_ocr_engine()  # blocks until ready (rarely), or None on failure
    vocab = model_preloader.get_vocab_engine()
    if model_preloader.is_vocab_ready(): ...  # non-blocking status check

Threading model:
    - One daemon thread loads OCR first, then vocabulary.
    - Engine references are published to module globals and read only after an
      Event is set, giving a happens-before edge — safe under the GIL.
    - EasyOCR/Reader is only ever used from the main scan path afterward.
"""
import threading

_ocr_engine = None
_vocab_engine = None

_ocr_ready = threading.Event()
_vocab_ready = threading.Event()

_start_lock = threading.Lock()
_started = False


def start_preload() -> None:
    """Kick off background model loading. Idempotent — safe to call repeatedly."""
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
    # OCR first: EasyOCR + torch is the heaviest load (~1-2 min on first run
    # when models must be downloaded).
    _preload_ocr()
    _preload_vocab()


def _preload_ocr() -> None:
    global _ocr_engine
    try:
        import torch
        from ocr_extractor import OCRExtractor

        use_gpu = torch.cuda.is_available()
        _ocr_engine = OCRExtractor(languages=["en"], use_gpu=use_gpu)
    except Exception as exc:
        print(f"⚠️ Không thể nạp trước mô hình OCR: {exc}")
    finally:
        _ocr_ready.set()


def _preload_vocab() -> None:
    global _vocab_engine
    try:
        from vocab_extractor import VocabularyExtractor

        # VocabularyExtractor spawns its own internal background thread for the
        # spaCy/KeyBERT load, so this constructor returns almost immediately.
        # process_text() waits on that internal thread whenever it is needed.
        _vocab_engine = VocabularyExtractor(spacy_model="en_core_web_sm")
    except Exception as exc:
        print(f"⚠️ Không thể nạp trước mô hình từ vựng: {exc}")
    finally:
        _vocab_ready.set()


def is_ocr_ready() -> bool:
    """Non-blocking: True when the OCR engine finished (or failed) loading."""
    return _ocr_ready.is_set()


def is_vocab_ready() -> bool:
    """Non-blocking: True when the vocab engine finished (or failed) loading."""
    return _vocab_ready.is_set()


def get_ocr_engine():
    """Return the preloaded OCR engine, blocking until it is ready.

    Returns None if background loading failed (e.g. missing torch/EasyOCR),
    which the caller should surface as a user-facing error.
    """
    _ocr_ready.wait()
    return _ocr_engine


def get_vocab_engine():
    """Return the preloaded vocab engine, blocking until it is ready.

    Returns None if background loading failed.
    """
    _vocab_ready.wait()
    return _vocab_engine
