import os
import re
import threading
from collections import Counter
from pathlib import Path
from typing import List, Dict, Any
from functools import lru_cache
from concurrent.futures import ThreadPoolExecutor

from nltk_example_extractor import NLTKExampleExtractor

PROJECT_DIR = Path(__file__).resolve().parent
MODELS_DIR = PROJECT_DIR / "models"
NLTK_DATA_DIR = MODELS_DIR / "nltk_data"
KEYBERT_MODEL_DIR = MODELS_DIR / "keybert" / "all-MiniLM-L6-v2"
CEFR_TSV_PATH = MODELS_DIR / "wordlists" / "cefr.tsv"

DEFAULT_WEIGHTS = {
    "keybert": 0.25,
    "cefr": 0.30,
    "frequency": 0.15,
    "specificity": 0.15,
    "context": 0.10,
    "user": 0.10,
    "pos": 0.07,
}

CEFR_LEVEL_SCORE = {"A1": 0.1, "A2": 0.3, "B1": 0.5, "B2": 0.7, "C1": 0.9, "C2": 1.0}

# Curated exceptions for domain words the generic wordlists miss.
DOMAIN_CEFR = {
    "jedi": "C1", "sith": "C1", "lightsaber": "C2", "droid": "B2",
    "holocron": "C2", "blaster": "B2", "saber": "C1", "republic": "B2",
}

# POS-tag patterns for multi-word candidates (noun phrases).
PHRASE_PATTERNS = [
    [{"POS": "ADJ"}, {"POS": "NOUN"}],
    [{"POS": "NOUN"}, {"POS": "NOUN"}],
    [{"POS": "NOUN"}, {"POS": "ADP"}, {"POS": "NOUN"}],
]

MAX_DOC_CHARS = 100_000

# WordNet root hypernyms & categories to ignore (non-learning words)
EXCLUDED_LEXNAMES = {"noun.quantity", "noun.location", "noun.time"}
EXCLUDED_HYPERNYMS = {
    "unit_of_measurement.n.01",
    "linear_unit.n.01",
    "area_unit.n.01",
    "volume_unit.n.01",
    "mass_unit.n.01",
    "historical_event.n.01",
    "chronological_record.n.01",
}


def ensure_model_paths():
    MODELS_DIR.mkdir(exist_ok=True)
    NLTK_DATA_DIR.mkdir(exist_ok=True)
    KEYBERT_MODEL_DIR.parent.mkdir(exist_ok=True)
    os.environ.setdefault("HF_HOME", str(MODELS_DIR))
    os.environ.setdefault("TRANSFORMERS_OFFLINE", "1")
    os.environ.setdefault("HF_DATASETS_OFFLINE", "1")


def _load_cefr_map() -> Dict[str, str]:
    """Load an optional local CEFR word list (word<TAB>level per line)."""
    cefr_map = {}
    try:
        if CEFR_TSV_PATH.exists():
            with CEFR_TSV_PATH.open("r", encoding="utf-8") as handle:
                for line in handle:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    parts = line.split("\t")
                    if len(parts) >= 2:
                        word = parts[0].strip().lower()
                        level = parts[1].strip().upper()
                        if level in CEFR_LEVEL_SCORE:
                            cefr_map[word] = level
    except Exception:
        pass
    return cefr_map


def _load_wordfreq():
    """Load the wordfreq zipf scorer if installed (bundled offline data)."""
    try:
        from wordfreq import zipf_frequency
        return zipf_frequency
    except Exception:
        return None


class VocabularyExtractor:
    def __init__(self, spacy_model: str = "en_core_web_sm", max_workers: int = None):

        self.is_ready = False
        self._ready_event = threading.Event()
        self.spacy_model_name = spacy_model
        self.max_workers = max_workers
        self.nlp = None
        self.matcher = None
        self.kw_model = None
        self.embedding_model = None
        self.dict_engine = None
        self.nltk_example_engine = None
        self._dictionary_cache: Dict[str, Dict[str, Any]] = {}
        self._doc_cache: Dict[str, "object"] = {}
        self.cefr_map = _load_cefr_map()
        self.wordfreq = _load_wordfreq()

        threading.Thread(target=self._background_init, daemon=True).start()

    def _background_init(self):
        try:
            import spacy
            from keybert import KeyBERT
            from sentence_transformers import SentenceTransformer
            from spacy.matcher import Matcher
            import nltk
            import torch
            from offline_dictionary import LargeOfflineDictionary

            ensure_model_paths()
            if str(NLTK_DATA_DIR) not in nltk.data.path:
                nltk.data.path.append(str(NLTK_DATA_DIR))

            # Explicit Hardware Acceleration Detection
            device = "cuda" if torch.cuda.is_available() else "mps" if torch.backends.mps.is_available() else "cpu"
            if device != "cpu":
                spacy.prefer_gpu()

            self.nlp = spacy.load(
                self.spacy_model_name,
                disable=["parser", "ner"],
            )
            if not self.nlp.has_pipe("sentencizer"):
                try:
                    self.nlp.add_pipe("sentencizer")
                except Exception:
                    pass

            self.matcher = Matcher(self.nlp.vocab)
            self.matcher.add("NOUN_PHRASES", PHRASE_PATTERNS)

            self.dict_engine = LargeOfflineDictionary()
            self.nltk_example_engine = NLTKExampleExtractor(min_words=6, max_words=16)

            # Load shared SentenceTransformer locally for KeyBERT and Embedding WSD
            self.embedding_model = SentenceTransformer(str(KEYBERT_MODEL_DIR), device=device)
            self.kw_model = KeyBERT(model=self.embedding_model)

            self.is_ready = True
        except Exception as e:
            print(f"❌ Lỗi trong quá trình khởi tạo ngầm: {e}")
        finally:
            self._ready_event.set()

    def _wait_for_ready(self):
        self._ready_event.wait()

    def _get_doc(self, text: str):
        cache_key = text
        doc = self._doc_cache.get(cache_key)
        if doc is None:
            if len(self._doc_cache) > 64:
                self._doc_cache.clear()
            doc = self.nlp(text[:MAX_DOC_CHARS])
            self._doc_cache[cache_key] = doc
        return doc

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

    # ------------------------------------------------------------------
    # Offline lexical data & Non-Learning Word Filter
    # ------------------------------------------------------------------
    @staticmethod
    @lru_cache(maxsize=32768)
    def _wordnet_synsets(word: str):
        try:
            from nltk.corpus import wordnet
            return wordnet.synsets(word)
        except Exception:
            return []

    @classmethod
    @lru_cache(maxsize=16384)
    def _is_non_learning_word(cls, word: str) -> bool:
        if word.lower() in DOMAIN_CEFR:
            return False

        synsets = cls._wordnet_synsets(word)
        if not synsets:
            return False

        all_excluded = True
        for syn in synsets:
            # 1. Check Lexicographer Category
            if syn.lexname() in EXCLUDED_LEXNAMES:
                continue

            # 2. Check Hypernym Tree for Measurement Units or Historical Events
            hypernym_names = set()
            for path in syn.hypernym_paths():
                hypernym_names.update(h.name() for h in path)

            if hypernym_names & EXCLUDED_HYPERNYMS:
                continue

            all_excluded = False
            break

        return all_excluded

    @staticmethod
    def _context_window(context: str, word: str, radius: int = 5) -> str:
        tokens = re.findall(r"[a-z']+", context.lower())
        words = word.lower().replace("_", " ").split()
        if not tokens or not words:
            return context
        for i in range(len(tokens) - len(words) + 1):
            if tokens[i:i + len(words)] == words:
                start = max(0, i - radius)
                end = min(len(tokens), i + len(words) + radius)
                return " ".join(tokens[start:end])
        return context

    # ------------------------------------------------------------------
    # Context quality checks
    # ------------------------------------------------------------------
    def _looks_like_noisy_context(self, context: str) -> bool:
        cleaned_context = context.strip()
        if not cleaned_context:
            return True

        doc = self._get_doc(cleaned_context)
        content_tokens = [
            token.lemma_.lower()
            for token in doc
            if token.is_alpha and not token.is_stop and token.pos_ in {"NOUN", "VERB", "ADJ", "ADV"}
        ]

        if len(content_tokens) < 2:
            return True

        short_word_blacklist = {
            "aa", "bb", "cc", "dd", "ee", "ff", "gg", "hh", "ii", "jj", "kk",
            "ll", "mm", "nn", "oo", "pp", "qq", "rr", "ss", "tt", "uu", "vv",
            "ww", "xx", "yy", "zz", "xzq",
        }
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
        context_words = {
            token.lemma_.lower()
            for token in self._get_doc(cleaned_context)
            if token.is_alpha and not token.is_stop
        }
        if not context_words:
            return True

        word_forms = {
            normalized_word,
            normalized_word.rstrip("s"),
            normalized_word.rstrip("es"),
        }
        if word_forms & context_words:
            return False

        dictionary_info = self._fetch_dictionary_info(normalized_word, context=cleaned_context, pos=pos)
        definition = (dictionary_info.get("definition") or "").lower()
        if not definition:
            return True

        definition_terms = {
            term for term in re.findall(r"[a-z']+", definition)
            if len(term) > 2 and term not in {"with", "from", "into", "this", "that"}
        }
        if not definition_terms:
            return True

        overlap = len(context_words & definition_terms)
        return overlap < 1

    # ------------------------------------------------------------------
    # Advanced Embedding-Based WSD & Dictionary Fetching
    # ------------------------------------------------------------------
    def build_example_sentence(self, word: str, context: str = "", pos: str = "") -> str:
        normalized_word = word.lower()
        cleaned_context = context.strip()
        if cleaned_context and not self._looks_like_noisy_context(cleaned_context):
            words = cleaned_context.split()
            if 5 <= len(words) <= 25:
                if not self._looks_like_unrelated_context(normalized_word, cleaned_context, pos=pos):
                    return cleaned_context

        return self.nltk_example_engine.get_example_sentence(normalized_word, fallback="")

    def _fetch_dictionary_info(self, word: str, context: str = "", pos: str = "") -> Dict[str, Any]:
        normalized_word = word.lower()
        cache_key = f"{normalized_word}|{pos}|{context.lower()}"

        cached = self._dictionary_cache.get(cache_key)
        if cached is not None:
            return cached

        info: Dict[str, Any] = {"definition": "", "synonyms": []}
        self._dictionary_cache[cache_key] = info

        # Lookup in local custom dictionary first
        if self.dict_engine and hasattr(self.dict_engine, "lookup"):
            try:
                offline_result = self.dict_engine.lookup(normalized_word)
                if offline_result:
                    if isinstance(offline_result, dict) and offline_result.get("definition"):
                        info["definition"] = offline_result["definition"]
                        info["synonyms"] = offline_result.get("synonyms", [])[:4]
                    elif isinstance(offline_result, str):
                        info["definition"] = offline_result
            except Exception:
                pass

        # Advanced Embedding WSD via SentenceTransformers & WordNet
        if not info["definition"]:
            try:
                import torch
                from sentence_transformers import util
                from nltk.corpus import wordnet

                pos_map = {
                    "NOUN": wordnet.NOUN,
                    "VERB": wordnet.VERB,
                    "ADJ": wordnet.ADJ,
                    "ADV": wordnet.ADV,
                }
                target_pos = pos_map.get(pos.upper(), None)
                synsets = self._wordnet_synsets(normalized_word)

                if target_pos:
                    filtered_synsets = [s for s in synsets if s.pos() == target_pos]
                    if filtered_synsets:
                        synsets = filtered_synsets

                if synsets:
                    preferred_synset = synsets[0]

                    # Perform Vector Space Semantic WSD using SentenceTransformers
                    if self.embedding_model and len(synsets) > 1 and context:
                        sense_profiles = [
                            f"{syn.definition()} Example: {' '.join(syn.examples())}".strip()
                            for syn in synsets
                        ]
                        
                        ctx_emb = self.embedding_model.encode(context, convert_to_tensor=True)
                        sense_embs = self.embedding_model.encode(sense_profiles, convert_to_tensor=True)

                        cosine_scores = util.cos_sim(ctx_emb, sense_embs)[0]
                        best_idx = int(torch.argmax(cosine_scores).item())
                        preferred_synset = synsets[best_idx]

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
            pos=pos,
        )
        return info

    def _normalize_token_pos(self, token: Any) -> str:
        tag = (token.tag_ or "").upper()
        pos = (token.pos_ or "").upper()

        if tag.startswith(("NN", "NNS")):
            return "NOUN"
        if tag.startswith("VB"):
            return "VERB"
        if tag.startswith("JJ"):
            return "ADJ"
        if tag.startswith("RB"):
            return "ADV"

        if pos in {"NOUN", "VERB", "ADJ", "ADV"}:
            return pos

        return "NOUN"

    def _has_dictionary_meaning(self, word: str, pos: str = "") -> bool:
        normalized_word = word.lower()
        synsets = self._wordnet_synsets(normalized_word)
        if not synsets:
            return False

        pos_map = {"NOUN": "n", "VERB": "v", "ADJ": "a", "ADV": "r"}
        target_tag = pos_map.get(pos.upper(), None)
        if target_tag is None:
            return True
        return any(syn.pos() == target_tag for syn in synsets)

    # ------------------------------------------------------------------
    # Candidate extraction (excluding non-learning terms)
    # ------------------------------------------------------------------
    def extract_candidates(self, text: str, doc=None) -> List[Dict[str, str]]:
        doc = doc if doc is not None else self._get_doc(text)
        candidates = []
        seen_lemmas = set()
        target_pos = {"NOUN", "VERB", "ADJ", "ADV"}

        def passes_candidate_filters(lemma: str, pos: str) -> bool:
            if self._is_non_learning_word(lemma):
                return False
            return self._has_dictionary_meaning(lemma, pos=pos)

        for token in doc:
            lemma = token.lemma_.lower()
            pos = self._normalize_token_pos(token)

            # Strict filtering: Exclude PROPN (Proper Nouns) and Non-Learning terms
            if (
                token.pos_ != "PROPN"
                and pos in target_pos
                and not token.is_stop
                and token.is_alpha
                and len(lemma) > 1
                and lemma not in seen_lemmas
                and passes_candidate_filters(lemma, pos)
            ):
                candidates.append({
                    "lemma": lemma,
                    "pos": pos,
                    "original_text": token.text,
                    "context_example": token.sent.text.strip(),
                    "is_phrase": False,
                })
                seen_lemmas.add(lemma)

        if self.matcher is not None:
            for _match_id, start, end in self.matcher(doc):
                span = doc[start:end]
                if not (2 <= len(span) <= 3):
                    continue
                if not all(t.is_alpha and t.pos_ != "PROPN" for t in span):
                    continue
                if any(t.is_stop for t in span):
                    continue

                phrase = "_".join(t.lemma_.lower() for t in span)
                if phrase in seen_lemmas or self._is_non_learning_word(phrase):
                    continue
                if not self._has_dictionary_meaning(phrase, pos="NOUN"):
                    continue

                candidates.append({
                    "lemma": phrase,
                    "pos": "NOUN",
                    "original_text": span.text,
                    "context_example": span.sent.text.strip(),
                    "is_phrase": True,
                })
                seen_lemmas.add(phrase)

        return candidates

    # ------------------------------------------------------------------
    # Scoring
    # ------------------------------------------------------------------
    def get_keybert_scores(self, text: str, candidates: List[Dict[str, str]]) -> Dict[str, float]:
        candidate_words = [c["lemma"] for c in candidates]
        if not candidate_words:
            return {}

        kb_input = [w.replace("_", " ") for w in candidate_words]
        keywords = self.kw_model.extract_keywords(
            text,
            candidates=kb_input,
            top_n=len(kb_input),
        )
        kb_dict = {}
        for word, score in keywords:
            kb_dict[word.replace(" ", "_")] = float(score)

        for word in candidate_words:
            if word not in kb_dict:
                kb_dict[word] = 0.1

        return kb_dict

    def get_cefr_level(self, lemma: str) -> str:
        score = self.get_cefr_score(lemma)
        if score < 0.18: return "A1"
        if score < 0.36: return "A2"
        if score < 0.58: return "B1"
        if score < 0.78: return "B2"
        if score < 0.9:  return "C1"
        return "C2"

    def get_cefr_score(self, lemma: str) -> float:
        level = self.cefr_map.get(lemma) or DOMAIN_CEFR.get(lemma)
        if level is not None:
            return CEFR_LEVEL_SCORE.get(level, 0.7)

        if self.wordfreq is not None:
            zipf = self.wordfreq(lemma.replace("_", " ").lower(), "en")
            return max(0.1, min(0.95, (7.5 - zipf) / 6.5))

        length = len(lemma)
        if length <= 4: score = 0.12
        elif length <= 6: score = 0.24
        elif length <= 8: score = 0.40
        elif length <= 10: score = 0.58
        else: score = 0.74

        if any(lemma.endswith(suffix) for suffix in ("tion", "ment", "ness", "ity", "ology", "ous", "able")):
            score += 0.08
        if length >= 10: score += 0.08
        if length >= 12: score += 0.06

        return min(max(score, 0.1), 0.95)

    def get_frequency_score(self, lemma: str) -> float:
        if self.wordfreq is not None:
            zipf = self.wordfreq(lemma.replace("_", " ").lower(), "en")
            rarity = max(0.0, min(1.0, (7.5 - zipf) / 6.5))
            length_bonus = min(max(len(lemma) - 4, 0) * 0.05, 0.25)
            return min(rarity + length_bonus, 1.0)

        length_bonus = min(max(len(lemma) - 4, 0) * 0.05, 0.25)
        return min(0.45 + length_bonus, 0.9)

    def get_lexical_specificity_score(self, lemma: str, text: str, doc=None) -> float:
        doc = doc if doc is not None else self._get_doc(text)
        content_tokens = [
            token.lemma_.lower()
            for token in doc
            if token.is_alpha and not token.is_stop and token.pos_ in {"NOUN", "VERB", "ADJ", "ADV"}
        ]
        if not content_tokens:
            return 0.0

        token_count = Counter(content_tokens)
        frequency = token_count.get(lemma, 0)
        rarity = 1.0 - min(frequency / max(len(content_tokens), 1), 1.0)
        length_bonus = min(max(len(lemma) - 4, 0) * 0.03, 0.15)
        return min(max(rarity + length_bonus, 0.0), 1.0)

    def get_context_focus_score(self, lemma: str, text: str, doc=None) -> float:
        doc = doc if doc is not None else self._get_doc(text)
        lemma_lower = lemma.lower()
        phrase_words = set(lemma_lower.split("_"))

        def sentence_matches(sent) -> bool:
            sent_lemmas = {
                token.lemma_.lower()
                for token in sent
                if token.is_alpha and not token.is_stop
            }
            return phrase_words <= sent_lemmas

        candidate_sentences = [sent for sent in doc.sents if sentence_matches(sent)]
        if not candidate_sentences:
            return 0.0

        sentence_bonus = min(len(candidate_sentences) * 0.15, 0.35)
        content_overlap = sum(
            1 for sent in candidate_sentences for token in sent
            if token.is_alpha
            and not token.is_stop
            and token.lemma_.lower() in phrase_words
            and token.pos_ in {"NOUN", "VERB", "ADJ", "ADV"}
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
            "NOUN": 0.15, "VERB": 0.05, "ADJ": 0.05, "ADV": 0.02,
        }
        length_bonus = min(max(len(lemma) - 4, 0) * 0.02, 0.10)
        return pos_bonus.get(pos, 0.0) + length_bonus

    @staticmethod
    def _cefr_rank(level: str) -> int:
        rank_map = {"A1": 0, "A2": 1, "B1": 2, "B2": 3, "C1": 4, "C2": 5}
        return rank_map.get((level or "B2").upper(), 3)

    # ------------------------------------------------------------------
    # Main pipeline
    # ------------------------------------------------------------------
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
        doc = self._get_doc(text)
        candidates = self.extract_candidates(text, doc=doc)
        kb_scores = self.get_keybert_scores(text, candidates)

        learned_words = user_history.get("learned_words", {})

        def _score_candidate(cand):
            lemma = cand["lemma"]
            if lemma in learned_words:
                return None

            s_kb = self._normalize_score(kb_scores.get(lemma, 0.0), low=0.0, high=1.0)
            s_cefr = self.get_cefr_score(lemma)
            s_freq = self.get_frequency_score(lemma)
            s_specificity = self.get_lexical_specificity_score(lemma, text, doc=doc)
            s_context = self.get_context_focus_score(lemma, text, doc=doc)
            s_user = self.get_user_score(lemma, user_history)
            s_pos = self.get_pos_bonus(cand["pos"], lemma)

            questlex_score = (
                weights["keybert"] * s_kb +
                weights["cefr"] * s_cefr +
                weights["frequency"] * s_freq +
                weights["specificity"] * s_specificity +
                weights["context"] * s_context +
                weights["user"] * s_user +
                weights["pos"] * s_pos
            )

            return {
                "word": lemma,
                "pos": cand["pos"],
                "context_example": cand["context_example"],
                "level": self.get_cefr_level(lemma),
                "mastery_score": 0.0,
                "questlex_score": round(questlex_score, 4),
                "breakdown": {
                    "keybert": round(s_kb, 3),
                    "cefr": round(s_cefr, 3),
                    "frequency": round(s_freq, 3),
                    "specificity": round(s_specificity, 3),
                    "context_focus": round(s_context, 3),
                    "user_priority": round(s_user, 3),
                    "pos_bonus": round(s_pos, 3),
                },
            }

        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            raw_results = list(executor.map(_score_candidate, candidates))
        
        results = [res for res in raw_results if res is not None]

        results.sort(key=lambda x: x["questlex_score"], reverse=True)

        if score_threshold is not None:
            results = [item for item in results if item["questlex_score"] >= score_threshold]

        if level is not None:
            level_thresholds = {
                "A1": 0.10, "A2": 0.24, "B1": 0.42, "B2": 0.62, "C1": 0.80, "C2": 0.92,
            }
            min_cefr = level_thresholds.get(level.upper(), 0.40)
            results = [item for item in results if item["breakdown"]["cefr"] >= min_cefr]

        results.sort(
            key=lambda item: (
                self._cefr_rank(item.get("level", "B2")),
                -item.get("questlex_score", 0.0),
                -item.get("breakdown", {}).get("cefr", 0.0),
            )
        )

        top_results = results if (top_k is None or top_k >= len(results)) else results[:top_k]

        def _enrich_result(item):
            dict_info = self._fetch_dictionary_info(
                item["word"],
                context=item["context_example"],
                pos=item["pos"],
            )
            item["definition"] = dict_info["definition"]
            item["synonyms"] = dict_info["synonyms"]
            item["context_example"] = dict_info["example_sentence"]
            item.setdefault("level", self.get_cefr_level(item["word"]))
            item.setdefault("mastery_score", 0.0)
            return item

        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            top_results = list(executor.map(_enrich_result, top_results))

        return top_results