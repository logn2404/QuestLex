import sqlite3
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
import json
import random
import threading

PROJECT_DIR = Path(__file__).resolve().parent
DB_DIR = PROJECT_DIR / "../user_history" / "vocab_app.db"


class RevisionEngine:
    def __init__(self, db_path: str = DB_DIR):
        self.db_path = Path(db_path)
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._lock = threading.Lock()
        self._conn = None
        self._init_db()

    def _get_connection(self):
        if self._conn is None:
            self._conn = sqlite3.connect(self.db_path, check_same_thread=False)
        return self._conn

    def close(self):
        with self._lock:
            if self._conn is not None:
                try:
                    self._conn.close()
                finally:
                    self._conn = None

    def _init_db(self):
        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS user_vocabulary (
                    user_id TEXT,
                    word TEXT,
                    pos TEXT,
                    definition TEXT,
                    synonyms TEXT,
                    context_example TEXT,
                    level TEXT DEFAULT 'A1',
                    mastery_score REAL DEFAULT 0.0,
                    repetition_count INTEGER DEFAULT 0,
                    interval_days INTEGER DEFAULT 0,
                    ease_factor REAL DEFAULT 2.5,
                    next_review_date TIMESTAMP,
                    created_at TIMESTAMP,
                    vietnamese_meaning TEXT DEFAULT '',
                    PRIMARY KEY (user_id, word)
                )
            """)
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS user_settings (
                    user_id TEXT PRIMARY KEY,
                    level TEXT,
                    updated_at TIMESTAMP
                )
            """)

            cursor.execute("PRAGMA table_info(user_vocabulary)")
            columns = {row[1] for row in cursor.fetchall()}
            if "level" not in columns:
                cursor.execute("ALTER TABLE user_vocabulary ADD COLUMN level TEXT DEFAULT 'A1'")
            if "mastery_score" not in columns:
                cursor.execute("ALTER TABLE user_vocabulary ADD COLUMN mastery_score REAL DEFAULT 0.0")
            if "vietnamese_meaning" not in columns:
                cursor.execute("ALTER TABLE user_vocabulary ADD COLUMN vietnamese_meaning TEXT DEFAULT ''")

            conn.commit()

    @staticmethod
    def _safe_json_loads(data: Optional[str]) -> List[str]:
        if not data:
            return []
        try:
            res = json.loads(data)
            return res if isinstance(res, list) else []
        except Exception:
            return []

    def save_user_level(self, user_id: str, level: str) -> None:
        now = datetime.now()
        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO user_settings (user_id, level, updated_at)
                VALUES (?, ?, ?)
                ON CONFLICT(user_id)
                DO UPDATE SET level = excluded.level, updated_at = excluded.updated_at
                """,
                (user_id, level.upper(), now)
            )
            conn.commit()

    def get_user_level(self, user_id: str) -> Optional[str]:
        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()
            cursor.execute("SELECT level FROM user_settings WHERE user_id = ?", (user_id,))
            row = cursor.fetchone()
            return row[0] if row else None

    def add_word_to_study(
        self, user_id: str, word: str, pos: str,
        definition: str = "", synonyms: List[str] = None, context_example: str = "",
        level: str = "A1", mastery_score: float = 0.0, vietnamese_meaning: str = ""
    ) -> bool:
        now = datetime.now()
        synonyms_str = json.dumps(synonyms) if synonyms else "[]"
        normalized_level = (level or "A1").upper()
        word = word.lower().strip()

        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()

            cursor.execute("""
                INSERT INTO user_vocabulary 
                (user_id, word, pos, definition, synonyms, context_example, level, mastery_score,
                 repetition_count, interval_days, ease_factor, next_review_date, created_at, vietnamese_meaning)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 2.5, ?, ?, ?)
                ON CONFLICT(user_id, word) DO UPDATE SET
                    pos = excluded.pos,
                    definition = excluded.definition,
                    synonyms = excluded.synonyms,
                    context_example = excluded.context_example,
                    level = excluded.level,
                    vietnamese_meaning = excluded.vietnamese_meaning
            """, (user_id, word, pos, definition, synonyms_str, context_example,
                  normalized_level, round(float(mastery_score), 2), now, now, vietnamese_meaning))
            conn.commit()
            return cursor.rowcount > 0

    def review_word(self, user_id: str, word: str, quality: int) -> Dict[str, Any]:
        if quality not in [1, 2, 3, 4]:
            raise ValueError("Quality phải từ 1 đến 4.")

        word = word.lower().strip()
        now = datetime.now()

        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()
            cursor.execute("""
                SELECT repetition_count, interval_days, ease_factor, mastery_score
                FROM user_vocabulary WHERE user_id = ? AND word = ?
            """, (user_id, word))
            row = cursor.fetchone()

            if not row:
                raise ValueError(f"Từ '{word}' chưa được thêm vào kho học của user.")

            rep_count, interval, ease_factor, current_mastery = row

            if quality < 3:
                rep_count = 0
                interval = 0
                next_review = now + timedelta(hours=4)
            else:
                if rep_count == 0:
                    next_review = now + timedelta(hours=6)
                    interval = 1
                elif rep_count == 1:
                    next_review = now + timedelta(hours=24)
                    interval = 1
                else:
                    interval = int(interval * ease_factor)
                    if interval < 2:
                        interval = 2
                    next_review = now + timedelta(days=interval)

                rep_count += 1

            q_sm2 = quality + 1
            ease_factor = ease_factor + (0.1 - (5 - q_sm2) * (0.08 + (5 - q_sm2) * 0.02))
            ease_factor = max(1.3, ease_factor)

            mastery_increment = {1: -0.1, 2: 0.05, 3: 0.15, 4: 0.25}.get(quality, 0.1)
            new_mastery = max(0.0, min(1.0, round(float(current_mastery or 0.0) + mastery_increment, 2)))

            cursor.execute("""
                UPDATE user_vocabulary 
                SET repetition_count = ?, interval_days = ?, ease_factor = ?, 
                    mastery_score = ?, next_review_date = ?
                WHERE user_id = ? AND word = ?
            """, (rep_count, interval, ease_factor, new_mastery, next_review, user_id, word))
            conn.commit()

            return {
                "word": word,
                "next_review_in_days": interval,
                "next_review_date": next_review.strftime("%Y-%m-%d %H:%M"),
                "mastery_score": new_mastery
            }

    def update_word_result(self, user_id: str, word: str, is_correct: bool):
        word = word.lower().strip()
        quality = 3 if is_correct else 1
        return self.review_word(user_id, word, quality)

    def get_study_words(self, user_id: str, limit: int = 30) -> List[Dict[str, Any]]:
        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()
            cursor.execute("""
                SELECT word, pos, definition, synonyms, context_example, level, mastery_score, interval_days, vietnamese_meaning
                FROM user_vocabulary 
                WHERE user_id = ? AND mastery_score < 1.0
                ORDER BY next_review_date ASC, created_at ASC
                LIMIT ?
            """, (user_id, limit))

            rows = cursor.fetchall()
            return [
                {
                    "word": r[0],
                    "pos": r[1],
                    "definition": r[2],
                    "synonyms": self._safe_json_loads(r[3]),
                    "context_example": r[4],
                    "level": r[5],
                    "mastery": r[6],
                    "interval_days": r[7],
                    "vietnamese_meaning": r[8] or ""
                }
                for r in rows
            ]

    def get_practice_word(self, user_id: str, recent_words: List[str]) -> Optional[Dict[str, Any]]:
        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()

            cursor.execute("""
                SELECT word, pos, definition, synonyms, context_example, level, mastery_score, vietnamese_meaning
                FROM user_vocabulary WHERE user_id = ? AND mastery_score < 1.0
            """, (user_id,))
            unreviewed_pool = cursor.fetchall()

            cursor.execute("""
                SELECT word, pos, definition, synonyms, context_example, level, mastery_score, vietnamese_meaning
                FROM user_vocabulary WHERE user_id = ? AND mastery_score >= 1.0
            """, (user_id,))
            mastered_pool = cursor.fetchall()

            cursor.execute("""
                SELECT word, pos, definition, synonyms, context_example, level, mastery_score, vietnamese_meaning
                FROM user_vocabulary WHERE user_id = ?
            """, (user_id,))
            all_inventory = cursor.fetchall()

            if not all_inventory:
                return None

            # Lọc bỏ các từ vừa ôn gần đây
            unreviewed_fresh = [r for r in unreviewed_pool if r[0] not in recent_words]
            mastered_fresh = [r for r in mastered_pool if r[0] not in recent_words]
            all_fresh = [r for r in all_inventory if r[0] not in recent_words]

            selected_row = None

            if unreviewed_pool:
                rand = random.random()
                if rand < 0.70:
                    pool = unreviewed_fresh or unreviewed_pool
                    selected_row = random.choice(pool)
                elif rand < 0.90:
                    pool = all_fresh or all_inventory
                    selected_row = random.choice(pool)
                else:
                    pool = mastered_fresh or mastered_pool or unreviewed_pool
                    selected_row = random.choice(pool)
            else:
                pool = all_fresh or all_inventory
                selected_row = random.choice(pool)

            return {
                "word": selected_row[0],
                "pos": selected_row[1],
                "definition": selected_row[2],
                "synonyms": self._safe_json_loads(selected_row[3]),
                "context_example": selected_row[4],
                "level": selected_row[5],
                "mastery": selected_row[6],
                "vietnamese_meaning": selected_row[7] or ""
            }

    def get_all_user_history(self, user_id: str) -> List[Dict[str, Any]]:
        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()
            cursor.execute(
                """
                SELECT word, pos, definition, synonyms, context_example, level, mastery_score, interval_days, repetition_count, next_review_date, created_at, vietnamese_meaning
                FROM user_vocabulary
                WHERE user_id = ?
                ORDER BY level ASC, word ASC
                """,
                (user_id,)
            )
            rows = cursor.fetchall()
            return [
                {
                    "word": r[0],
                    "pos": r[1],
                    "definition": r[2],
                    "synonyms": self._safe_json_loads(r[3]),
                    "context_example": r[4],
                    "level": r[5],
                    "mastery": r[6],
                    "interval_days": r[7],
                    "repetition_count": r[8],
                    "next_review_date": r[9],
                    "created_at": r[10],
                    "vietnamese_meaning": r[11] or ""
                }
                for r in rows
            ]

    def get_user_history_for_extractor(self, user_id: str) -> Dict[str, Any]:
        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()
            cursor.execute("""
                SELECT word, mastery_score FROM user_vocabulary WHERE user_id = ?
            """, (user_id,))
            rows = cursor.fetchall()

            learned_words = {r[0]: {"mastery": r[1]} for r in rows}
            return {
                "user_id": user_id,
                "learned_words": learned_words
            }