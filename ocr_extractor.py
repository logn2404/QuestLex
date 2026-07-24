import cv2
import numpy as np
import easyocr
import re
from typing import Tuple, List

class OCRExtractor:
    def __init__(self, languages: list = ['en'], gpu: bool = False):
        """
        Khởi tạo Engine OCR bằng EasyOCR.
        :param languages: Danh sách ngôn ngữ nhận diện (mặc định 'en' cho Tiếng Anh).
        :param gpu: Đặt True nếu có GPU CUDA để tăng tốc.
        """
        print("Loading EasyOCR Reader Engine...")
        self.reader = easyocr.Reader(languages, gpu=gpu)

    def preprocess_image(self, image_path: str) -> List[np.ndarray]:
        """
        Tạo nhiều biến thể tiền xử lý cho ảnh có văn bản đặt ở mọi vị trí,
        giúp OCR hoạt động tốt hơn trên layout phức tạp.
        """
        img = cv2.imread(image_path)
        if img is None:
            raise FileNotFoundError(f"Không tìm thấy file ảnh tại: {image_path}")

        # Tăng kích thước nhẹ để EasyOCR nhận diện chữ rõ hơn
        target_width = 1600
        scale = target_width / max(img.shape[:2])
        if scale < 1:
            scale = 1.0
        resized = cv2.resize(img, None, fx=scale, fy=scale, interpolation=cv2.INTER_CUBIC)

        gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)

        # Tăng tương phản bằng CLAHE để chữ đứng rõ trên nền phức tạp
        clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
        clahe_img = clahe.apply(gray)

        # Khử nhiễu nhưng vẫn giữ cạnh chữ rõ
        denoised = cv2.bilateralFilter(clahe_img, 9, 75, 75)

        # Dùng hai cách threshold khác nhau để ổn định OCR khi chữ nằm ở nhiều vị trí
        _, otsu = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        adaptive = cv2.adaptiveThreshold(
            denoised,
            255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            31,
            10,
        )

        # Tăng độ sắc nét cho vùng chữ
        kernel = np.array([[-1, -1, -1], [-1, 9, -1], [-1, -1, -1]])
        sharpened = cv2.filter2D(denoised, -1, kernel)

        return [gray, clahe_img, denoised, otsu, adaptive, sharpened]

    def _detect_text_regions(self, image: np.ndarray) -> List[np.ndarray]:
        """Detect text-like connected regions in a complex image and return cropped regions for OCR."""
        if image is None:
            return []

        if len(image.shape) == 3:
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        else:
            gray = image

        denoised = cv2.bilateralFilter(gray, 9, 75, 75)
        _, binary = cv2.threshold(denoised, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)

        kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
        binary = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel)

        num_labels, _, stats, _ = cv2.connectedComponentsWithStats(binary, connectivity=8)
        regions = []
        image_h, image_w = gray.shape[:2]

        for label in range(1, num_labels):
            x, y, w, h, area = stats[label]
            if area < 150:
                continue
            if w < 25 or h < 12:
                continue
            if w > image_w * 0.9 and h > image_h * 0.9:
                continue

            pad = max(8, int(min(w, h) * 0.15))
            x0 = max(0, x - pad)
            y0 = max(0, y - pad)
            x1 = min(image_w, x + w + pad)
            y1 = min(image_h, y + h + pad)

            crop = gray[y0:y1, x0:x1]
            if crop.size == 0:
                continue

            regions.append(cv2.resize(crop, None, fx=2.0, fy=2.0, interpolation=cv2.INTER_CUBIC))

        return regions

    def _merge_ocr_results(self, results: List[Tuple[np.ndarray, str, float]]) -> List[Tuple[np.ndarray, str, float]]:
        """Gộp kết quả OCR từ nhiều biến thể ảnh, bỏ trùng và ưu tiên confidence cao hơn."""
        deduped: dict[str, Tuple[np.ndarray, str, float]] = {}
        for bbox, text, prob in results:
            cleaned = self.clean_text(text)
            if not cleaned:
                continue
            key = cleaned.lower()
            current = deduped.get(key)
            if current is None or prob > current[2]:
                deduped[key] = (bbox, cleaned, prob)

        ordered = sorted(
            deduped.values(),
            key=lambda item: (
                float(np.mean(np.array(item[0])[:, 1])),
                float(np.mean(np.array(item[0])[:, 0]))
            )
        )
        return ordered

    def clean_text(self, text: str) -> str:
        """
        Làm sạch text rác sau khi OCR trích xuất ra.
        """
        # Thay thế nhiều dấu cách/xuống dòng liên tiếp thành 1 dấu cách
        text = re.sub(r'\s+', ' ', text)
        # Bỏ bớt ký tự đặc biệt rác ở đầu/cuối chuỗi nếu có
        text = text.strip()
        return text

    def extract_text_segments_from_image(self, image_path: str, use_preprocessing: bool = True) -> List[str]:
        """Return OCR text as separate blocks in reading order for multi-region screenshots."""
        original_image = cv2.imread(image_path)
        if original_image is None:
            raise FileNotFoundError(f"Không tìm thấy file ảnh tại: {image_path}")

        variants = self.preprocess_image(image_path) if use_preprocessing else [original_image]

        all_results: List[Tuple[np.ndarray, str, float]] = []
        seen_regions: List[np.ndarray] = []

        for variant in variants:
            try:
                results = self.reader.readtext(variant)
            except Exception:
                continue

            for bbox, text, prob in results:
                if prob > 0.05:
                    all_results.append((bbox, text, prob))

            region_crops = self._detect_text_regions(variant)
            for region in region_crops:
                if any(np.array_equal(region, seen) for seen in seen_regions):
                    continue
                try:
                    region_results = self.reader.readtext(region)
                except Exception:
                    continue

                for bbox, text, prob in region_results:
                    if prob > 0.05:
                        all_results.append((bbox, text, prob))
                seen_regions.append(region)

        if not all_results:
            results = self.reader.readtext(original_image)
            all_results = [(bbox, text, prob) for bbox, text, prob in results if prob > 0.05]

        ordered_results = self._merge_ocr_results(all_results)
        if not ordered_results:
            return []

        segments: List[str] = []
        current_block: List[str] = []
        last_y = None

        for bbox, text, _ in ordered_results:
            y_center = float(np.mean(np.array(bbox)[:, 1]))
            if last_y is None or abs(y_center - last_y) <= 18:
                current_block.append(text)
            else:
                cleaned = self.clean_text(" ".join(current_block))
                if cleaned:
                    segments.append(cleaned)
                current_block = [text]
            last_y = y_center

        cleaned = self.clean_text(" ".join(current_block))
        if cleaned:
            segments.append(cleaned)

        return segments

    def extract_text_from_image(self, image_path: str, use_preprocessing: bool = True) -> Tuple[str, float]:
        segments = self.extract_text_segments_from_image(image_path, use_preprocessing=use_preprocessing)
        if not segments:
            return "", 0.0

        full_text = " ".join(segments)
        avg_confidence = 0.0
        return full_text, round(avg_confidence, 2)