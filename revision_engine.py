import sqlite3
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
import json

class RevisionEngine:
    def __init__(self, db_path: str = "vocab_app.db"):
        """
        Khởi tạo Revision Engine kết nối SQLite database.
        """
        self.db_path = db_path
        self._init_db()

    def _get_connection(self):
        return sqlite3.connect(self.db_path)

    def _init_db(self):
        """
        Khởi tạo bảng cơ sở dữ liệu nếu chưa tồn tại.
        """
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS user_vocabulary (
                    user_id TEXT,
                    word TEXT,
                    pos TEXT,
                    definition TEXT,
                    synonyms TEXT,
                    context_example TEXT,
                    mastery_score REAL DEFAULT 0.0,
                    repetition_count INTEGER DEFAULT 0,
                    interval_days INTEGER DEFAULT 0,
                    ease_factor REAL DEFAULT 2.5,
                    next_review_date TIMESTAMP,
                    created_at TIMESTAMP,
                    PRIMARY KEY (user_id, word)
                )
            """)
            conn.commit()

    # ==========================================
    # 1. THÊM TỪ MỚI VÀO SỔ TỪ VỰNG CỦA USER
    # ==========================================
    def add_word_to_study(
        self, user_id: str, word: str, pos: str, 
        definition: str = "", synonyms: List[str] = None, context_example: str = ""
    ) -> bool:
        now = datetime.now()
        synonyms_str = json.dumps(synonyms) if synonyms else "[]"

        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                INSERT OR IGNORE INTO user_vocabulary 
                (user_id, word, pos, definition, synonyms, context_example, 
                 mastery_score, repetition_count, interval_days, ease_factor, next_review_date, created_at)
                VALUES (?, ?, ?, ?, ?, ?, 0.0, 0, 0, 2.5, ?, ?)
            """, (user_id, word.lower(), pos, definition, synonyms_str, context_example, now, now))
            conn.commit()
            return cursor.rowcount > 0

    # ==========================================
    # 2. THUẬT TOÁN SM-2 (SPACED REPETITION)
    # ==========================================
    def review_word(self, user_id: str, word: str, quality: int) -> Dict[str, Any]:
        if quality not in [1, 2, 3, 4]:
            raise ValueError("Quality phải từ 1 đến 4.")

        word = word.lower()
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT repetition_count, interval_days, ease_factor 
                FROM user_vocabulary WHERE user_id = ? AND word = ?
            """, (user_id, word))
            row = cursor.fetchone()

            if not row:
                raise ValueError(f"Từ '{word}' chưa được thêm vào kho học của user.")

            rep_count, interval, ease_factor = row

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

            mastery_score = min(1.0, round(interval / 30.0, 2))
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
        with self._get_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("""
                SELECT word, pos, definition, synonyms, context_example, mastery_score, interval_days
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
                    "mastery": r[5], 
                    "interval_days": r[6]
                }
                for r in rows
            ]

    # ==========================================
    # 4. XUẤT USER HISTORY CẤP CHO MODULE 1
    # ==========================================
    def get_user_history_for_extractor(self, user_id: str) -> Dict[str, Any]:
        with self._get_connection() as conn:
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