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
        self.db_path = db_path
        self._lock = threading.Lock()
        self._init_db()

    def _get_connection(self):
        if not hasattr(self, "_conn") or self._conn is None:
            self._conn = sqlite3.connect(self.db_path, check_same_thread=False)
        return self._conn

    def close(self):
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
            cursor.execute("SELECT level FROM user_settings WHERE user_id = ?", (user_id,))
            row = cursor.fetchone()
            return row[0] if row else None

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

    # ==========================================================
    # CẬP NHẬT SM-2 VỚI LỊCH "THỜI GIẢN VÀNG ÔN TẬP"
    # ==========================================================
    def review_word(self, user_id: str, word: str, quality: int) -> Dict[str, Any]:
        if quality not in [1, 2, 3, 4]:
            raise ValueError("Quality phải từ 1 đến 4.")

        word = word.lower()
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
                # Ôn lại sau 4 giờ (khung giờ vàng để ghi nhớ lại từ quên)
                next_review = now + timedelta(hours=4)
            else:
                if rep_count == 0:
                    # Lần học đầu tiên thành công -> Ôn lại sau 6 giờ (khung giờ vàng cho não bộ)
                    next_review = now + timedelta(hours=6)
                    interval = 1
                elif rep_count == 1:
                    # Lần thứ 2 -> Tầm 24 giờ sau
                    next_review = now + timedelta(hours=24)
                    interval = 1
                else:
                    # Các lần tiếp theo theo chu kỳ Spaced Repetition
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
        """Cập nhật mastery cho bài tập Matching và Typing"""
        word = word.lower()
        quality = 3 if is_correct else 1
        return self.review_word(user_id, word, quality)

    # ==========================================================
    # LẤY TỪ CHO CHẾ ĐỘ STUDY (30 TỪ ĐẦU TIÊN CÓ MASTERY < 1.0)
    # ==========================================================
    def get_study_words(self, user_id: str, limit: int = 30) -> List[Dict[str, Any]]:
        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()
            cursor.execute("""
                SELECT word, pos, definition, synonyms, context_example, level, mastery_score, interval_days
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
                    "synonyms": json.loads(r[3]) if r[3] else [],
                    "context_example": r[4],
                    "level": r[5],
                    "mastery": r[6],
                    "interval_days": r[7]
                }
                for r in rows
            ]

    # ==========================================================
    # LẤY TỪ CHO CHẾ ĐỘ PRACTICE (ENDLESS VỚI TỈ LỆ TRỌNG SỐ)
    # ==========================================================
    def get_practice_word(self, user_id: str, recent_words: List[str]) -> Optional[Dict[str, Any]]:
        with self._lock:
            conn = self._get_connection()
            cursor = conn.cursor()

            # Group 1: Chưa ôn / Đang học (mastery < 1.0)
            cursor.execute("""
                SELECT word, pos, definition, synonyms, context_example, level, mastery_score
                FROM user_vocabulary WHERE user_id = ? AND mastery_score < 1.0
            """, (user_id,))
            unreviewed_pool = cursor.fetchall()

            # Group 2: Từ mastered (mastery >= 1.0)
            cursor.execute("""
                SELECT word, pos, definition, synonyms, context_example, level, mastery_score
                FROM user_vocabulary WHERE user_id = ? AND mastery_score >= 1.0
            """, (user_id,))
            mastered_pool = cursor.fetchall()

            # Group 3: Tất cả từ trong kho
            cursor.execute("""
                SELECT word, pos, definition, synonyms, context_example, level, mastery_score
                FROM user_vocabulary WHERE user_id = ?
            """, (user_id,))
            all_inventory = cursor.fetchall()

            if not all_inventory:
                return None

            selected_row = None

            # Nếu còn từ chưa ôn/học chưa thuộc
            if unreviewed_pool:
                # Tỉ lệ 70% chưa ôn, 20% vừa ôn, 10% mastered
                rand = random.random()
                if rand < 0.70:
                    selected_row = random.choice(unreviewed_pool)
                elif rand < 0.90:
                    recent_pool = [r for r in all_inventory if r[0] in recent_words]
                    selected_row = random.choice(recent_pool) if recent_pool else random.choice(unreviewed_pool)
                else:
                    selected_row = random.choice(mastered_pool) if mastered_pool else random.choice(unreviewed_pool)
            else:
                # Khi đã hết từ chưa ôn -> 60% kho chung (inventory), 40% từ vừa ôn
                rand = random.random()
                if rand < 0.60:
                    selected_row = random.choice(all_inventory)
                else:
                    recent_pool = [r for r in all_inventory if r[0] in recent_words]
                    selected_row = random.choice(recent_pool) if recent_pool else random.choice(all_inventory)

            return {
                "word": selected_row[0],
                "pos": selected_row[1],
                "definition": selected_row[2],
                "synonyms": json.loads(selected_row[3]) if selected_row[3] else [],
                "context_example": selected_row[4],
                "level": selected_row[5],
                "mastery": selected_row[6]
            }

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