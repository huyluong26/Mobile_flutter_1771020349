## 🚀 Tính Năng Nổi Bật

### 📱 Dành cho Người dùng (Mobile App)
*   **Đặt Sân Thông Minh:**
    *   Xem lịch trống trực quan (Timeline view).
    *   Đặt sân nhanh chóng và thanh toán qua ví.
    *   Quản lý lịch sử đặt sân.
*   **Giải Đấu Chuyên Nghiệp:**
    *   Đăng ký tham gia giải đấu.
    *   Theo dõi lịch thi đấu và kết quả.
*   **Ví Điện Tử Tích Hợp:**
    *   Nạp tiền qua chuyển khoản (upload bill).
    *   Xem lịch sử biến động số dư.

### 🛠️ Dành cho Quản Trị Viên (Admin)
*   **Quản Lý Tài Nguyên:** Thêm/Sửa/Xóa sân bãi.
*   **Duyệt Giao Dịch:** Xác nhận các yêu cầu nạp tiền từ người dùng.
*   **Quản Lý Giải Đấu:** Tạo giải, sắp xếp lịch thi đấu.

---

## 🛠️ Yêu Cầu Hệ Thống

*   **Flutter SDK:** Phiên bản 3.0 trở lên.
*   **NET SDK:** Phiên bản 8.0.
*   **Database:** MySQL hoặc MariaDB.
*   **IDE:** Visual Studio Code hoặc Visual Studio.

---

## 📦 Hướng Dẫn Cài Đặt & Chạy Ứng Dụng

### 1. Khởi Chạy Backend (Server)

Backend được viết bằng **ASP.NET Core Web API**.

1.  **Mở terminal** và di chuyển vào thư mục backend:
    ```bash
    cd backend
    ```

2.  **Cấu hình Database:**
    *   Mở file `appsettings.json`.
    *   Chỉnh sửa `ConnectionStrings:DefaultConnection` để phù hợp với thông tin MySQL của bạn (Host, User, Password).

3.  **Khởi tạo Database (Migrations):**
    ```bash
    dotnet ef database update
    ```

4.  **Chạy Server:**
    ```bash
    dotnet run
    ```
    *   Backend sẽ khởi chạy tại: `http://localhost:5017` (hoặc `http://0.0.0.0:5017`).

### 2. Khởi Chạy Mobile App

Ứng dụng di động được xây dựng bằng **Flutter**.

1.  **Mở terminal mới** và di chuyển vào thư mục mobile_app:
    ```bash
    cd mobile_app
    ```

2.  **Cấu hình API URL:**
    *   Mở file `lib/services/api_service.dart`.
    *   Hệ thống đã tự động cấu hình:
        *   **Android Emulator:** `10.0.2.2:5017`
        *   **Windows/Web/iOS:** `127.0.0.1:5017`
    *   *Nếu bạn chạy App trên điện thoại thật, hãy thay đổi IP về địa chỉ LAN của máy tính đang chạy Backend (ví dụ: `192.168.1.x`).*

3.  **Cài đặt thư viện:**
    ```bash
    flutter pub get
    ```

4.  **Chạy ứng dụng:**
    ```bash
    # Chạy trên Windows
    flutter run -d windows

    # Chạy trên Android Emulator (cần bật giả lập trước)
    flutter run -d android
    ```

---

## 🔐 Tài Khoản Demo (Mặc định)

Khi khởi tạo database lần đầu, hệ thống sẽ tạo sẵn các tài khoản sau:


| **Admin** | `admin` | `Admin@123` |
| **User** | `user` | `User@123` |

---

