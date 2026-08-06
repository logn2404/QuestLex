# GitHub Copilot Instructions for Automatic Language Learning

## Project purpose
This repository is a lightweight Python CLI app for AI-assisted vocabulary learning. The user journey is a menu-driven pipeline that:
1. extracts text from a screenshot or image using OCR,
2. ranks and filters useful vocabulary with a multi-signal scoring system,
3. stores the selected words in SQLite,
4. reviews them later using spaced repetition.

The app is centered on the workflow in `main.py`, with supporting logic split into these modules:
- `ocr_extractor.py` for EasyOCR extraction and image preprocessing
- `vocab_extractor.py` for candidate extraction, KeyBERT ranking, CEFR/frequency scoring, POS normalization, specificity/context scoring, and dictionary enrichment
- `revision_engine.py` for SQLite persistence and SM-2-style review scheduling
- `flashcard_cli.py` for the interactive flashcard review UI

## Primary entry points
- Run the app with: `python main.py`
- Run the flashcard review flow directly with: `python flashcard_cli.py`

## Runtime architecture
The main execution path is:
1. `main.py` creates `OCRExtractor`, `VocabularyExtractor`, and `RevisionEngine`.
2. On first run, the user is prompted to choose a proficiency level (`Beginner`, `Amateur`, `Expert`) that maps to CEFR bands `B1`, `B2`, and `C1`.
3. The selected level is persisted in the `user_settings` table and reused automatically on later runs.
4. `OCRExtractor.extract_text_from_image(...)` returns OCR text from one or more processed image variants.
5. `RevisionEngine.get_user_history_for_extractor(...)` supplies user mastery history so previously learned words are not re-suggested.
6. `VocabularyExtractor.process_text(...)` ranks candidates by a blended score that includes KeyBERT, CEFR, frequency, lexical specificity, context focus, user priority, and POS bonus.
7. `RevisionEngine.add_word_to_study(...)` persists selected items into `vocab_app.db`.
8. The review flow uses `flashcard_cli.run_flashcard_session(...)` to show due words and update review state.
9. Users can also review their full saved vocabulary history from the main menu via `RevisionEngine.get_all_user_history(...)`.

## Important implementation details
- The project is a Python CLI, not a web app.
- Database storage is SQLite and the persistent file is `vocab_app.db`.
- Vocabulary extraction depends on:
  - `spacy`
  - `KeyBERT`
  - `nltk` with `wordnet`
  - `torch`
- OCR depends on `easyocr` and `opencv` via `cv2`.
- OCR preprocessing is intentionally multi-variant for complex page layouts where text can appear in different regions of the image.
- Dictionary lookup uses WordNet first, then falls back to the public dictionary API if needed.
- Candidate words are normalized to lowercase for persistence and stored per `user_id` and `word` in `user_vocabulary`.

## Coding guidance for future changes
- Preserve the existing interactive CLI flow in `main.py` unless the user explicitly requests a redesign.
- Keep the data flow linear and simple: OCR -> vocabulary ranking -> persistence -> spaced review.
- Prefer small, focused functions and keep file responsibilities separated.
- Do not rename core symbols without updating the import graph and call sites.
- When adding new features, keep the database schema and review logic compatible with `RevisionEngine`.
- If the user-level selection changes, keep the persistence model in `user_settings` backward-compatible.
- Prefer improving the existing ranking/filter pipeline over adding ad-hoc hard-coded caps.

## Data and persistence rules
- All learned words are stored per `user_id` and `word` in the `user_vocabulary` table.
- The selected proficiency level is persisted in `user_settings`.
- The review algorithm is generated from the existing SM-2-style implementation in `RevisionEngine.review_word(...)`.
- Keep `word` normalized to lowercase before persistence where appropriate.
- Previously learned words should not be returned again in the extraction flow unless the user explicitly asks for a re-review of history.

## Quality expectations
- Favor minimal, readable changes over large refactors.
- Preserve the current console output style and interactive prompts unless asked to redesign the UX.
- Avoid introducing hard requirements for a web framework or external service unless the task explicitly needs it.
- When adding dependency usage, keep the code compatible with the current CLI architecture.
- Prefer evidence-based fixes and regression validation over guesswork.

## Suggested validation workflow
Before claiming a change is complete:
1. Run the relevant Python file or entry point.
2. Confirm the interactive workflow still starts without immediate runtime errors.
3. If a change touches the database layer, verify that `vocab_app.db` is still created or updated correctly.
4. If a change touches OCR or vocabulary extraction, validate that the real image sample flow still produces usable text and ranked vocabulary.
5. Re-run the targeted regression test suite when scoring/filtering or persistence logic changes.

## Repository conventions
- Comments and user-facing messages are mixed between Vietnamese and English.
- Keep code readable and straightforward for a small research/demo project.
- Prefer adding new logic to the module that already owns that responsibility rather than spreading it across files.
- Favor stable, incremental improvements to the existing architecture rather than large rewrites.
- Preserve compatibility with the current menu-driven flow, SQLite persistence, and spaced repetition behavior.
