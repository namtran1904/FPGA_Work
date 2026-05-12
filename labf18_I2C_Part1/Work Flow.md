# 🗺️ BẢN ĐỒ LẬP TRÌNH I2C MASTER (STEP-BY-STEP)

Thực hiện đúng 6 bước sau để xây dựng hoặc tái cấu trúc Module:

### BƯỚC 0: TẠO NHỊP ĐẬP (TIMING)
1. **Tick Generation:** Chia 1 chu kỳ SCL thành 4 Tick (0, 1, 2, 3).
   - `COUNT_MAX = CLK_FREQ / (I2C_FREQ * 4)`.
   - `tick` tăng khi `count` chạm `COUNT_MAX - 1`.
2. **Mục đích:** TICK 0 (Thay đổi SDA), TICK 2 (Dâng SCL để lấy mẫu).

### BƯỚC 1: TRẠNG THÁI NGHỈ (IDLE)
1. **Thiết lập:** `SCL = 1`, `sda_en = 0` (High-Z), `o_busy = 0`.
2. **Kích hoạt:** Nếu `i_start == 1`:
   - Chốt `addr` và `data` vào Buffer.
   - Nhảy sang `START`.

### BƯỚC 2: ĐIỀU KIỆN MỞ ĐẦU (START)
*Quy tắc: SDA hạ trước SCL.*
1. **Tick 1:** Kéo SDA xuống (`sda_en = 1`, `sda_out = 0`).
2. **Tick 3:** Kéo SCL xuống (`SCL = 0`).
3. **Kết thúc:** Nhảy sang `ADDR`.

### BƯỚC 3: TRUYỀN DỮ LIỆU (ADDR & WRITE_DATA)
*Lặp lại 8 bit (MSB first):*
1. **Tick 0:** `SCL = 0`. Đẩy bit ra: `sda_out = buffer[bit_idx]`.
2. **Tick 2:** `SCL = 1` (Slave đọc dữ liệu).
3. **Tick 3:** `SCL = 0`.
   - **Bàn giao sớm (Crucial):** Nếu `bit_idx == 0`, phải nhả bus ngay (`sda_en = 0`) để tránh xung đột ACK.
   - Giảm `bit_idx`. Nếu hết 8 bit, nhảy sang `ACK`.

### BƯỚC 4: KIỂM TRA PHẢN HỒI (ADDR_ACK & DATA_ACK)
1. **Xuyên suốt:** `sda_en = 0` (Master im lặng lắng nghe).
2. **Tick 2:** `SCL = 1`. Master chốt lỗi: `o_ack_error <= sda_in`. (0: OK, 1: Lỗi).
3. **Tick 3:** `SCL = 0`.
   - Nếu `o_ack_error == 1` (NACK) -> Nhảy sang `STOP`.
   - Nếu `o_ack_error == 0` (ACK) -> Nhảy sang trạng thái kế tiếp.

### BƯỚC 5: ĐIỀU KIỆN KẾT THÚC (STOP)
*Quy tắc: SCL dâng trước SDA.*
1. **Tick 0:** `SCL = 0`, Master kéo SDA xuống (`sda_en = 1`, `sda_out = 0`).
2. **Tick 1:** `SCL = 1` (Dâng SCL lên).
3. **Tick 2:** `sda_en = 0` (Nhả SDA để Pull-up kéo lên 1).
4. **Tick 3:** `o_busy = 0`. Nhảy về `IDLE`.
