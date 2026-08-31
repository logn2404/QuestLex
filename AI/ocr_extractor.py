import cv2
import numpy as np
import easyocr
import re
import torch
import wordninja
from spellchecker import SpellChecker
from typing import Tuple
from functools import lru_cache
from concurrent.futures import ThreadPoolExecutor

class OCRExtractor:
    def __init__(self, languages: list = None, use_gpu: bool = None, max_workers: int = None):
        if languages is None:
            languages = ["en"]
            
        if use_gpu is None:
            use_gpu = torch.cuda.is_available() or torch.backends.mps.is_available()

        self.reader = easyocr.Reader(languages, gpu=use_gpu, quantize=True) 
        self.spell = SpellChecker() 
        
        # Determine optimal thread count for parallel CPU tasks (NLP correction)
        self.max_workers = max_workers 

    @lru_cache(maxsize=8192)
    def _correct_word(self, word_lower: str) -> str:
        if word_lower in self.spell: 
            return word_lower

        split_words = wordninja.split(word_lower) 
        if len(split_words) > 1:
            fixed_splits = []
            for w in split_words:
                if w == 'l':
                    w = 'i' 
                fixed_splits.append(self._safe_correction(w)) 
            return " ".join(fixed_splits) 
        return self._safe_correction(word_lower) 

    @lru_cache(maxsize=8192)
    def _safe_correction(self, word_lower: str) -> str:
        """Correct only when a valid, different dictionary word is proposed."""
        candidate = self.spell.correction(word_lower) 
        if (
            candidate
            and candidate != word_lower
            and candidate.isalpha()
            and (len(candidate) >= 3 or candidate in {"i", "a"})
        ): 
            return candidate 
        return word_lower 

    def enhance_image(self, image_path: str) -> np.ndarray:
        img = cv2.imread(image_path) 
        if img is None:
            return None 

        h, w = img.shape[:2] 
        max_dim = 960 
        min_dim = 640 

        # Downscale very large images (faster OCR), upscale tiny ones (better recall).
        if max(h, w) > max_dim:
            scale = max_dim / max(h, w) 
            img = cv2.resize(
                img, (int(w * scale), int(h * scale)), interpolation=cv2.INTER_AREA
            ) 
        elif min(h, w) < min_dim:
            scale = min_dim / min(h, w) 
            img = cv2.resize(
                img, (int(w * scale), int(h * scale)), interpolation=cv2.INTER_CUBIC
            ) 

        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) 
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8)) 
        return clahe.apply(gray) 

    def _correct_line(self, line: str) -> str:
        tokens = re.findall(r"[\w'-]+|[.,!?;]", line) 
        corrected_tokens = []

        for token in tokens:
            if re.match(r"^[.,!?;]$", token):
                if corrected_tokens:
                    corrected_tokens[-1] += token 
                continue

            if len(token) == 1 and token.lower() not in ['i', 'a'] and not token.isdigit():
                continue 

            pure_word = re.sub(r"[^A-Za-z0-9'-]", "", token) 
            if not pure_word:
                continue 

            if any(char.isdigit() for char in pure_word):
                corrected_tokens.append(pure_word) 
                continue

            if pure_word.istitle() or pure_word.isupper():
                corrected_tokens.append(pure_word) 
            else:
                corrected_tokens.append(self._correct_word(pure_word.lower())) 

        return " ".join(corrected_tokens) 

    def advanced_nlp_correction(self, text: str) -> str:
        if not text:
            return "" 

        lines = [line for line in text.splitlines() if line.strip()] 
        
        # Parallelize CPU-heavy spellchecking and word splitting
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            corrected_lines = list(executor.map(self._correct_line, lines)) 
            
        full_sentence = "\n".join(corrected_lines) 
        full_sentence = re.sub(r'\s+([.,!?;])', r'\1', full_sentence) 
        return full_sentence.strip() 

    def extract_text_from_image(self, image_path: str) -> Tuple[str, float]:
        processed_img = self.enhance_image(image_path) 
        if processed_img is None:
            return "", 0.0 

        results = self.reader.readtext(
            processed_img,
            adjust_contrast=False,
            width_ths=0.7,
            paragraph=True,
        ) 
        if not results:
            return "", 0.0 

        raw_text_parts = []
        confidences = []

        for item in results:
            if len(item) >= 3:
                text = item[1] 
                prob = item[2] 
            else:
                text = item[1] 
                prob = None

            text = text.strip() 
            
            if text and (prob is None or prob >= 0.30): 
                raw_text_parts.append(text) 
                if prob is not None:
                    confidences.append(prob) 

        if not raw_text_parts:
            return "", 0.0 

        raw_text = "\n".join(raw_text_parts) 
        average_confidence = float(np.mean(confidences)) if confidences else 0.60 

        # Skip NLP processing if OCR confidence is high
        if average_confidence > 0.85:
            clean_text = raw_text 
        else:
            clean_text = self.advanced_nlp_correction(raw_text) 

        return clean_text, round(average_confidence, 4) 