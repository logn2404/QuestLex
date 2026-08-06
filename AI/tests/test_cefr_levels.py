import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from vocab_extractor import VocabularyExtractor


def test_cefr_level_thresholds_are_more_separated():
    extractor = VocabularyExtractor(spacy_model="en_core_web_sm")

    assert extractor.get_cefr_level("apple") == "A1"
    assert extractor.get_cefr_level("important") == "B1"
    assert extractor.get_cefr_level("algorithm") == "C1"
    assert extractor.get_cefr_level("resilient") == "C2"
