# MyFinance Flutter

Ứng dụng quản lý tài chính cá nhân, ưu tiên trải nghiệm điện thoại và giao diện tiếng Việt.

## Tính năng hiện có

- Tổng quan số dư, thu nhập và chi tiêu trong tháng.
- Thêm, sửa và xóa giao dịch thu/chi.
- Lọc giao dịch theo tháng và loại giao dịch.
- Ngân sách theo danh mục với thanh tiến độ.
- Lưu dữ liệu cục bộ bằng `shared_preferences`.
- Chuyển đổi giao diện sáng/tối.

## Chạy ứng dụng

Cài Flutter SDK, sau đó từ thư mục dự án chạy:

```bash
flutter pub get
flutter run
```

Nếu chưa có thư mục nền tảng Android/iOS, tạo chúng một lần bằng `flutter create .` trước khi chạy.

## Lưu trữ

Giao dịch được lưu trên thiết bị hiện tại. Bản MVP chưa đồng bộ dữ liệu giữa các thiết bị hoặc có tài khoản người dùng.
