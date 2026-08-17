import sqlite3
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
import json
import threading

PROJECT_DIR = Path(__file__).resolve().parent
DB_DIR = PROJECT_DIR / "../user_history" / "vocab_app.db"


class RevisionEngine:
    def __init__(self, db_path: str = DB_DIR):
        self.db_path = db_path
        self._lock = threading.Lock()
        self._init_db()

    def _get_connection(self):
        # Reuse one connection per engine instance instead of opening a new one
        # per call. Default journal mode keeps the DB to a single .db file
        # (no -wal/-shm sidecar files); this is a single-user local app so the
        # WAL concurrency trade-off is unnecessary.
        if not hasattr(self, "_conn") or self._conn is None:
            self._conn = sqlite3.connect(self.db_path, check_same_thread=False)
        return self._conn

    def close(self):
        """Close the persistent connection (releases the file handle on Windows)."""
        with self._lock:
            conn = getattr(self, "_conn", None)
            if conn is not None:
                try:
                    conn.close()
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

            conn.commit()

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
            cursor.execute(
                "SELECT level FROM user_settings WHERE user_id = ?",
                (user_id,)
            )
            row = cursor.fetchone()
            return row[0] if row else None

    # ==========================================
    # 1. THÊM TỪ MỚI VÀO SỔ TỪ VỰNG CỦA USER
    # ==========================================
    def add_word_to_study(
        self, user_id: str, word: str, pos: str,
        definition: str = "", synonyms: List[str] = None, context_example: str = "",
        level: str = "A1", mastery_score: float = 0.0
    ) -> bool:
        now = datetime.now()
        synonyms_str = json.dumps(synonyms) if synonyms else "[]"
        normalized_level = (level or "A1").upper()
        word = word.lower()

        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()

            # Upsert: refresh enriches on re-scan, but NEVER touch the SM-2
            # state (repetition_count, interval, ease, next_review, mastery).
            cursor.execute("""
                INSERT INTO user_vocabulary 
                (user_id, word, pos, definition, synonyms, context_example, level, mastery_score,
                 repetition_count, interval_days, ease_factor, next_review_date, created_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 2.5, ?, ?)
                ON CONFLICT(user_id, word) DO UPDATE SET
                    pos = excluded.pos,
                    definition = excluded.definition,
                    synonyms = excluded.synonyms,
                    context_example = excluded.context_example,
                    level = excluded.level
            """, (user_id, word, pos, definition, synonyms_str, context_example,
                  normalized_level, round(float(mastery_score), 2), now, now))
            conn.commit()
            return cursor.rowcount > 0

    # ==========================================
    # 2. THUẬT TOÁN SM-2 (SPACED REPETITION)
    # ==========================================
    def review_word(self, user_id: str, word: str, quality: int) -> Dict[str, Any]:
        if quality not in [1, 2, 3, 4]:
            raise ValueError("Quality phải từ 1 đến 4.")

        word = word.lower()
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
                interval = 1
            else:
                if rep_count == 0:
                    interval = 1
                elif rep_count == 1:
                    interval = 6
                else:
                    interval = int(interval * ease_factor)
                rep_count += 1

            q_sm2 = quality + 1
            ease_factor = ease_factor + (0.1 - (5 - q_sm2) * (0.08 + (5 - q_sm2) * 0.02))
            ease_factor = max(1.3, ease_factor)

            mastery_increment = {1: 0.1, 2: 0.2, 3: 0.3, 4: 0.4}.get(quality, 0.2)
            mastery_score = min(1.0, round(float(current_mastery or 0.0) + mastery_increment, 2))
            next_review = datetime.now() + timedelta(days=interval)

            cursor.execute("""
                UPDATE user_vocabulary 
                SET repetition_count = ?, interval_days = ?, ease_factor = ?, 
                    mastery_score = ?, next_review_date = ?
                WHERE user_id = ? AND word = ?
            """, (rep_count, interval, ease_factor, mastery_score, next_review, user_id, word))
            conn.commit()

            return {
                "word": word,
                "next_review_in_days": interval,
                "next_review_date": next_review.strftime("%Y-%m-%d"),
                "mastery_score": mastery_score
            }

    # ==========================================
    # 3. TRÍCH XUẤT CÁC TỪ CẦN ÔN TẬP HÔM NAY
    # ==========================================
    def get_due_words(self, user_id: str, limit: int = 10) -> List[Dict[str, Any]]:
        now = datetime.now()
        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()
            cursor.execute("""
                SELECT word, pos, definition, synonyms, context_example, level, mastery_score, interval_days
                FROM user_vocabulary 
                WHERE user_id = ? AND next_review_date <= ?
                ORDER BY next_review_date ASC
                LIMIT ?
            """, (user_id, now, limit))

            rows = cursor.fetchall()
            return [
                {
                    "word": r[0],
                    "pos": r[1],
                    "definition": r[2],
                    "synonyms": json.loads(r[3]) if r[3] else [],
                    "context_example": r[4],
                    "level": r[5],
                    "mastery": r[6],
                    "interval_days": r[7]
                }
                for r in rows
            ]

    def get_all_user_history(self, user_id: str) -> List[Dict[str, Any]]:
        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()
            cursor.execute(
                """
                SELECT word, pos, definition, synonyms, context_example, level, mastery_score, interval_days, repetition_count, next_review_date, created_at
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
                    "synonyms": json.loads(r[3]) if r[3] else [],
                    "context_example": r[4],
                    "level": r[5],
                    "mastery": r[6],
                    "interval_days": r[7],
                    "repetition_count": r[8],
                    "next_review_date": r[9],
                    "created_at": r[10]
                }
                for r in rows
            ]

    # ==========================================
    # 4. XUẤT USER HISTORY CẤP CHO MODULE 1
    # ==========================================
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
