import os
import pickle
import re
from pathlib import Path
from typing import Dict, List

import nltk
from nltk.corpus import brown, gutenberg
from nltk.stem import WordNetLemmatizer
from nltk.tokenize import sent_tokenize, word_tokenize

PROJECT_DIR = Path(__file__).resolve().parent
MODELS_DIR = PROJECT_DIR / "models"
NLTK_INDEX_CACHE_PATH = MODELS_DIR / "nltk_index_cache.pkl"


def ensure_model_paths():
    MODELS_DIR.mkdir(exist_ok=True)
    if not NLTK_INDEX_CACHE_PATH.exists():
        with NLTK_INDEX_CACHE_PATH.open("wb") as handle:
            pickle.dump({}, handle)


class NLTKExampleExtractor:
    def __init__(self, min_words: int = 6, max_words: int = 16, cache_path: str | None = None):
        ensure_model_paths()
        self.min_words = min_words
        self.max_words = max_words
        self.lemmatizer = WordNetLemmatizer()
        self.cache_path = Path(cache_path) if cache_path else NLTK_INDEX_CACHE_PATH
        self.index: Dict[str, List[str]] = {}

        if self.cache_path.exists():
            with self.cache_path.open("rb") as f:
                self.index = pickle.load(f)
        else:
            self._build_index()
            with self.cache_path.open("wb") as f:
                pickle.dump(self.index, f)

    def _is_clean_sentence(self, token_list: List[str]) -> bool:
        if not (self.min_words <= len(token_list) <= self.max_words):
            return False

        if not token_list[0][0].isupper():
            return False

        if token_list[-1] not in {".", "?", "!"}:
            return False

        alpha_tokens = [t for t in token_list if t.isalpha()]
        if len(alpha_tokens) / len(token_list) < 0.75:
            return False

        return True

    def _format_sentence(self, token_list: List[str]) -> str:
        raw_text = " ".join(token_list)
        clean_text = re.sub(r'\s+([.,?!;:\'\"])', r'\1', raw_text)
        return clean_text

    def _build_index(self):
        raw_texts = []
        try:
            raw_texts.append(brown.raw())
        except Exception:
            pass
            
        try:
            raw_texts.append(gutenberg.raw())
        except Exception:
            pass

        combined_sentences = []
        for raw_text in raw_texts:
            sentences = sent_tokenize(raw_text)
            for sent in sentences:
                tokens = word_tokenize(sent)
                if tokens:
                    combined_sentences.append(tokens)

        for token_list in combined_sentences:
            if not self._is_clean_sentence(token_list):
                continue

            formatted_sentence = self._format_sentence(token_list)

            seen_keys = set()
            for token in token_list:
                if token.isalpha():
                    lowered = token.lower()
                    lemma = self.lemmatizer.lemmatize(lowered)
                    seen_keys.add(lowered)
                    seen_keys.add(lemma)

            for key in seen_keys:
                if key not in self.index:
                    self.index[key] = []
                if len(self.index[key]) < 5:
                    self.index[key].append(formatted_sentence)

    def get_example_sentence(self, word: str, fallback: str = "") -> str:
        """Retrieves the shortest, cleanest example sentence for a target word."""
        target = word.lower().strip()
        lemma = self.lemmatizer.lemmatize(target)

        candidates = self.index.get(target) or self.index.get(lemma)

        if candidates:
            return min(candidates, key=len)

        return fallback