import cv2
import numpy as np
import easyocr
import re
from typing import Tuple

class OCRExtractor:
    def __init__(self, languages: list = ['en'], gpu: bool = False):
        """
        Khởi tạo Engine OCR bằng EasyOCR.
        :param languages: Danh sách ngôn ngữ nhận diện (mặc định 'en' cho Tiếng Anh).
        :param gpu: Đặt True nếu có GPU CUDA để tăng tốc.
        """
        print("Loading EasyOCR Reader Engine...")
        self.reader = easyocr.Reader(languages, gpu=gpu)

    def preprocess_image(self, image_path: str) -> np.ndarray:
        """
        Tiền xử lý ảnh screenshot giúp tăng độ chính xác OCR.
        """
        # 1. Đọc ảnh
        img = cv2.imread(image_path)
        if img is None:
            raise FileNotFoundError(f"Không tìm thấy file ảnh tại: {image_path}")

        # 2. Chuyển sang ảnh xám (Grayscale)
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

        # 3. Khử nhiễu nhẹ (Bilateral Filter giữ lại cạnh chữ)
        denoised = cv2.bilateralFilter(gray, 9, 75, 75)

        # 4. Tăng độ tương phản (Adaptive Thresholding)
        # Giúp tách chữ đen ra khỏi nền xám/màu screenshot
        thresh = cv2.adaptiveThreshold(
            denoised, 255, 
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
            cv2.THRESH_BINARY, 31, 2
        )

        return thresh

    def clean_text(self, text: str) -> str:
        """
        Làm sạch text rác sau khi OCR trích xuất ra.
        """
        # Thay thế nhiều dấu cách/xuống dòng liên tiếp thành 1 dấu cách
        text = re.sub(r'\s+', ' ', text)
        # Bỏ bớt ký tự đặc biệt rác ở đầu/cuối chuỗi nếu có
        text = text.strip()
        return text

    def extract_text_from_image(self, image_path: str, use_preprocessing: bool = True) -> Tuple[str, float]:
        if use_preprocessing:
            processed_img = self.preprocess_image(image_path)
            results = self.reader.readtext(processed_img)
        else:
            results = self.reader.readtext(image_path)

        extracted_texts = []
        confidences = []

        for bbox, text, prob in results:
            # GIẢM THRESHOLD: Lấy cả các từ có độ tin cậy thấp (> 0.05 thay vì > 0.2)
            if prob > 0.05:
                extracted_texts.append(text)
                confidences.append(prob)

        full_text = " ".join(extracted_texts)
        cleaned_text = self.clean_text(full_text)
        avg_confidence = float(np.mean(confidences)) if confidences else 0.0

        return cleaned_text, round(avg_confidence, 2)