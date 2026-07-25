import re
import string
from typing import Dict, List, Optional
import nltk

# ------------------------------------------------------------------
# 1. Download Required NLTK Corpora & Tokenizers
# ------------------------------------------------------------------
NLTK_RESOURCES = [
    ("corpora/brown", "brown"),
    ("corpora/gutenberg", "gutenberg"),
    ("tokenizers/punkt", "punkt"),
    ("tokenizers/punkt_tab", "punkt_tab"),
    ("corpora/wordnet", "wordnet"),
    ("corpora/omw-1.4", "omw-1.4"),
]

for resource_path, resource_id in NLTK_RESOURCES:
    try:
        nltk.data.find(resource_path)
    except LookupError:
        nltk.download(resource_id, quiet=True)

from nltk.corpus import brown, gutenberg
from nltk.stem import WordNetLemmatizer
from nltk.tokenize import sent_tokenize, word_tokenize


class NLTKExampleExtractor:
    """
    Extracts concise, high-quality example sentences for English words
    using offline NLTK corpora (Brown and Gutenberg).
    """

    def __init__(self, min_words: int = 6, max_words: int = 16):
        self.min_words = min_words
        self.max_words = max_words
        self.lemmatizer = WordNetLemmatizer()

        # Inverted Index mapping: word_lemma -> List[clean_sentences]
        self.index: Dict[str, List[str]] = {}
        self._build_index()

    def _is_clean_sentence(self, token_list: List[str]) -> bool:
        """Validates whether a sentence token sequence meets grammar standards."""
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
        """Joins tokens back into a natural sentence string."""
        raw_text = " ".join(token_list)
        clean_text = re.sub(r'\s+([.,?!;:\'\"])', r'\1', raw_text)
        return clean_text

    def _build_index(self):
        """Pre-indexes NLTK corpora using safe manual sentence tokenization."""
        print("Building NLTK index from Brown and Gutenberg corpora...")
        
        # Gather raw text chunks safely to avoid tokenizer exceptions
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
            # Safely split raw text into sentences and tokenize words
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

        print(f"Indexing complete. Built database for {len(self.index):,} unique vocabulary terms.\n")

    def get_example_sentence(self, word: str, fallback: str = "") -> str:
        """Retrieves the shortest, cleanest example sentence for a target word."""
        target = word.lower().strip()
        lemma = self.lemmatizer.lemmatize(target)

        candidates = self.index.get(target) or self.index.get(lemma)

        if candidates:
            return min(candidates, key=len)

        return fallback