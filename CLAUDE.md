# CLAUDE.md

This file provides guidance to AI coding assistants (e.g. Claude) working with the **QuestLex** repository.

## What This Project Is

QuestLex is an offline-first **Vietnamese-language CLI app** that turns screenshots (newspaper articles, game dialogue, social media posts, etc.) into personalized English vocabulary study material. The pipeline:

1. **OCR** — extracts text from images in `images/` (primary engine: EasyOCR; alternatives: Gemini, RapidOCR).
2. **Vocabulary selection** — scores candidate words via a weighted "QuestLex score" (KeyBERT, CEFR level, frequency, lexical specificity, context focus, user history) and picks words matching the user's CEFR proficiency level.
3. **Enrichment** — for each chosen word, fetch a definition, synonyms, and an example sentence (WordNet + NLTK corpora, with offline fallback).
4. **Persistence** — words are stored in a SQLite DB (`user_history/vocab_app.db`) with fields: `level`, `mastery_score`, `definition`, `synonyms`, `context_example`, plus SM-2 spaced-repetition state.
5. **Revision** — a flashcard CLI uses the SM-2 algorithm to schedule reviews; the user rates each word 1–4 and the engine updates interval/ease factor/mastery.

## Performance & Accuracy Notes (latest)

- **Lazy model loading** — `main.py` no longer imports KeyBERT/torch/EasyOCR at startup. The OCR engine is built on the first scan (`choice 1`) only; flashcard/history use starts instantly. GPU is auto-detected via `torch.cuda.is_available()`.
- **Single spaCy parse** — `VocabularyExtractor` parses the text once per image and reuses the `Doc` (`_doc_cache`). The dependency parser and NER are disabled for speed; sentence boundaries come from the sentencizer and multi-word candidates come from a POS-tag `Matcher` (no parser needed).
- **Context-first examples** — the original sentence the word appeared in is preferred over a generic NLTK corpus sentence (`build_example_sentence`). NLTK is the fallback.
- **Real lexical data** — `wordfreq` (bundled offline frequency data, packaged via pip) drives CEFR/frequency scoring. A downloadable `models/wordlists/cefr.tsv` (via `python download_wordlists.py`) overrides wordfreq when present; `DOMAIN_CEFR` handles curated domain words (jedi, lightsaber, etc.).
- **Weighted scoring** — `pos_bonus` is a weighted component (`weights["pos"]`, default 0.07) inside the sum, so `questlex_score` stays in the 0–1 range and the `score_threshold` means the same thing for every POS.
- **Recursion guard** — `_fetch_dictionary_info` inserts its cache entry before building the example sentence, breaking the fetch → example → unrelated-check → fetch recursion.
- **Dictionary fallback** — `offline_dictionary.lookup` returns an empty definition for unknown words so the WordNet sense-selection path (with ±5-token windowed Lesk) is used instead of a "not found" placeholder blocking the fallback.
- **SQLite** — `revision_engine.py` reuses one connection with `PRAGMA journal_mode=WAL`; `add_word_to_study` upserts enrichment fields on re-scan but never touches SM-2 state (intervals, ease, mastery).
- **OCR pipeline** — `paragraph=True` preserves line/sentence boundaries, low-confidence boxes (<0.30) are dropped, tiny images are upscaled (INTER_CUBIC) and huge ones downscaled (INTER_AREA), and spell-correction only applies when the candidate is a different valid dictionary word.
- **NLTK example index** — the index build is capped at 80k sentences (was millions) and written with pickle protocol 4, cutting first-run from minutes to seconds.

## Project Structure

```
QuestLex/
├── CLAUDE.md                  # This file
├── .gitignore
├── AI/                        # All Python source lives here
│   ├── main.py                # App entry point + Vietnamese CLI menu
