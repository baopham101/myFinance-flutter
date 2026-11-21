# MyFinance Flutter

Ứng dụng Flutter mobile-first dùng chung tài khoản, dữ liệu và chính sách bảo mật Supabase với bản web MyFinance.

## Tính năng

- Đăng nhập, đăng ký và đặt lại mật khẩu qua Supabase Auth.
- Dashboard số dư, thu/chi tháng, dòng tiền 6 tháng, cơ cấu chi tiêu và giao dịch gần đây.
- Giao dịch thu, chi và chuyển khoản giữa ví; sửa, tìm kiếm, lọc và xóa mềm.
- Quản lý ví, số dư ban đầu và số dư tính từ giao dịch.
- Quản lý danh mục thu/chi.
- Ngân sách có danh mục, hạn mức, ngày bắt đầu/kết thúc và tiến độ từ giao dịch.
- Báo cáo theo khoảng ngày gồm thu nhập, chi tiêu, chuyển khoản, chênh lệch và phân loại chi phí.
- Household: tạo nhóm, mời thành viên, nhận lời mời, xem thành viên và rời nhóm.
- Giao diện sáng/tối/theo thiết bị, thanh điều hướng mobile, rail điều hướng màn hình rộng.

## Cấu trúc mã

- `lib/app`: MaterialApp, khởi tạo cấu hình.
- `lib/core`: theme, định dạng tiền và widget dùng chung.
- `lib/features/auth`: xác thực và cổng đăng nhập.
- `lib/features/finance/data`: model và truy cập Supabase.
- `lib/features/finance/screens`: từng màn hình độc lập.
- `lib/features/finance/widgets`: form và thành phần giao dịch tái sử dụng.
- `lib/features/dashboard/widgets`: biểu đồ dashboard.

## Cấu hình và chạy

Cần dùng URL và public anon/publishable key của cùng Supabase project với MyFinance Web. Lấy từ `.env.local` bản web; không dùng `service_role` key. Chạy:

```bash
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<public-anon-key>
```

Database migrations cần được áp dụng trên Supabase project. Household, soft-delete, số dư ví, ghi giao dịch atomic và budget progress dùng RPC/RLS của bản web.
