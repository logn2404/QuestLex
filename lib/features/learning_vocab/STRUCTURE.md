# learning_vocab

Thư mục này quản lý màn hình học từ vựng, gồm dữ liệu mock, model nghiệp vụ, controller và giao diện hiển thị tiến độ, tìm kiếm, chọn từ và thống kê CEFR.

```text
learning_vocab/
├─ data/
│  └─ repositories/
│     └─ fake_learning_vocab_repository.dart
│
├─ domain/
│  ├─ models/
│  │  ├─ daily_cefr_count.dart
│  │  ├─ learning_vocab_item.dart
│  │  └─ vocab_stats.dart
│  └─ repositories/
│     └─ learning_vocab_repository.dart
│
├─ presentation/
│  ├─ learning_page.dart
│  ├─ learning_vocab_controller.dart
│  └─ widgets/
│     ├─ cefr_bar_chart.dart
│     ├─ learning_analytics.dart
│     ├─ learning_control_panel.dart
│     ├─ search_bar.dart
│     ├─ word_card.dart
│     └─ word_queue.dart
│
├─ STRUCTURE.md
└─ README (nếu có sau này)
```

## 1. data/
Chứa tầng dữ liệu, hiện tại là mock repository để mô phỏng dữ liệu từ backend.

- fake_learning_vocab_repository.dart
  - Implements interface LearningVocabRepository.
  - Trả về danh sách từ vựng mẫu, số liệu thống kê theo ngày và tháng.
  - Dùng Future.delayed để mô phỏng latency.

## 2. domain/
Chứa logic nghiệp vụ và model dữ liệu cốt lõi.

### 2.1 models/
- learning_vocab_item.dart
  - Model của một từ vựng đang học.
  - Fields: id, word, meaning, cefrLevel, currentProgress, maxProgress.
  - Có getter progressPercentage để tính phần trăm tiến độ.

- daily_cefr_count.dart
  - Model thống kê số lượng từ theo từng mức CEFR theo ngày / tháng.
  - Mỗi mục có label và map countsByLevel.
  - total tính tổng số từ của từng nhánh thống kê.

- vocab_stats.dart
  - Model tính toán cấp độ học tập và điểm EXP từ số lượng từ theo level.
  - currentExp, calculatedLevel, expPercentage, totalStars là các giá trị dùng cho hiển thị tiến độ người dùng.

### 2.2 repositories/
- learning_vocab_repository.dart
  - Interface định nghĩa các method cần triển khai:
    - getLearningVocab()
    - getDailyStats()
    - getMonthlyStats()

## 3. presentation/
Chứa UI và state management cho màn hình học từ vựng.

- learning_page.dart
  - Là màn hình chính của module.
  - Dùng ChangeNotifierProvider để tạo LearningVocabController.
  - Sắp xếp layout gồm header, cột trái (analytics + control panel), cột phải (word queue), và thanh kéo resize giữa hai cột.

- learning_vocab_controller.dart
  - Controller quản lý toàn bộ state của màn hình.
  - Có các chức năng:
    - loadData(): nạp dữ liệu từ repository.
    - updateLeftPanelWidth(): chỉnh độ rộng cột trái.
    - toggleSelectionMode(): bật/tắt chế độ chọn từ.
    - toggleSelectItem(): chọn hoặc bỏ chọn một từ.
    - clearAllSelection(): xoá tất cả lựa chọn.
    - search(): tìm kiếm với debounce 300ms để tránh gọi filter quá nhiều.
    - _applyFilter(): lọc danh sách từ theo query.
  - Dùng ChangeNotifier để rebuild UI khi dữ liệu thay đổi.

### 3.1 widgets/
- word_queue.dart
  - Hiển thị danh sách từ vựng dạng grid.
  - Có tìm kiếm ở trên và card từ ở dưới.
  - Nếu isSelectionMode bật, mỗi WordCard có thể chọn/bỏ chọn.

- word_card.dart
  - Card hiển thị một từ vựng.
  - Bao gồm CEFR badge, từ, nghĩa, progress bar và tiến độ hiện tại.
  - Có trạng thái selected để hỗ trợ chọn nhiều từ.

- search_bar.dart
  - Thanh tìm kiếm dùng TextField.
  - Gửi onChanged tới controller để lọc dữ liệu.

- learning_analytics.dart
  - Hiển thị tiến độ học tập theo thời gian.
  - Có segmented button để chuyển giữa xem theo ngày và tháng.
  - Gọi CefrBarChart để vẽ chart.

- cefr_bar_chart.dart
  - Vẽ biểu đồ thanh ngang, phân theo mức CEFR A1 → C2.
  - Mỗi cột thời gian hiển thị tổng số từ và các phần màu theo từng level.

- learning_control_panel.dart
  - Panel điều khiển bên trái.
  - Có nút "HỌC NGAY" với badge chọn từ.
  - Có nút "CHỌN TỪ ĐỂ HỌC" / "THOÁT CHẾ ĐỘ CHỌN".
  - Có các shortcut điều hướng sang Inventory, Streak, Home.

## Tổng kết
Module learning_vocab hiện đang tập trung vào 3 chức năng chính:
1. Hiển thị danh sách từ vựng đang học.
2. Thống kê và biểu đồ tiến độ theo CEFR.
3. Chọn từ để học nhanh và chuyển hướng qua các màn hình khác.

Cấu trúc này đang theo hướng Clean-ish Architecture với:
- data: nguồn dữ liệu/mock
- domain: model + interface repository
- presentation: UI + controller + widget.
