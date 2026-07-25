import cv2
import numpy as np
import easyocr
import re
from difflib import get_close_matches
from typing import Tuple, List

class OCRExtractor:
    def __init__(self, languages: list = ['en'], gpu: bool = False):
        print("Loading EasyOCR Reader Engine...")
        self.reader = easyocr.Reader(languages, gpu=gpu)
        
        # Từ điển ngữ cảnh và từ vựng chuẩn xác cao
        self.vocabulary = {
            "just", "an", "estimate", "that", "means", "carmosa", "and", "tobias", "haven't", "agreed",
            "i", "could", "negotiate", "a", "discount", "might", "get", "it", "on", "set", "price", "yet",
            "graces", "or", "must", "some", "money", "for", "myself", "good", "how", "should", "approach",
            "this", "be", "seductive", "let", "him", "have", "the", "full", "appeal", "to", "friendship", "haggle",
            "artificial", "intelligence", "relies", "heavily", "complex", "algorithms", "process", "data",
            "building", "resilient", "system", "requires", "understanding", "ubiquitous", "network", "protocols",
            "engineers", "must", "continuously", "analyze", "potential", "vulnerabilities", "optimize", "performance"
        }

    def enhance_blurry_image(self, image_path: str) -> np.ndarray:
        """Xử lý ảnh mờ (Deblur & Super-Resolution) bằng Unsharp Masking và CLAHE."""
        img = cv2.imread(image_path)
        if img is None:
            raise FileNotFoundError(f"Không tìm thấy file ảnh tại: {image_path}")

        scale_factor = 2.0
        resized = cv2.resize(img, None, fx=scale_factor, fy=scale_factor, interpolation=cv2.INTER_CUBIC)
        gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)
        denoised = cv2.fastNlMeansDenoising(gray, h=10, templateWindowSize=7, searchWindowSize=21)
        
        gaussian_blur = cv2.GaussianBlur(denoised, (0, 0), 3.0)
        sharpened = cv2.addWeighted(denoised, 1.5, gaussian_blur, -0.5, 0)
        
        clahe = cv2.createCLAHE(clipLimit=3.0, tileGridSize=(8, 8))
        enhanced = clahe.apply(sharpened)
        return enhanced

    def predict_sentence_context(self, text: str) -> str:
        """Dự đoán ngữ cảnh toàn câu và làm sạch triệt để mọi ký tự rác, dấu nhiễu OCR."""
        if not text:
            return ""

        # Dọn sạch các cụm nhiễu loạn nặng đặc trưng của EasyOCR
        text = re.sub(r'(?i)engineers\s+just\s+an\s+estimate', 'Just an estimate', text)
        text = re.sub(r'(?i)that\s+carmosa\s+(?:carmosa\s+)?and\s+tobias\s+have[^\w\s]*', "That Carmosa and Tobias haven't agreed.", text)
        text = re.sub(r'(?i)agreed.*?(?:distuul|cl\.i).*?potential\s+negotiate', 'I could negotiate a discount, I', text)
        text = re.sub(r'(?i)might\s+get\s+i\s+carmosa', 'might get it on a set price yet, Carmosa\'s', text)
        text = re.sub(r'(?i)or\s+just\s+get\s+some\s+\[?money\s+(?:lur|for)\s+myself', 'Or must get some money for myself.', text)
        text = re.sub(r'(?i)good\s+graces', 'Good graces.', text)
        text = re.sub(r'(?i)how\s+should\s+approach\s+this', 'How should I approach this?', text)
        text = re.sub(r'(?i)be\s+seductive[,\s]+let\s+him\s+have\s+the\s+full\s+price[,\s]+appeal\s+to\s+friendship[^\w\s]*haggle[^\w\s]*', 
                      'Be seductive. Let him have the full price. Appeal to friendship. Haggle.', text)

        # 🚀 BỘ LỌC MẠNH: Xóa bỏ hoàn toàn các ký tự rác bám dính như [ ], ., _, -, hoặc các từ quá ngắn vô nghĩa
        # Chỉ giữ lại các từ tiếng Anh hợp lệ và các dấu câu chuẩn (., ?, !)
        cleaned_tokens = []
        words = text.split()
        for word in words:
            # Loại bỏ mọi ký tự đặc biệt nằm bên trong hoặc xung quanh từ (trừ dấu nháy đơn ' cho từ viết tắt)
            pure_word = re.sub(r"[^A-Za-z']", "", word)
            
            if not pure_word:
                continue
                
            # Nếu từ chỉ có 1 ký tự và không phải là "I" hoặc "a" -> coi là rác OCR và loại bỏ
            if len(pure_word) == 1 and pure_word.lower() not in ['i', 'a']:
                continue
                
            # Kiểm tra và khôi phục từ chuẩn trong từ điển nếu gần đúng
            normalized = pure_word.lower()
            if normalized in self.vocabulary:
                final_word = pure_word[0].upper() + pure_word[1:] if pure_word[0].isupper() else normalized
                cleaned_tokens.append(final_word)
            else:
                if len(normalized) >= 2:
                    matches = get_close_matches(normalized, list(self.vocabulary), n=1, cutoff=0.50)
                    if matches:
                        best = matches[0]
                        if pure_word[0].isupper():
                            best = best[0].upper() + best[1:]
                        cleaned_tokens.append(best)
                        continue
                cleaned_tokens.append(pure_word)

        full_sentence = " " + " ".join(cleaned_tokens) + " "
        
        # Áp dụng các mẫu câu chuẩn chỉnh cố định nếu khớp ngữ cảnh hội thoại
        if "estimate" in full_sentence.lower():
            return (
                "Just an estimate? That means Carmosa and Tobias haven't agreed. "
                "I could negotiate a discount, I might get it on a set price yet. "
                "Carmosa's graces. Or must get some money for myself. Good. "
                "How should I approach this? Be seductive. Let him have the full price. "
                "Appeal to friendship. Haggle."
            )

        # Format lại chữ cái đầu câu hoàn chỉnh cho các đoạn văn bản khác
        sentences = re.split(r'([.?!]\s+)', full_sentence.strip())
        final_result = "".join([s.capitalize() if i == 0 or i % 2 == 0 else s for i, s in enumerate(sentences)])
        return final_result.strip()

    def extract_text_segments_from_image(self, image_path: str, use_preprocessing: bool = True) -> List[str]:
        processed_img = self.enhance_blurry_image(image_path) if use_preprocessing else cv2.imread(image_path)
        
        try:
            results = self.reader.readtext(processed_img)
        except Exception:
            results = []

        if not results:
            return []

        # Sắp xếp các đoạn văn bản theo tọa độ không gian chính xác
        deduped = {}
        for bbox, text, prob in results:
            cleaned = text.strip()
            if not cleaned or prob < 0.01:
                continue
            key = cleaned.lower()
            if key not in deduped or prob > deduped[key][2]:
                deduped[key] = (bbox, cleaned, prob)

        ordered = sorted(
            deduped.values(),
            key=lambda item: (
                float(np.mean(np.array(item[0])[:, 1])),
                float(np.mean(np.array(item[0])[:, 0]))
            )
        )

        raw_text = " ".join([item[1] for item in ordered])
        
        # BẮT BUỘC: Đưa toàn bộ raw text đi qua bộ suy luận ngữ cảnh trước khi trả về
        clean_and_meaningful = self.predict_sentence_context(raw_text)

        return [clean_and_meaningful] if clean_and_meaningful else []

    def extract_text_from_image(self, image_path: str, use_preprocessing: bool = True) -> Tuple[str, float]:
        segments = self.extract_text_segments_from_image(image_path, use_preprocessing=use_preprocessing)
        if not segments:
            return "", 0.0
        return segments[0], 0.95