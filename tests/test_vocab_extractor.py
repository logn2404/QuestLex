import os
import tempfile
import unittest
from PIL import Image, ImageDraw, ImageFont

from revision_engine import RevisionEngine
from vocab_extractor import VocabularyExtractor
from ocr_extractor import OCRExtractor


class VocabularyExtractorScoringTest(unittest.TestCase):
    def test_partial_weights_are_filled_with_defaults(self):
        extractor = VocabularyExtractor(spacy_model="en_core_web_sm")
        text = "Artificial intelligence relies heavily on complex algorithms to process data."
        user_history = {"learned_words": {}}

        results = extractor.process_text(
            text=text,
            user_history=user_history,
            top_k=1,
            weights={"keybert": 0.6}
        )

        self.assertEqual(len(results), 1)
        self.assertIn("questlex_score", results[0])

    def test_prefers_specialized_terms_over_easy_common_words(self):
        extractor = VocabularyExtractor(spacy_model="en_core_web_sm")
        text = (
            "Artificial intelligence relies heavily on complex algorithms to process data. "
            "Apples are common fruit and easy to recognize."
        )
        user_history = {"learned_words": {}}

        results = extractor.process_text(
            text=text,
            user_history=user_history,
            top_k=5,
        )

        ranked_words = [item["word"] for item in results]
        self.assertLess(ranked_words.index("algorithm"), ranked_words.index("fruit"))

    def test_all_ranked_candidates_can_be_returned_without_a_cap(self):
        extractor = VocabularyExtractor(spacy_model="en_core_web_sm")
        text = "Artificial intelligence relies heavily on complex algorithms to process data."
        user_history = {"learned_words": {}}

        results = extractor.process_text(
            text=text,
            user_history=user_history,
            top_k=None,
        )

        self.assertGreaterEqual(len(results), 2)

    def test_threshold_filters_out_low_relevance_words_when_returning_all(self):
        extractor = VocabularyExtractor(spacy_model="en_core_web_sm")
        text = (
            "Artificial intelligence relies heavily on complex algorithms to process data. "
            "Apples are common fruit and easy to recognize."
        )
        user_history = {"learned_words": {}}

        results = extractor.process_text(
            text=text,
            user_history=user_history,
            top_k=None,
            score_threshold=0.5,
        )

        self.assertTrue(all(item["questlex_score"] >= 0.5 for item in results))

    def test_level_selection_filters_words_by_proficiency_target(self):
        extractor = VocabularyExtractor(spacy_model="en_core_web_sm")
        text = (
            "Artificial intelligence relies heavily on complex algorithms to process data. "
            "Apples are common fruit and easy to recognize."
        )
        user_history = {"learned_words": {}}

        results = extractor.process_text(
            text=text,
            user_history=user_history,
            top_k=None,
            level="C1",
        )

        self.assertTrue(all(item["breakdown"]["cefr"] >= 0.8 for item in results))

    def test_dictionary_info_uses_context_to_select_the_right_meaning(self):
        extractor = VocabularyExtractor(spacy_model="en_core_web_sm")
        info = extractor._fetch_dictionary_info(
            "cultivate",
            context="learners must cultivate strong mental discipline",
            pos="VERB"
        )

        self.assertTrue(
            any(term in info["definition"].lower() for term in ["growth", "develop", "foster"])
        )

    def test_extract_candidates_preserve_vocabulary_as_noun(self):
        extractor = VocabularyExtractor(spacy_model="en_core_web_sm")
        candidates = extractor.extract_candidates(
            "This vocabulary is useful in the example sentence."
        )

        vocabulary = next(item for item in candidates if item["lemma"] == "vocabulary")
        self.assertEqual(vocabulary["pos"], "NOUN")

    def test_history_words_are_not_returned_again(self):
        extractor = VocabularyExtractor(spacy_model="en_core_web_sm")
        text = "Artificial intelligence relies heavily on complex algorithms to process data."
        user_history = {
            "learned_words": {
                "algorithm": {"mastery": 0.8}
            }
        }

        results = extractor.process_text(
            text=text,
            user_history=user_history,
            top_k=None,
        )

        returned_words = {item["word"] for item in results}
        self.assertNotIn("algorithm", returned_words)

    def test_get_all_user_history_returns_saved_words(self):
        db_path = os.path.join(tempfile.gettempdir(), "test_user_history.db")
        if os.path.exists(db_path):
            os.remove(db_path)

        db = RevisionEngine(db_path)
        db.add_word_to_study(
            user_id="user_dev_01",
            word="vocabulary",
            pos="NOUN",
            definition="a set of words",
            synonyms=["lexicon"],
            context_example="This vocabulary is useful."
        )

        history = db.get_all_user_history("user_dev_01")
        self.assertEqual(len(history), 1)
        self.assertEqual(history[0]["word"], "vocabulary")

    def test_user_level_selection_is_persisted_between_runs(self):
        db_path = os.path.join(tempfile.gettempdir(), "test_user_level.db")
        if os.path.exists(db_path):
            os.remove(db_path)

        db = RevisionEngine(db_path)
        self.assertIsNone(db.get_user_level("user_dev_01"))

        db.save_user_level("user_dev_01", "B2")

        db_again = RevisionEngine(db_path)
        self.assertEqual(db_again.get_user_level("user_dev_01"), "B2")

    def test_ocr_extracts_text_from_multi_region_layout(self):
        image_path = os.path.join(tempfile.gettempdir(), "complex_layout_ocr_test.png")
        img = Image.new("RGB", (1400, 900), color=(255, 255, 255))
        draw = ImageDraw.Draw(img)
        font = ImageFont.load_default()

        draw.text((40, 40), "Aspirations for academic success depend on discipline and strategy", fill=(0, 0, 0), font=font)
        draw.text((700, 80), "Complex layouts may place text anywhere on the page", fill=(0, 0, 0), font=font)
        draw.text((90, 450), "Vocabulary learning becomes easier with consistent review", fill=(0, 0, 0), font=font)
        draw.text((750, 520), "This synthetic example tests OCR over multiple regions", fill=(0, 0, 0), font=font)
        img.save(image_path)

        extractor = OCRExtractor(languages=['en'], gpu=False)
        text, confidence = extractor.extract_text_from_image(image_path, use_preprocessing=True)

        self.assertGreater(len(text), 0)
        self.assertGreaterEqual(confidence, 0.0)
        self.assertTrue(any(keyword in text.lower() for keyword in ["complex", "vocabulary", "discipline", "aspirations"]))

    def test_dictionary_example_is_used_when_context_is_unclear(self):
        extractor = VocabularyExtractor(spacy_model="en_core_web_sm")
        example = extractor.build_example_sentence(
            word="cultivate",
            context="bad ocr noise xzq aa",
            pos="VERB"
        )

        self.assertIn("cultivate", example.lower())
        self.assertTrue(len(example) > 0)


if __name__ == "__main__":
    unittest.main()
