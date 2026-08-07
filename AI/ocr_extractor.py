import cv2
import numpy as np
import easyocr
import re
import torch
import wordninja
from spellchecker import SpellChecker
from typing import Tuple, List

class OCRExtractor:
    def __init__(self, languages: list = ['en'], gpu: bool = True):
        device = torch.cuda.is_available()
        self.reader = easyocr.Reader(languages, gpu=device)
        self.spell = SpellChecker()

    def enhance_image(self, image_path: str) -> np.ndarray:
        img = cv2.imread(image_path)
        scale_factor = 2.0
        resized = cv2.resize(img, None, fx=scale_factor, fy=scale_factor, interpolation=cv2.INTER_CUBIC)
        gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)
        denoised = cv2.fastNlMeansDenoising(gray, h=10, templateWindowSize=7, searchWindowSize=21)
        return cv2.addWeighted(denoised, 1.5, cv2.GaussianBlur(denoised, (0, 0), 3.0), -0.5, 0)

    def advanced_nlp_correction(self, text: str) -> str:
        if not text:
            return ""

        tokens = re.findall(r"[\w'-]+|[.,!?;]", text)
        corrected_tokens = []

        for token in tokens:
            if re.match(r"[.,!?;]", token):
                if corrected_tokens:
                    corrected_tokens[-1] += token
                continue

            if len(token) == 1 and token.lower() not in ['i', 'a']:
                continue 

            pure_word = re.sub(r"[^A-Za-z0-9'-]", "", token)
            if not pure_word:
                continue

            original_case_is_title = pure_word.istitle() or pure_word.isupper()
            word_lower = pure_word.lower()

            if original_case_is_title:
                # 1. Nếu từ có viết hoa -> Tự động tin đây là Tên riêng/Nhân vật/Game
                # -> BỎ QUA KIỂM TRA CHÍNH TẢ, giữ nguyên hiện trạng để không làm hỏng tên
                final_word = pure_word
            elif word_lower not in self.spell:
                # 2. Nếu là từ viết thường mà sai chính tả -> Đưa vào viện phẫu thuật
                split_words = wordninja.split(word_lower)
                
                if len(split_words) > 1:
                    fixed_splits = []
                    for w in split_words:
                        if w == 'l': w = 'i' 
                        corrected_w = self.spell.correction(w) or w
                        fixed_splits.append(corrected_w)
                    final_word = " ".join(fixed_splits)
                else:
                    final_word = self.spell.correction(word_lower) or word_lower
            else:
                # 3. Từ tiếng Anh bình thường, viết đúng
                final_word = word_lower

            corrected_tokens.append(final_word)

        full_sentence = " ".join(corrected_tokens)
        full_sentence = re.sub(r'\s+([.,!?;])', r'\1', full_sentence)
        
        return full_sentence.strip()

    def extract_text_from_image(self, image_path: str) -> Tuple[str, float]:
        processed_img = self.enhance_image(image_path)
        
        results = self.reader.readtext(processed_img, paragraph=True)
        if not results:
            return "", 0.0

        raw_text_parts = [text.strip() for bbox, text in results if text.strip()]
        raw_text = " ".join(raw_text_parts)
        
        clean_text = self.advanced_nlp_correction(raw_text)

        return clean_text, 0.95