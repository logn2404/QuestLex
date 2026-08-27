import nltk
from nltk.corpus import wordnet
from typing import Dict, Any


class LargeOfflineDictionary:
    def __init__(self):
        pass

    def lookup(self, word: str) -> Dict[str, Any]:
        word = word.lower().strip()
        result = {
            "word": word,
            "pos": "unknown",
            "definition": "",
            "synonyms": [],
        }

        synsets = wordnet.synsets(word)
        if not synsets:
            return result

        # Lấy nghĩa phổ biến nhất
        first_syn = synsets[0]
        result["definition"] = first_syn.definition()

        # Quy đổi POS tag của WordNet sang chuẩn ngắn gọn (noun, verb, adj, adv)
        pos_map = {'n': 'noun', 'v': 'verb', 'a': 'adj', 's': 'adj', 'r': 'adv'}
        result["pos"] = pos_map.get(first_syn.pos(), 'unknown')

        # Gom nhóm từ đồng nghĩa không trùng lặp
        synonyms_set = set()
        for syn in synsets:
            for lemma in syn.lemmas():
                syn_name = lemma.name().replace('_', ' ')
                if syn_name.lower() != word:
                    synonyms_set.add(syn_name)

        result["synonyms"] = list(synonyms_set)[:5]  # Lấy tối đa 5 từ đồng nghĩa
        return result
