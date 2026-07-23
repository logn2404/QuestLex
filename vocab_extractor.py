import math
import urllib.request
import json
from typing import List, Dict, Any
import spacy
import torch
from keybert import KeyBERT

class VocabularyExtractor:
    def __init__(self, spacy_model: str = "en_core_web_sm"):
        print("Loading spaCy model...")
        self.nlp = spacy.load(spacy_model)
        
        device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"Loading KeyBERT model on device: {device}...")
        self.kw_model = KeyBERT(model="all-MiniLM-L6-v2")

        # CSDL Mock điểm số
        self.cefr_db = {
            "apple": "A1", "read": "A1", "important": "B1",
            "algorithm": "C1", "resilient": "C2", "ubiquitous": "C2"
        }
        self.freq_db = {
            "apple": 10000, "important": 5000, "algorithm": 800, "resilient": 200
        }

    def _fetch_dictionary_info(self, word: str) -> Dict[str, Any]:
        """Gọi API từ điển miễn phí để lấy Definition và Synonyms cho từ."""
        url = f"https://api.dictionaryapi.dev/api/v2/entries/en/{word}"
        info = {"definition": "", "synonyms": []}
        
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req) as response:
                if response.status == 200:
                    data = json.loads(response.read().decode())[0]
                    meanings = data.get("meanings", [])
                    if meanings:
                        # Lấy định nghĩa đầu tiên
                        defs = meanings[0].get("definitions", [])
                        if defs:
                            info["definition"] = defs[0].get("definition", "")
                        
                        # Cố gắng lấy từ đồng nghĩa từ tất cả các nghĩa
                        synonyms = []
                        for m in meanings:
                            synonyms.extend(m.get("synonyms", []))
                        info["synonyms"] = list(set(synonyms))[:3] # Lấy tối đa 3 từ đồng nghĩa
        except Exception:
            pass # Bỏ qua nếu lỗi mạng hoặc không tìm thấy từ
            
        return info

    def extract_candidates(self, text: str) -> List[Dict[str, str]]:
        doc = self.nlp(text)
        candidates = []
        seen_lemmas = set()

        target_pos = {"NOUN", "VERB", "ADJ", "ADV", "PROPN"}

        for token in doc:
            lemma = token.lemma_.lower()
            if (
                token.pos_ in target_pos 
                and not token.is_stop 
                and token.is_alpha 
                and len(lemma) > 1
                and lemma not in seen_lemmas
            ):
                candidates.append({
                    "lemma": lemma,
                    "pos": token.pos_,
                    "original_text": token.text,
                    "context_example": token.sent.text.strip() # Lấy TRỰC TIẾP câu chứa từ này
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
        level = self.cefr_db.get(lemma, "B2")
        return mapping.get(level, 0.7)

    def get_frequency_score(self, lemma: str) -> float:
        freq = self.freq_db.get(lemma, 500)
        return min(math.log10(freq) / 5.0, 1.0)

    def get_user_score(self, lemma: str, user_history: Dict[str, Any]) -> float:
        user_words = user_history.get("learned_words", {})
        if lemma in user_words:
            mastery_level = user_words[lemma].get("mastery", 0)
            return 1.0 - mastery_level
        return 1.0

    def process_text(
        self, 
        text: str, 
        user_history: Dict[str, Any], 
        top_k: int = 5,
        weights: Dict[str, float] = None
    ) -> List[Dict[str, Any]]:
        if weights is None:
            weights = {"keybert": 0.35, "cefr": 0.25, "frequency": 0.15, "user": 0.25}

        candidates = self.extract_candidates(text)
        kb_scores = self.get_keybert_scores(text, candidates)

        results = []
        for cand in candidates:
            lemma = cand["lemma"]
            s_kb = kb_scores.get(lemma, 0.0)
            s_cefr = self.get_cefr_score(lemma)
            s_freq = self.get_frequency_score(lemma)
            s_user = self.get_user_score(lemma, user_history)

            questlex_score = (
                weights["keybert"] * s_kb +
                weights["cefr"] * s_cefr +
                weights["frequency"] * s_freq +
                weights["user"] * s_user
            )

            results.append({
                "word": lemma,
                "pos": cand["pos"],
                "context_example": cand["context_example"], # Câu ví dụ lấy từ văn bản gốc
                "questlex_score": round(questlex_score, 4),
                "breakdown": {
                    "keybert": round(s_kb, 3),
                    "cefr": round(s_cefr, 3),
                    "frequency": round(s_freq, 3),
                    "user_priority": round(s_user, 3)
                }
            })

        # Sắp xếp để lấy Top K trước
        results.sort(key=lambda x: x["questlex_score"], reverse=True)
        top_results = results[:top_k]

        # Chỉ tra API định nghĩa và đồng nghĩa cho Top K (tối ưu thời gian chạy)
        for item in top_results:
            dict_info = self._fetch_dictionary_info(item["word"])
            item["definition"] = dict_info["definition"]
            item["synonyms"] = dict_info["synonyms"]

        return top_results