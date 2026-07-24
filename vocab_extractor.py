import math
import urllib.request
import json
from collections import Counter
from typing import List, Dict, Any
import spacy
import torch
from keybert import KeyBERT

DEFAULT_WEIGHTS = {
    "keybert": 0.25,
    "cefr": 0.35,
    "frequency": 0.15,
    "specificity": 0.15,
    "context": 0.10,
    "user": 0.10,
}

# Import NLTK WordNet cho bộ từ điển lớn
import nltk
try:
    nltk.data.find('corpora/wordnet')
except LookupError:
    nltk.download('wordnet', quiet=True)
    nltk.download('omw-1.4', quiet=True)

from nltk.corpus import wordnet

class VocabularyExtractor:
    def __init__(self, spacy_model: str = "en_core_web_sm"):
        print("Loading spaCy model...")
        self.nlp = spacy.load(spacy_model)
        self._dictionary_cache: Dict[str, Dict[str, Any]] = {}
        
        device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"Loading KeyBERT model on device: {device}...")
        self.kw_model = KeyBERT(model="all-MiniLM-L6-v2")

        # CSDL Mock điểm số bổ trợ
        self.cefr_db = {
            "apple": "A1", "read": "A1", "important": "B1",
            "algorithm": "C1", "resilient": "C2", "ubiquitous": "C2"
        }
        self.freq_db = {
            "apple": 10000, "important": 5000, "algorithm": 800, "resilient": 200
        }

    def _merge_weights(self, weights: Dict[str, float] | None) -> Dict[str, float]:
        """Merge caller weights with the default scoring configuration."""
        merged = dict(DEFAULT_WEIGHTS)
        if weights:
            for key, value in weights.items():
                if key in merged:
                    merged[key] = float(value)
        return merged

    @staticmethod
    def _normalize_score(value: float, low: float = 0.0, high: float = 1.0) -> float:
        """Normalize a score into the [0, 1] interval when possible."""
        if high <= low:
            return 0.0
        normalized = (value - low) / (high - low)
        return max(0.0, min(1.0, normalized))

    def _looks_like_noisy_context(self, context: str) -> bool:
        """Detect OCR fragments that are too broken to serve as a trustworthy example."""
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

    def build_example_sentence(self, word: str, context: str = "", pos: str = "") -> str:
        """Create a safe example sentence using the word itself when OCR context is unclear or noisy."""
        normalized_word = word.lower()
        cleaned_context = context.strip()

        if cleaned_context and not self._looks_like_noisy_context(cleaned_context):
            return cleaned_context

        templates = {
            "NOUN": [
                f"The {normalized_word} is an important concept in modern learning.",
                f"Students often discuss the {normalized_word} in class.",
                f"This example highlights the meaning of {normalized_word}."
            ],
            "VERB": [
                f"Learners should {normalized_word} new ideas carefully.",
                f"She tried to {normalized_word} her skills through practice.",
                f"We need to {normalized_word} strong habits for better progress."
            ],
            "ADJ": [
                f"This approach feels {normalized_word} and practical.",
                f"The result is a {normalized_word} solution for daily study.",
                f"A {normalized_word} method helps learners stay focused."
            ],
            "ADV": [
                f"The lesson was completed {normalized_word} and clearly.",
                f"She worked {normalized_word} to improve her results.",
                f"The task was handled {normalized_word} and efficiently."
            ]
        }

        patterns = templates.get(pos.upper(), templates["NOUN"])
        return patterns[0]

    def _fetch_dictionary_info(self, word: str, context: str = "", pos: str = "") -> Dict[str, Any]:
        """Tra cứu định nghĩa và từ đồng nghĩa theo ngữ cảnh câu và loại từ để tránh nghĩa sai."""
        normalized_word = word.lower()
        cache_key = f"{normalized_word}|{pos}|{context.lower()}"
        if cache_key in self._dictionary_cache:
            return self._dictionary_cache[cache_key]

        info = {"definition": "", "synonyms": []}
        context_words = set(context.lower().split())

        try:
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

                if not context:
                    info["synonyms"] = list(synonyms_set)[:4]
                else:
                    context_related = []
                    for synonym in synonyms_set:
                        if len(synonym.split()) > 3:
                            continue
                        if synonym.lower() in context.lower():
                            context_related.append(synonym)
                        else:
                            synonym_words = set(synonym.lower().split())
                            if len(context_words & synonym_words) > 0:
                                context_related.append(synonym)

                    if context_related:
                        info["synonyms"] = list(context_related)[:4]
                    else:
                        info["synonyms"] = list(synonyms_set)[:4]
        except Exception:
            pass

        if not info["definition"]:
            try:
                url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{normalized_word}"
                req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
                with urllib.request.urlopen(req, timeout=3) as response:
                    if response.status == 200:
                        data = json.loads(response.read().decode())[0]
                        meanings = data.get("meanings", [])
                        if meanings:
                            candidate_meanings = []
                            for meaning in meanings:
                                meaning_pos = meaning.get("partOfSpeech", "")
                                if pos and meaning_pos and meaning_pos.lower() != pos.lower():
                                    continue
                                candidate_meanings.append(meaning)

                            if not candidate_meanings:
                                candidate_meanings = meanings

                            chosen = candidate_meanings[0]
                            defs = chosen.get("definitions", [])
                            if defs:
                                info["definition"] = defs[0].get("definition", "")
                            synonyms = []
                            for meaning in candidate_meanings:
                                synonyms.extend(meaning.get("synonyms", []))
                            info["synonyms"] = list(set(synonyms))[:4]
            except Exception:
                info["definition"] = "Không tìm thấy định nghĩa chi tiết trong từ điển."

        if not info["definition"]:
            info["definition"] = f"A meaning of '{normalized_word}' is available in the dictionary."

        if not info["synonyms"]:
            info["synonyms"] = []

        info["example_sentence"] = self.build_example_sentence(
            word=normalized_word,
            context=context,
            pos=pos
        )

        self._dictionary_cache[cache_key] = info
        return info

    def _normalize_token_pos(self, token: Any) -> str:
        """Normalize spaCy POS output using both coarse and fine-grained tags."""
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
        """Check whether a candidate actually resolves to a meaningful dictionary entry."""
        normalized_word = word.lower()
        try:
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
        except Exception:
            pass

        try:
            url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{normalized_word}"
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=3) as response:
                return response.status == 200
        except Exception:
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
            # Unknown words without a corpus frequency should get a modest rarity bonus,
            # while very short common words remain low-priority.
            length_bonus = min(max(len(lemma) - 4, 0) * 0.05, 0.25)
            return min(0.45 + length_bonus, 0.9)

        if freq <= 0:
            return 0.8

        commonness = min(math.log10(freq) / 5.0, 1.0)
        rarity = 1.0 - commonness
        length_bonus = min(max(len(lemma) - 4, 0) * 0.05, 0.25)
        return min(max(rarity + length_bonus, 0.0), 1.0)

    def get_lexical_specificity_score(self, lemma: str, text: str) -> float:
        """Reward rarer, more specialized words that appear as content terms in the current sentence."""
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

        # Extra reward for words that appear in a noun chunk or are a meaningful content word
        chunk_bonus = 0.0
        for chunk in doc.noun_chunks:
            if lemma == chunk.root.lemma_.lower():
                chunk_bonus = 0.1
                break

        return min(max(rarity + length_bonus + chunk_bonus, 0.0), 1.0)

    def get_context_focus_score(self, lemma: str, text: str) -> float:
        """Prefer words that are central to the sentence context rather than generic fillers."""
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
            "NOUN": 0.15,
            "PROPN": 0.12,
            "VERB": 0.05,
            "ADJ": 0.05,
            "ADV": 0.02,
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
                "A1": 0.10,
                "A2": 0.30,
                "B1": 0.50,
                "B2": 0.70,
                "C1": 0.90,
                "C2": 1.00,
            }
            min_cefr = level_thresholds.get(level.upper(), 0.50)
            results = [item for item in results if item["breakdown"]["cefr"] >= min_cefr]

        if top_k is None or top_k >= len(results):
            top_results = results
        else:
            top_results = results[:top_k]

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