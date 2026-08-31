import json
from pathlib import Path
from typing import Dict, Any, List

import nltk
from nltk.corpus import wordnet

try:
    from deep_translator import GoogleTranslator
except ImportError:
    GoogleTranslator = None

PROJECT_DIR = Path(__file__).resolve().parent
EN_VI_DICT_PATH = PROJECT_DIR / "models" / "en_vi_dict.json"


class LargeOfflineDictionary:
    def __init__(self):
        self.en_vi_dict = {}
        self._load_vi_dict()
        self.translator = None
        if GoogleTranslator:
            try:
                self.translator = GoogleTranslator(source='en', target='vi')
            except Exception:
                pass

    def _load_vi_dict(self):
        if EN_VI_DICT_PATH.exists():
            try:
                with open(EN_VI_DICT_PATH, "r", encoding="utf-8") as f:
                    self.en_vi_dict = json.load(f)
            except Exception:
                pass

    def lookup(self, word: str) -> Dict[str, Any]:
        word_clean = word.lower().strip()
        result = {
            "word": word_clean,
            "pos": "unknown",
            "definition": "",
            "synonyms": [],
            "vietnamese_meaning": "Không có"
        }

        # 1. Lấy nghĩa tiếng Việt từ file từ điển local trước
        lookup_keys = [word_clean, word_clean.replace("_", " ")]
        vi_meanings = None
        for key in lookup_keys:
            if key in self.en_vi_dict:
                vi_meanings = self.en_vi_dict[key]
                break

        if vi_meanings:
            if isinstance(vi_meanings, list):
                result["vietnamese_meaning"] = ", ".join(vi_meanings[:3])
            elif isinstance(vi_meanings, str):
                result["vietnamese_meaning"] = vi_meanings
        elif self.translator:
            # 2. Fallback sang dịch tự động nếu từ không có trong từ điển local
            try:
                query_word = word_clean.replace("_", " ")
                translated = self.translator.translate(query_word)
                if translated:
                    result["vietnamese_meaning"] = translated
            except Exception:
                pass

        # 3. Lấy định nghĩa và từ đồng nghĩa từ WordNet
        try:
            synsets = wordnet.synsets(word_clean)
            if not synsets and "_" in word_clean:
                synsets = wordnet.synsets(word_clean.replace("_", " "))
        except Exception:
            synsets = []

        if not synsets:
            return result

        # Lấy nghĩa phổ biến nhất
        first_syn = synsets[0]
        result["definition"] = first_syn.definition()

        # Quy đổi POS tag của WordNet sang chuẩn ngắn gọn
        pos_map = {'n': 'noun', 'v': 'verb', 'a': 'adj', 's': 'adj', 'r': 'adv'}
        result["pos"] = pos_map.get(first_syn.pos(), 'unknown')

        # Gom nhóm từ đồng nghĩa không trùng lặp
        synonyms_set = set()
        for syn in synsets:
            for lemma in syn.lemmas():
                syn_name = lemma.name().replace('_', ' ')
                if syn_name.lower() != word_clean and syn_name.lower() != word_clean.replace('_', ' '):
                    synonyms_set.add(syn_name)

        result["synonyms"] = list(synonyms_set)[:5]
        return result