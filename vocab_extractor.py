import math
import urllib.request
import json
import re
import threading
from collections import Counter
from typing import List, Dict, Any
from nltk_example_extractor import NLTKExampleExtractor

DEFAULT_WEIGHTS = {
    "keybert": 0.25,
    "cefr": 0.35,
    "frequency": 0.15,
    "specificity": 0.15,
    "context": 0.10,
    "user": 0.10,
}

class VocabularyExtractor:
    def __init__(self, spacy_model: str = "en_core_web_sm"):
        print("🚀 Khởi động app thành công ngay lập tức! Đang nạp mô hình AI ngầm...")
        
        self.is_ready = False
        self.spacy_model_name = spacy_model
        self.nlp = None
        self.kw_model = None
        self.dict_engine = None
        self.nltk_example_engine = None
        self._dictionary_cache: Dict[str, Dict[str, Any]] = {}

        self.cefr_db = {
            "apple": "A1", "read": "A1", "important": "B1",
            "algorithm": "C1", "resilient": "C2", "ubiquitous": "C2"
        }
        self.freq_db = {
            "apple": 10000, "important": 5000, "algorithm": 800, "resilient": 200
        }

        threading.Thread(target=self._background_init, daemon=True).start()

    def _background_init(self):
        try:
            import spacy
            import torch
            from keybert import KeyBERT
            import nltk
            from nltk.corpus import wordnet
            from offline_dictionary import LargeOfflineDictionary

            nltk.data.path.append("./nltk_data")

            self.nlp = spacy.load(self.spacy_model_name)
            self.dict_engine = LargeOfflineDictionary()
            self.nltk_example_engine = NLTKExampleExtractor(min_words=6, max_words=16)
            self.kw_model = KeyBERT(model="./models/all-MiniLM-L6-v2")

            self.is_ready = True
        except Exception as e:
            print(f"❌ Lỗi trong quá trình khởi tạo ngầm: {e}")

    def _wait_for_ready(self):
        if not self.is_ready:
            while not self.is_ready:
                import time
                time.sleep(0.1)

    def _merge_weights(self, weights: Dict[str, float] | None) -> Dict[str, float]:
        merged = dict(DEFAULT_WEIGHTS)
        if weights:
            for key, value in weights.items():
                if key in merged:
                    merged[key] = float(value)
        return merged

    @staticmethod
    def _normalize_score(value: float, low: float = 0.0, high: float = 1.0) -> float:
        if high <= low:
            return 0.0
        normalized = (value - low) / (high - low)
        return max(0.0, min(1.0, normalized))

    def _looks_like_noisy_context(self, context: str) -> bool:
        cleaned_context = context.strip()
        if not cleaned_context:
            return True

        doc = self.nlp(cleaned_context)
        content_tokens = [
            token.lemma_.lower()
            for token in doc
            if token.is_alpha and not token.is_stop and token.pos_ in {"NOUN", "VERB", "ADJ", "ADV", "PROPN"}
        ]

        if len(content_tokens) < 2:
            return True

        short_word_blacklist = {"aa", "bb", "cc", "dd", "ee", "ff", "gg", "hh", "ii", "jj", "kk", "ll", "mm", "nn", "oo", "pp", "qq", "rr", "ss", "tt", "uu", "vv", "ww", "xx", "yy", "zz", "xzq"}
        for token in doc:
            if token.is_alpha and len(token.text) <= 2 and token.text.lower() not in {"to", "in", "on", "of", "or", "an", "at", "be", "is", "it"}:
                if token.text.lower() in short_word_blacklist:
                    return True

        return False

    def _looks_like_unrelated_context(self, word: str, context: str, pos: str = "") -> bool:
        cleaned_context = context.strip()
        if not cleaned_context or self._looks_like_noisy_context(cleaned_context):
            return True

        normalized_word = word.lower()
        context_words = {token.lemma_.lower() for token in self.nlp(cleaned_context) if token.is_alpha and not token.is_stop}
        if not context_words:
            return True

        if normalized_word in context_words:
            return False

        dictionary_info = self._fetch_dictionary_info(normalized_word, context=cleaned_context, pos=pos)
        definition = (dictionary_info.get("definition") or "").lower()
        if not definition:
            return True

        definition_terms = {
            term for term in re.findall(r"[a-z']+", definition) if len(term) > 2 and term not in {"with", "from", "into", "this", "that"}
        }
        if not definition_terms:
            return True

        overlap = len(context_words & definition_terms)
        return overlap < 1

    def build_example_sentence(self, word: str, context: str = "", pos: str = "") -> str:
        normalized_word = word.lower()
        example = self.nltk_example_engine.get_example_sentence(normalized_word, fallback="")
        if example:
            return example
            
        cleaned_context = context.strip()
        if cleaned_context and not self._looks_like_noisy_context(cleaned_context):
            words = cleaned_context.split()
            if 5 <= len(words) <= 15 and not self._looks_like_unrelated_context(normalized_word, cleaned_context, pos=pos):
                return cleaned_context

        return ""

    def _fetch_dictionary_info(self, word: str, context: str = "", pos: str = "") -> Dict[str, Any]:
        normalized_word = word.lower()
        cache_key = f"{normalized_word}|{pos}|{context.lower()}"
        if cache_key in self._dictionary_cache:
            return self._dictionary_cache[cache_key]

        info = {"definition": "", "synonyms": []}
        context_words = set(context.lower().split())

        if self.dict_engine and hasattr(self.dict_engine, "lookup"):
            try:
                offline_result = self.dict_engine.lookup(normalized_word)
                if offline_result:
                    if isinstance(offline_result, dict):
                        info["definition"] = offline_result.get("definition", "")
                        info["synonyms"] = offline_result.get("synonyms", [])[:4]
                    elif isinstance(offline_result, str):
                        info["definition"] = offline_result
            except Exception:
                pass

        if not info["definition"]:
            try:
                import nltk
                from nltk.corpus import wordnet
                synsets = wordnet.synsets(normalized_word)
                if synsets:
                    preferred_synset = None
                    best_score = -1.0
                    pos_map = {
                        "NOUN": wordnet.NOUN,
                        "VERB": wordnet.VERB,
                        "ADJ": wordnet.ADJ,
                        "ADV": wordnet.ADV,
                        "PROPN": wordnet.NOUN,
                    }
                    target_pos = pos_map.get(pos.upper(), None)

                    for syn in synsets:
                        score = 0.0
                        if target_pos is not None and syn.pos() == target_pos:
                            score += 1.5

                        definition_words = set(syn.definition().lower().split())
                        overlap = len(context_words & definition_words)
                        score += overlap * 0.5

                        if score > best_score:
                            best_score = score
                            preferred_synset = syn

                    if preferred_synset is None:
                        preferred_synset = synsets[0]

                    info["definition"] = preferred_synset.definition()

                    synonyms_set = set()
                    for lemma in preferred_synset.lemmas():
                        syn_name = lemma.name().replace('_', ' ')
                        if syn_name.lower() != normalized_word:
                            synonyms_set.add(syn_name)

                    info["synonyms"] = list(synonyms_set)[:4]
            except Exception:
                pass

        if not info["definition"]:
            info["definition"] = f"A definition for '{normalized_word}' is currently unavailable."

        info["example_sentence"] = self.build_example_sentence(
            word=normalized_word,
            context=context,
            pos=pos
        )

        self._dictionary_cache[cache_key] = info
        return info

    def _normalize_token_pos(self, token: Any) -> str:
        tag = (token.tag_ or "").upper()
        pos = (token.pos_ or "").upper()

        if tag.startswith(("NN", "NNS", "NNP", "NNPS")):
            return "NOUN"
        if tag.startswith("VB"):
            return "VERB"
        if tag.startswith("JJ"):
            return "ADJ"
        if tag.startswith("RB"):
            return "ADV"

        if pos in {"NOUN", "VERB", "ADJ", "ADV", "PROPN"}:
            return pos

        return "NOUN"

    def _has_dictionary_meaning(self, word: str, pos: str = "") -> bool:
        normalized_word = word.lower()
        try:
            import nltk
            from nltk.corpus import wordnet
            synsets = wordnet.synsets(normalized_word)
            if synsets:
                pos_map = {
                    "NOUN": wordnet.NOUN,
                    "VERB": wordnet.VERB,
                    "ADJ": wordnet.ADJ,
                    "ADV": wordnet.ADV,
                    "PROPN": wordnet.NOUN,
                }
                target_pos = pos_map.get(pos.upper(), None)
                if target_pos is not None:
                    return any(syn.pos() == target_pos for syn in synsets)
                return True
            return False
        except Exception:
            pass
        return False

    def extract_candidates(self, text: str) -> List[Dict[str, str]]:
        doc = self.nlp(text)
        candidates = []
        seen_lemmas = set()
        target_pos = {"NOUN", "VERB", "ADJ", "ADV", "PROPN"}

        for token in doc:
            lemma = token.lemma_.lower()
            pos = self._normalize_token_pos(token)
            if (
                pos in target_pos
                and not token.is_stop
                and token.is_alpha
                and len(lemma) > 1
                and lemma not in seen_lemmas
                and self._has_dictionary_meaning(lemma, pos=pos)
            ):
                candidates.append({
                    "lemma": lemma,
                    "pos": pos,
                    "original_text": token.text,
                    "context_example": token.sent.text.strip()
                })
                seen_lemmas.add(lemma)

        return candidates

    def get_keybert_scores(self, text: str, candidates: List[Dict[str, str]]) -> Dict[str, float]:
        candidate_words = [c["lemma"] for c in candidates]
        if not candidate_words:
            return {}

        keywords = self.kw_model.extract_keywords(
            text, 
            candidates=candidate_words, 
            top_n=len(candidate_words)
        )
        kb_dict = {word: float(score) for word, score in keywords}
        
        for word in candidate_words:
            if word not in kb_dict:
                kb_dict[word] = 0.1

        return kb_dict

    def get_cefr_score(self, lemma: str) -> float:
        mapping = {"A1": 0.1, "A2": 0.3, "B1": 0.5, "B2": 0.7, "C1": 0.9, "C2": 1.0}
        level = self.cefr_db.get(lemma)
        if level is not None:
            return mapping.get(level, 0.7)
        length_bonus = min(max(len(lemma) - 4, 0) * 0.05, 0.25)
        return min(0.45 + length_bonus, 0.95)

    def get_frequency_score(self, lemma: str) -> float:
        freq = self.freq_db.get(lemma)
        if freq is None:
            length_bonus = min(max(len(lemma) - 4, 0) * 0.05, 0.25)
            return min(0.45 + length_bonus, 0.9)
        if freq <= 0:
            return 0.8
        commonness = min(math.log10(freq) / 5.0, 1.0)
        rarity = 1.0 - commonness
        length_bonus = min(max(len(lemma) - 4, 0) * 0.05, 0.25)
        return min(max(rarity + length_bonus, 0.0), 1.0)

    def get_lexical_specificity_score(self, lemma: str, text: str) -> float:
        doc = self.nlp(text)
        content_tokens = [
            token.lemma_.lower()
            for token in doc
            if token.is_alpha and not token.is_stop and token.pos_ in {"NOUN", "VERB", "ADJ", "ADV", "PROPN"}
        ]
        if not content_tokens:
            return 0.0

        token_count = Counter(content_tokens)
        frequency = token_count.get(lemma, 0)
        rarity = 1.0 - min(frequency / max(len(content_tokens), 1), 1.0)
        length_bonus = min(max(len(lemma) - 4, 0) * 0.03, 0.15)
        chunk_bonus = 0.0
        for chunk in doc.noun_chunks:
            if lemma == chunk.root.lemma_.lower():
                chunk_bonus = 0.1
                break

        return min(max(rarity + length_bonus + chunk_bonus, 0.0), 1.0)

    def get_context_focus_score(self, lemma: str, text: str) -> float:
        doc = self.nlp(text)
        candidate_sentences = [
            sent for sent in doc.sents
            if lemma in {token.lemma_.lower() for token in sent if token.is_alpha and not token.is_stop}
        ]
        if not candidate_sentences:
            return 0.0

        sentence_bonus = min(len(candidate_sentences) * 0.15, 0.35)
        content_overlap = sum(
            1 for token in doc
            if token.lemma_.lower() == lemma and token.pos_ in {"NOUN", "VERB", "ADJ", "ADV", "PROPN"}
        )
        return min(sentence_bonus + min(content_overlap * 0.05, 0.15), 1.0)

    def get_user_score(self, lemma: str, user_history: Dict[str, Any]) -> float:
        user_words = user_history.get("learned_words", {})
        if lemma in user_words:
            mastery_level = user_words[lemma].get("mastery", 0)
            return 1.0 - mastery_level
        return 1.0

    def get_pos_bonus(self, pos: str, lemma: str) -> float:
        pos_bonus = {
            "NOUN": 0.15, "PROPN": 0.12, "VERB": 0.05, "ADJ": 0.05, "ADV": 0.02,
        }
        length_bonus = min(max(len(lemma) - 4, 0) * 0.02, 0.10)
        return pos_bonus.get(pos, 0.0) + length_bonus

    def process_text(
        self,
        text: str,
        user_history: Dict[str, Any],
        top_k: int | None = 5,
        weights: Dict[str, float] = None,
        score_threshold: float | None = None,
        level: str | None = None
    ) -> List[Dict[str, Any]]:
        self._wait_for_ready()

        weights = self._merge_weights(weights)
        candidates = self.extract_candidates(text)
        kb_scores = self.get_keybert_scores(text, candidates)

        results = []
        learned_words = user_history.get("learned_words", {})
        for cand in candidates:
            lemma = cand["lemma"]
            if lemma in learned_words:
                continue

            s_kb = self._normalize_score(kb_scores.get(lemma, 0.0), low=0.0, high=1.0)
            s_cefr = self.get_cefr_score(lemma)
            s_freq = self.get_frequency_score(lemma)
            s_specificity = self.get_lexical_specificity_score(lemma, text)
            s_context = self.get_context_focus_score(lemma, text)
            s_user = self.get_user_score(lemma, user_history)
            s_pos = self.get_pos_bonus(cand["pos"], lemma)

            questlex_score = (
                weights["keybert"] * s_kb +
                weights["cefr"] * s_cefr +
                weights["frequency"] * s_freq +
                weights["specificity"] * s_specificity +
                weights["context"] * s_context +
                weights["user"] * s_user +
                s_pos
            )

            results.append({
                "word": lemma,
                "pos": cand["pos"],
                "context_example": cand["context_example"],
                "questlex_score": round(questlex_score, 4),
                "breakdown": {
                    "keybert": round(s_kb, 3),
                    "cefr": round(s_cefr, 3),
                    "frequency": round(s_freq, 3),
                    "specificity": round(s_specificity, 3),
                    "context_focus": round(s_context, 3),
                    "user_priority": round(s_user, 3),
                    "pos_bonus": round(s_pos, 3)
                }
            })

        results.sort(key=lambda x: x["questlex_score"], reverse=True)

        if score_threshold is not None:
            results = [item for item in results if item["questlex_score"] >= score_threshold]

        if level is not None:
            level_thresholds = {
                "A1": 0.10, "A2": 0.30, "B1": 0.50, "B2": 0.70, "C1": 0.90, "C2": 1.00,
            }
            min_cefr = level_thresholds.get(level.upper(), 0.50)
            results = [item for item in results if item["breakdown"]["cefr"] >= min_cefr]

        top_results = results if (top_k is None or top_k >= len(results)) else results[:top_k]

        for item in top_results:
            dict_info = self._fetch_dictionary_info(
                item["word"],
                context=item["context_example"],
                pos=item["pos"]
            )
            item["definition"] = dict_info["definition"]
            item["synonyms"] = dict_info["synonyms"]
            item["context_example"] = dict_info["example_sentence"]

        return top_results