from pathlib import Path
from typing import Iterable, Set, Tuple

import numpy as np
from PIL import Image, ImageStat


class ImageQuickFilter:
    """Lightweight pre-filter that runs before OCR without loading an AI model."""

    def __init__(self, hash_size: int = 16, duplicate_distance: int = 6):
        self.hash_size = hash_size
        self.duplicate_distance = duplicate_distance

    def _perceptual_hash(self, image_path: Path) -> np.ndarray:
        with Image.open(image_path) as image:
            grayscale = image.convert("L").resize(
                (self.hash_size, self.hash_size),
                Image.Resampling.BILINEAR,
            )
            pixels = np.asarray(grayscale, dtype=np.float32)

        return pixels >= pixels.mean()

    def _is_low_quality(self, image_path: Path) -> bool:
        with Image.open(image_path) as image:
            width, height = image.size
            if width < 160 or height < 90:
                return True

            grayscale = image.convert("L")
            brightness = ImageStat.Stat(grayscale).mean[0]
            variance = ImageStat.Stat(grayscale).var[0]

        # Only reject almost empty/flat images. Text screenshots remain eligible.
        return (brightness < 3 or brightness > 252) and variance < 8

    def classify(
        self,
        image_path: Path,
        seen_hashes: Iterable[np.ndarray],
    ) -> Tuple[str, np.ndarray | None]:
        try:
            if self._is_low_quality(image_path):
                return "low_quality", None

            image_hash = self._perceptual_hash(image_path)
            for previous_hash in seen_hashes:
                distance = int(np.count_nonzero(image_hash != previous_hash))
                if distance <= self.duplicate_distance:
                    return "duplicate", image_hash

            return "process", image_hash
        except (OSError, ValueError) as error:
            print(f"[AI DEBUG] quick_filter_error file={image_path.name} error={error}", flush=True)
            return "low_quality", None
