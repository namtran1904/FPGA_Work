# I2C Master Core v1.0 (Single-byte Write)

## 1. Giới thiệu
Module thực hiện giao thức I2C Master cơ bản để giao tiếp với các ngoại vi (Sensor, EEPROM...). Phiên bản v1.0 hỗ trợ ghi 1 byte dữ liệu vào 1 địa chỉ thiết bị.

## 2. Thông số kỹ thuật
- **Nền tảng:** FPGA Gowin (Tang Primer 20k).
- **Tần số hệ thống:** 27 MHz.
- **Tốc độ I2C:** 100 kHz (Standard Mode).
- **Cơ chế điều khiển:** Tick-based (4 Ticks per SCL Period).

## 3. Sơ đồ cổng (I/O)
| Tín hiệu | Hướng | Mô tả |
| :--- | :--- | :--- |
| i_clk | Input | Clock hệ thống 27MHz |
| i_rst | Input | Reset hệ thống (Active High) |
| i_start | Input | Xung kích hoạt truyền (1 clock) |
| addr[6:0] | Input | Địa chỉ thiết bị Slave |
| data[7:0] | Input | Dữ liệu cần gửi |
| o_busy | Output | Báo bận (1: Đang truyền, 0: Rảnh) |
| o_ack_error | Output | 1: NACK (Lỗi), 0: ACK (Thành công) |
| SCL/SDA | Inout | Đường dây Bus I2C (Cần Pull-up ngoài) |
