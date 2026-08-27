# study

Module điều phối trải nghiệm học và luyện tập từ vựng trong QuestLex.

`study` hiện phụ trách màn hình chọn hình thức học, hiển thị trạng thái học tập, chọn mini-game và chạy animation chuyển cảnh trước khi mở bài học tương ứng. Dữ liệu từ vựng và tiến độ chi tiết hiện thuộc module `learning_vocab`, không nằm trực tiếp trong folder này.

```text
study/
├─ domain/
│  └─ enums/
│     ├─ study_mode.enum.dart
│     └─ study_task_type.enum.dart
│
├─ presentation/
│  ├─ pages/
│  │  └─ study_page.dart
│  └─ widgets/
│     ├─ study_header_banner.dart
│     ├─ study_mode_card.dart
│     ├─ study_mode_toggle.dart
│     ├─ study_task_card.dart
│     ├─ study_task_section.dart
│     └─ transitions/
│        ├─ flashcard_transition.dart
│        ├─ matching_transition.dart
│        └─ word_fill_transition.dart
│
└─ STRUCTURE.md
```

## 1. Vai trò của module

Module `study` là điểm vào cho workflow học từ vựng:

1. Người dùng mở `StudyPage`.
2. Chọn mode `STUDY` hoặc `PRACTICE`.
3. Xem banner mô tả trạng thái / phần thưởng của mode hiện tại.
4. Chọn một hình thức luyện tập.
5. Double-click vào card để chạy transition toàn màn hình.
6. Sau transition, module dự kiến điều hướng tới màn hình bài học tương ứng.

Module điều phối workflow học và luyện tập từ vựng. Module này hiện đã có controller, API repository, màn hình Study và màn Flashcard. Dữ liệu từ được truyền vào Study từ `learning_vocab` hoặc được tải ngầm từ backend.

## Cấu trúc thực tế

```text
study/
├─ data/
│  └─ repositories/
│     └─ api_study_repositories.dart
│
├─ domain/
│  └─ enums/
│     ├─ study_mode.enum.dart
│     └─ study_task_type.enum.dart
│
├─ presentation/
│  ├─ pages/
│  │  ├─ flashcard_page.dart
│  │  ├─ study_controller.dart
│  │  └─ study_page.dart
│  └─ widgets/
│     ├─ study_header_banner.dart
│     ├─ study_mode_card.dart
│     ├─ study_mode_toggle.dart
│     ├─ study_task_card.dart
│     ├─ study_task_section.dart
│     ├─ flashcard/
│     │  ├─ flashcard_action_buttons.dart
│     │  ├─ flashcard_flipper_card.dart
│     │  ├─ flashcard_header_progress.dart
│     │  └─ flashcard_session_view.dart
│     └─ transitions/
│        ├─ flashcard_transition.dart
│        ├─ matching_transition.dart
│        └─ word_fill_transition.dart
│
└─ STRUCTURE.md
```

## Tổng quan luồng

```text
MainShellPage
  └─ StudyPage
      └─ Provider<StudyController>
          ├─ ApiStudyRepository
          │   ├─ GET  /api/flashcards
          │   └─ POST /api/flashcards/review
          ├─ StudyModeToggle
          │   └─ setMode(study/practice)
          ├─ StudyHeaderBanner
          └─ StudyTaskSection
              ├─ Flashcard transition
              │   └─ FlashcardSessionView
              ├─ Matching transition
              │   └─ TODO: MatchingCardPage
              └─ Typing transition
                  └─ TODO: TypingWordPage
```

## 1. data/

### `data/repositories/api_study_repositories.dart`

Repository gọi backend bằng package `http`.

- Class: `ApiStudyRepository`.
- Base URL mặc định: `http://127.0.0.1:8000`.
- `getStudyWords({limit, mode})`:
  - Gọi `GET /api/flashcards`.
  - Gửi `limit`, `mode` và `user_id`.
  - Trả về `List<Map<String, dynamic>>`.
- `reviewWord(word, quality)`:
  - Gọi `POST /api/flashcards/review`.
  - Gửi word, quality và user_id.
  - Trả về `bool` theo trường `success`.

Lưu ý tên file hiện tại là `api_study_repositories.dart` số nhiều. Mọi import phải dùng đúng tên này, hoặc đổi tên file và cập nhật toàn bộ import một cách nhất quán.

## 2. domain/

### `domain/enums/study_mode.enum.dart`

Khai báo:

```dart
enum StudyMode { study, practice }
```

Được dùng bởi `StudyPage`, `StudyController`, `StudyModeToggle` và `StudyHeaderBanner`.

### `domain/enums/study_task_type.enum.dart`

Khai báo:

```dart
enum StudyTaskType { flashcard, matching, typing }
```

Hiện enum đã có nhưng phần UI vẫn cấu hình task trực tiếp bằng các `StudyModeCard`, chưa dùng enum này làm nguồn cấu hình chung.

## 3. presentation/pages/

### `presentation/pages/study_page.dart`

Màn hình entry point của module.

- Nhận `initialWords` kiểu `List<Map<String, dynamic>>`.
- Tạo `ChangeNotifierProvider<StudyController>`.
- Truyền `ApiStudyRepository` và `initialWords` cho controller.
- Hiển thị mode toggle, banner và danh sách task.
- Khi controller loading, hiển thị `CircularProgressIndicator`.
- Truyền `studyQueue` và `reviewWord` xuống `StudyTaskSection`.

### `presentation/pages/study_controller.dart`

Quản lý state và dữ liệu của phiên học.

- State:
  - `_studyQueue`: danh sách từ đang chờ học.
  - `_currentMode`: mode hiện tại, mặc định `StudyMode.study`.
  - `_isLoading`: trạng thái tải dữ liệu.
  - `isGoldenHour`, `expMultiplier`: hiện đang hard-code.
- `setMode(mode)`: đổi mode và tải lại từ.
- `loadStudyWords()`: gọi repository với tối đa 30 từ.
- `reviewWord(word, quality)`: gửi kết quả review về backend.
- Constructor dùng `initialWords` nếu danh sách được truyền vào; nếu rỗng thì gọi API.

## 4. presentation/widgets/

### `study_mode_toggle.dart`

Chuyển giữa `StudyMode.study` và `StudyMode.practice`, nhận callback `onModeChanged`.

### `study_header_banner.dart`

Hiển thị banner theo mode, trạng thái Giờ vàng, hệ số EXP và số lượng từ trong queue (`wordCount`).

### `study_task_section.dart`

Hiển thị ba task theo grid responsive.

- Nhận `words` và callback `onReview`.
- Double-click card sẽ mở một `OverlayEntry` toàn màn hình.
- Sau transition, Flashcard đã điều hướng thật tới `FlashcardSessionView`.
- Matching và Typing hiện vẫn có callback `TODO` cho page đích.

### `study_mode_card.dart`

Card có hover animation và tự nhận diện double-click trong khoảng 300ms.

### `study_task_card.dart`

Card dạng hàng ngang, dùng single-click. Hiện tồn tại nhưng chưa được `StudyTaskSection` sử dụng.

## 5. presentation/widgets/flashcard/

### `flashcard_session_view.dart`

Điều phối một phiên Flashcard.

- Theo dõi index của từ hiện tại và trạng thái lật thẻ.
- Khi người dùng đánh giá, gọi `onReview(word, quality)`.
- Quality hiện dùng `1` cho sai và `3` cho đúng.
- Hiển thị dialog khi hoàn thành toàn bộ queue.

### `flashcard_page.dart`

Wrapper page nhận `words` và `onReview`, sau đó render `FlashcardSessionView`. Hiện `StudyTaskSection` điều hướng trực tiếp tới `FlashcardSessionView` thay vì dùng wrapper này.

### Các widget con

- `flashcard_header_progress.dart`: nút quay lại, số thứ tự và progress bar.
- `flashcard_flipper_card.dart`: hiển thị từ, CEFR, nghĩa và ví dụ; hỗ trợ lật thẻ.
- `flashcard_action_buttons.dart`: nút đánh giá sai / đúng.

## 6. presentation/widgets/transitions/

Các overlay chỉ làm animation trung gian, nhận `onComplete` và không gọi API.

- `flashcard_transition.dart`: flip card và scale toàn màn hình.
- `matching_transition.dart`: tạo và làm biến mất ngẫu nhiên các chip từ vựng.
- `word_fill_transition.dart`: hiệu ứng các dải chữ và split-screen.

## 7. Import contract cho Gemini

### Import package chuẩn

Với package name `questlex`, import tuyệt đối nên dùng:

```dart
import 'package:questlex/features/study/data/repositories/api_study_repositories.dart';
import 'package:questlex/features/study/presentation/pages/study_controller.dart';
import 'package:questlex/features/study/domain/enums/study_mode.enum.dart';
```

Package `provider` và `http` được khai báo trong `pubspec.yaml`:

```dart
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
```

### Relative import chuẩn theo vị trí file

| File hiện tại | Muốn import | Relative path đúng |
|---|---|---|
| `presentation/pages/study_page.dart` | API repository | `../../data/repositories/api_study_repositories.dart` |
| `presentation/pages/study_page.dart` | StudyController cùng thư mục | `study_controller.dart` |
| `presentation/pages/study_page.dart` | enum StudyMode | `../../domain/enums/study_mode.enum.dart` |
| `presentation/widgets/study_task_section.dart` | FlashcardSessionView | `flashcard/flashcard_session_view.dart` |
| `presentation/widgets/study_task_section.dart` | StudyModeCard | `study_mode_card.dart` |
| `presentation/widgets/study_header_banner.dart` | enum StudyMode | `../../domain/enums/study_mode.enum.dart` |
| `presentation/widgets/study_mode_toggle.dart` | enum StudyMode | `../../domain/enums/study_mode.enum.dart` |
| `presentation/pages/study_controller.dart` | API repository | `../../data/repositories/api_study_repositories.dart` |
| `presentation/pages/study_controller.dart` | enum StudyMode | `../../domain/enums/study_mode.enum.dart` |
| `presentation/widgets/flashcard/flashcard_session_view.dart` | widget cùng thư mục | `flashcard_action_buttons.dart`, `flashcard_flipper_card.dart`, `flashcard_header_progress.dart` |

### Các import mismatch cần kiểm tra

1. `study_page.dart` không được dùng `../data/...`: từ `presentation/pages`, path đó trỏ nhầm vào `presentation/data`. Path đúng là `../../data/...`.
2. `study_page.dart` không được dùng `../controllers/study_controller.dart` vì hiện không có folder `presentation/controllers`. Controller thật đang ở `presentation/pages/study_controller.dart`; dùng `study_controller.dart` hoặc chuyển file rồi cập nhật mọi import.
3. Tên repository thật là `api_study_repositories.dart` số nhiều. Import `api_study_repository.dart` số ít sẽ lỗi nếu chưa đổi tên file.
4. Không trộn tùy tiện package import và relative import trong cùng một dependency graph. Ưu tiên package import `package:questlex/...` cho các module feature; relative import chỉ dùng nhất quán trong cùng thư mục.
5. `StudyPage` phải truyền đúng tham số `words` và `onReview` cho phiên bản `StudyTaskSection` hiện tại.

## 8. Quan hệ với module khác

`MainShellPage` mở module bằng:

```dart
import '../../../study/presentation/pages/study_page.dart';
```

`learning_vocab` có thể truyền các từ đã chọn vào:

```text
learning_vocab
  └─ selected words
      └─ StudyPage(initialWords: ...)
          └─ StudyController
              └─ StudyTaskSection
                  └─ FlashcardSessionView
```

Nếu không truyền `initialWords`, `StudyController` tự gọi API `/api/flashcards`.

## 9. Trạng thái hiện tại

Đã có:

- Study / Practice mode.
- Tải queue từ API hoặc nhận queue từ ngoài.
- Review Flashcard gửi về backend.
- Màn Flashcard và các widget con.
- Transition cho Flashcard, Matching và Typing.

Còn cần hoàn thiện:

- Sửa các import mismatch được liệt kê ở trên.
- Điều hướng thật tới Matching và Typing page.
- Dùng `FlashcardPage` thống nhất thay vì điều hướng trực tiếp tới `FlashcardSessionView`.
- Kết nối Golden Hour / EXP với state hoặc service thật.
- Thêm test cho controller, import contract, chuyển mode và review API.

## Kết luận

`study` hiện gồm ba lớp chính:

- `data`: gọi API lấy từ và gửi kết quả review.
- `domain`: enum cho mode và loại task.
- `presentation`: controller, page, task card, Flashcard UI và transition.

Khi sửa lỗi import, cần ưu tiên **tên file thực tế**, **vị trí file hiện tại** và **độ sâu của relative path**. Không tạo thêm folder `controllers` hoặc đổi số ít / số nhiều của repository nếu chưa cập nhật toàn bộ import liên quan.

Hiện tại bước 6 vẫn chưa hoàn tất vì các callback điều hướng đang chứa `TODO`.

## 2. domain/

Chứa các kiểu dữ liệu dùng để biểu diễn lựa chọn trong workflow học.

### 2.1 enums/

- `study_mode.enum.dart`
  - Khai báo `StudyMode` với hai giá trị:
    - `study`: chế độ học chính, hướng tới tích lũy EXP / Mastery.
    - `practice`: chế độ luyện tập / sinh tồn vô hạn.
  - Được sử dụng bởi `StudyPage`, `StudyModeToggle` và `StudyHeaderBanner`.

- `study_task_type.enum.dart`
  - File hiện tồn tại nhưng đang rỗng.
  - Chưa có enum đại diện cho loại bài học như Flashcard, Matching Card hoặc Typing Word.
  - Có thể bổ sung sau để thay thế việc nhận diện task bằng callback và cấu hình thủ công.

## 3. presentation/pages/

### `study_page.dart`

Màn hình chính của module học tập.

- Là `StatefulWidget` vì cần lưu mode hiện tại.
- State chính:
  - `currentMode`: mode đang chọn, mặc định là `StudyMode.study`.
  - `isGoldenHour`: trạng thái giờ vàng, hiện đang hard-code `true`.
  - `expMultiplier`: hệ số EXP, hiện đang hard-code `1.5`.
- Thành phần giao diện:
  - `StudyModeToggle`: chuyển giữa Study và Practice.
  - `StudyHeaderBanner`: banner thay đổi theo mode.
  - `StudyTaskSection`: danh sách các hình thức luyện tập.
- Layout dùng `SingleChildScrollView`, phù hợp với nội dung dọc và màn hình nhỏ.
- Chưa có repository, controller hoặc service riêng; state đang được quản lý cục bộ bằng `setState`.

## 4. presentation/widgets/

### `study_mode_toggle.dart`

Thanh chuyển mode giữa hai lựa chọn:

- `STUDY (HỌC TẬP)`:
  - Dùng icon huy hiệu.
  - Màu nhấn đỏ đậm.
- `PRACTICE (LUYỆN TẬP)`:
  - Dùng icon vô hạn.
  - Màu nhấn cam đậm.
- Nhận `currentMode` và callback `onModeChanged` từ trang cha.
- Dùng `AnimatedContainer` để tạo hiệu ứng chuyển trạng thái.

### `study_header_banner.dart`

Banner thông tin phía trên danh sách bài học.

- Khi mode là `study`:
  - Hiển thị trạng thái Giờ vàng nếu `isGoldenHour = true`.
  - Hiển thị hệ số EXP qua `expMultiplier`.
  - Mô tả mục tiêu học bài mới, mở khóa Mastery và tích lũy EXP.
- Khi mode là `practice`:
  - Hiển thị banner dành cho chế độ sinh tồn / luyện tập vô hạn.
  - Dùng màu cam và nội dung khác với mode Study.
- Component chỉ hiển thị thông tin; chưa tự quản lý dữ liệu Giờ vàng hoặc EXP.

### `study_task_section.dart`

Khu vực hiển thị các lựa chọn bài luyện.

- Tự thay đổi layout theo chiều rộng:
  - Desktop: 3 cột.
  - Màn hình hẹp: 1 cột.
- Quản lý `OverlayEntry` để hiển thị transition phủ toàn màn hình.
- Có ba task:
  - Flash Card.
  - Matching Card.
  - Typing Word.
- Mỗi task gọi transition riêng trước khi thực hiện callback điều hướng.
- Các callback điều hướng hiện để `TODO`:
  - `FlashcardPage`.
  - `MatchingCardPage`.
  - `TypingWordPage`.

### `study_mode_card.dart`

Card tương tác dùng trong `StudyTaskSection`.

- Nhận title, description, icon, màu chủ đề và callback `onDoubleClick`.
- Theo dõi hover trên desktop bằng `MouseRegion`.
- Khi hover:
  - Card phóng to nhẹ.
  - Border sáng hơn.
  - Hiển thị glow shadow.
- Tự phát hiện double-click bằng khoảng thời gian 300ms giữa hai lần tap.
- Chỉ kích hoạt hành động sau double-click, không phải single-click.

### `study_task_card.dart`

Một biến thể card đơn giản hơn cho task học.

- Nhận title, description, icon, themeColor và `onTap`.
- Hiển thị dạng hàng ngang với icon, nội dung và mũi tên.
- Hiện chưa được `StudyTaskSection` sử dụng; có thể là component cũ hoặc phương án UI thay thế.

## 5. presentation/widgets/transitions/

Các widget trong thư mục này là overlay animation trung gian. Chúng nhận callback `onComplete`; khi animation kết thúc, callback sẽ xóa overlay và gọi logic điều hướng từ `StudyTaskSection`.

### `flashcard_transition.dart`

- Dùng `AnimationController` thời lượng 1000ms.
- Kết hợp:
  - Flip quanh trục Y.
  - Scale card từ kích thước ban đầu lên rất lớn.
- Hiển thị card đỏ với icon Flashcard trên nền tối mờ.
- Kết thúc animation bằng cách gọi `onComplete`.

### `matching_transition.dart`

- Dùng Timer để tạo hiệu ứng các chip từ vựng xuất hiện nhanh.
- Tạo khoảng 380 chip từ một pool từ khóa cố định.
- Sau đó xóa chip theo thứ tự ngẫu nhiên bằng scale và opacity.
- Hủy các timer trong `dispose` để tránh timer chạy sau khi widget bị hủy.
- Khi chip biến mất hết, gọi `onComplete`.

### `word_fill_transition.dart`

- Tạo các dải chữ ngẫu nhiên từ pool từ vựng.
- Các dải chữ chạy ngang hoặc dọc trên nền xanh tối.
- Một số dải được đánh dấu sticky để giữ lại ở hai bên màn hình.
- Sau giai đoạn hiển thị, chạy animation split-screen tách hai nửa màn hình.
- Kết thúc bằng callback `onComplete`.

## 6. Luồng tương tác chính

```text
StudyPage
   │
   ├─ StudyModeToggle
   │     └─ setState cập nhật currentMode
   │
   ├─ StudyHeaderBanner
   │     └─ Hiển thị theo StudyMode
   │
   └─ StudyTaskSection
         └─ StudyModeCard
               ├─ Double-click Flash Card
               │     └─ FlashcardTransitionOverlay
               ├─ Double-click Matching Card
               │     └─ MatchingTransitionOverlay
               └─ Double-click Typing Word
                     └─ WordFillTransitionOverlay

Sau transition:
TODO: điều hướng tới màn hình bài học thực tế
```

## 7. Quan hệ với module khác

### `study` và `learning_vocab`

- `study`:
  - Chọn cách học.
  - Chọn mode Study / Practice.
  - Tạo trải nghiệm chuyển cảnh.
  - Dự kiến mở bài học cụ thể.

- `learning_vocab`:
  - Quản lý danh sách từ đang học.
  - Lấy dữ liệu từ repository / API.
  - Tìm kiếm, chọn nhiều từ và theo dõi tiến độ.
  - Hiển thị analytics và thống kê CEFR.

Luồng dự kiến:

```text
learning_vocab
  └─ Người dùng chọn từ cần học
        └─ study
              └─ Chọn Flashcard / Matching / Typing Word
                    └─ Màn hình bài học tương ứng
```

## 8. Trạng thái hiện tại và điểm cần hoàn thiện

- Đã có:
  - Màn hình chọn mode học.
  - Banner Study / Practice.
  - Ba lựa chọn bài luyện.
  - Animation transition riêng cho từng bài.
  - Responsive layout cơ bản cho desktop và mobile.

- Cần hoàn thiện:
  - Tạo các page thực tế: `FlashcardPage`, `MatchingCardPage`, `TypingWordPage`.
  - Thay các callback `TODO` bằng navigation thật.
  - Kết nối danh sách từ đã chọn từ `learning_vocab` vào từng bài học.
  - Đưa trạng thái Golden Hour và hệ số EXP vào service / state dùng chung thay vì hard-code.
  - Bổ sung `StudyTaskType` để quản lý task bằng kiểu enum thống nhất.
  - Xác định rõ sự khác nhau về nghiệp vụ giữa Study và Practice.
  - Thêm test cho chuyển mode, double-click và callback sau transition.

## Tổng kết

`study` hiện là presentation shell cho phần học từ vựng: nó định hình trải nghiệm, cho phép chọn mode và chọn loại bài tập. Module chưa trực tiếp thực thi logic flashcard, matching hoặc typing; các màn hình bài học và kết nối dữ liệu vẫn là phần cần phát triển tiếp.

Cấu trúc hiện tại có thể hiểu ngắn gọn như sau:

- `domain`: các enum định nghĩa lựa chọn học tập.
- `presentation/pages`: màn hình điều phối workflow.
- `presentation/widgets`: banner, toggle, card và danh sách task.
- `presentation/widgets/transitions`: animation chuyển tiếp trước khi vào bài học.
