# NookBook – Frontend Flutter (khung dự án)

## 1. Cài đặt lần đầu (Windows)

1. Cài **Flutter SDK** theo hướng dẫn https://docs.flutter.dev/get-started/install/windows
   và chạy `flutter doctor` cho đến khi không còn lỗi đỏ ở phần bạn cần.
   - Chỉ cần **Chrome** là chạy được bản web, chưa cần Android Studio.
2. Giải nén thư mục này, mở bằng VS Code (cài extension **Flutter** + **Dart**).
3. Mở terminal trong thư mục dự án và chạy:

```bash
flutter create --project-name nookbook .   # sinh các thư mục android/ ios/ web/ windows/
flutter pub get
flutter run -d chrome
```

4. Xóa file `test/widget_test.dart` do `flutter create` sinh ra (nó tham chiếu MyApp cũ, sẽ báo lỗi).

> `flutter create .` KHÔNG ghi đè `lib/` và `pubspec.yaml` đã có.

## 2. Chạy với dữ liệu giả hay backend thật

Mặc định app dùng **dữ liệu giả** (`AppConfig.useMock = true`), nên frontend chạy được
ngay cả khi chưa có backend.

```bash
flutter run -d chrome                                   # dữ liệu giả
flutter run -d chrome --dart-define=USE_MOCK=false      # backend thật (localhost:8088)
flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://192.168.1.10:8088/api   # máy thật
```

Khi dùng backend thật cần lưu ý:
- **Android emulator**: dùng `10.0.2.2` thay cho `localhost` (đã xử lý sẵn trong `app_config.dart`).
  Thêm `android:usesCleartextTraffic="true"` vào thẻ `<application>` trong
  `android/app/src/main/AndroidManifest.xml` vì backend chạy `http` (không phải `https`).
- **Flutter Web**: backend Spring phải bật **CORS** cho origin của Flutter, nếu không trình duyệt chặn request.
- Mở Swagger `http://localhost:8088/api/swagger-ui/index.html` để đối chiếu tên field,
  rồi sửa `Book.fromJson`, `BookCategory.fromJson`, `ApiAuthRepository`, tham số `/books/search`.

## 3. Cấu trúc thư mục

```
lib/
  main.dart, app.dart          khởi động app, gắn theme + router
  core/
    config/app_config.dart     URL backend, bật/tắt mock, phí ship, tài khoản ngân hàng minh họa
    theme/                     màu + theme
    router/                    go_router: đường dẫn, chặn trang cần đăng nhập / chỉ admin
    network/                   Dio (tự gắn JWT), lưu token, xử lý lỗi
    utils/                     formatters (giá, ngày, mã đơn), jwt_utils (đọc quyền trong token)
    widgets/                   widget dùng chung: toast, dialog xác nhận, bottom sheet, skeleton, chip...
  features/
    auth/          đăng nhập (tab Người dùng / Quản trị viên), đăng ký
    home/          màn 01 + 40 (skeleton)
    categories/    màn 02
    books/         màn 03, 06, 07, 08 + model, repository, bộ lọc / sắp xếp
    search/        màn 04, 05
    favorites/     màn 09 (lưu trong máy, backend chưa có API)
    cart/          màn 10, 11, 12
    checkout/      màn 13, 14, 15, 16
    orders/        màn 17, 18
    account/       màn 19, 24 + hồ sơ lưu trong máy
    notifications/ màn 25, 26, 27 (suy ra từ đơn hàng)
    admin/         màn 30-39 (tổng quan, sách, biểu mẫu sách, danh mục, đơn hàng)
```

## 4. Đối chiếu 40 ảnh thiết kế với code

| Ảnh | Màn | File |
|---|---|---|
| 01, 40 | Trang chủ, đang tải | features/home/presentation/home_page.dart |
| 02 | Thể loại | features/categories/presentation/categories_page.dart |
| 03, 06, 07 | Tủ sách, bộ lọc, sắp xếp | features/books/presentation/book_list_page.dart + widgets/filter_sheet.dart |
| 04, 05 | Kết quả / không có kết quả | features/search/presentation/search_page.dart |
| 08, 28, 29 | Chi tiết sách + toast thêm giỏ / lỗi | features/books/presentation/book_detail_page.dart |
| 09 | Sách yêu thích | features/favorites/presentation/favorites_page.dart |
| 10, 11, 12 | Giỏ hàng / trống / xác nhận xóa | features/cart/presentation/cart_page.dart |
| 13, 14 | Thanh toán, chọn phương thức | features/checkout/presentation/checkout_page.dart |
| 15 | Chuyển khoản | features/checkout/presentation/bank_transfer_page.dart |
| 16 | Đặt hàng thành công | features/checkout/presentation/order_success_page.dart |
| 17, 18 | Danh sách / chi tiết đơn | features/orders/presentation/ |
| 19, 24 | Tài khoản, xác nhận đăng xuất | features/account/presentation/account_page.dart |
| 20, 21 | Đăng nhập người dùng / quản trị | features/auth/presentation/login_page.dart |
| 22, 23 | Đăng ký, lỗi biểu mẫu | features/auth/presentation/register_page.dart |
| 25, 26, 27 | Thông báo | features/notifications/presentation/ |
| 30 | Quản trị · Tổng quan | features/admin/presentation/admin_dashboard_page.dart |
| 31, 32, 35 | Quản lý / tìm kiếm / xóa sách | features/admin/presentation/admin_books_page.dart |
| 33, 34 | Thêm / sửa sách | features/admin/presentation/admin_book_form_page.dart |
| 36, 37 | Danh mục, thêm/sửa danh mục | features/admin/presentation/admin_categories_page.dart |
| 38, 39 | Quản lý đơn, đổi trạng thái | features/admin/presentation/admin_orders_page.dart |

## 5. Những chỗ giao diện đi trước backend (cần chốt với người làm backend)

- **Trạng thái đơn**: `lib/features/orders/domain/order.dart` -> `orderStatusApiValues` đang giả định
  `PENDING / SHIPPED / DELIVERED`. Đối chiếu enum thật trong Swagger rồi sửa.
- **Danh sách đơn của admin**: README backend chỉ có `GET /orders` (lịch sử của người đăng nhập).
  Muốn admin thấy đơn của mọi khách cần thêm API.
- **Cập nhật giỏ**: app gọi `PUT /cart/items/{id}` body `{"quantity": n}` (README ghi nhầm GET).
- **Không có ở backend, nên chỉ lưu trong máy / tính ở app**: sách yêu thích, SĐT và tên người nhận
  (ghép vào `shippingAddress` dạng "Tên · SĐT · Địa chỉ"), ghi chú đơn, phương thức thanh toán,
  phí giao hàng (25.000 ₫, miễn phí từ 300.000 ₫), thông báo.
- **Đã bỏ khỏi thiết kế vì backend không có dữ liệu**: tồn kho / "Còn hàng" / "Đang bán", "Bán chạy nhất",
  đánh giá sao (tự ẩn khi không có), số trang / NXB, thống kê so với hôm qua.
- **Đăng nhập quản trị**: app chỉ chọn giao diện; nếu JWT có claim quyền thì app chặn người thường.
  Quyền thật luôn do backend kiểm tra (403).
- Đăng nhập Google / Facebook, quên mật khẩu: chỉ là nút, chưa có chức năng.

## 6. Mẹo

- Dữ liệu giả: đăng nhập email bắt đầu bằng `admin` ở tab Quản trị viên để vào khu quản trị.
- Lưu file là app tự cập nhật (hot reload), nhấn `r` / `R` trong terminal để reload / restart.
- Mọi màn có dữ liệu đều xử lý 3 trạng thái: đang tải, lỗi, có dữ liệu (`AsyncValue.when`).
- Đừng gọi `Dio` trong widget; thêm hàm vào repository rồi bọc bằng provider.
- Gặp lỗi build: chạy `flutter clean && flutter pub get` rồi thử lại.
