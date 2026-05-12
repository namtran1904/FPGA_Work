# 🐞 NHẬT KÝ BUG & FIX

### Bug 01: Race Condition đầu Start
- **Hiện tượng:** Bit MSB của địa chỉ bị màu đỏ (X) trên GTKWave.
- **Nguyên nhân:** Testbench gán `addr` cùng lúc với `i_start`. Module chốt dữ liệu hụt.
- **Giải pháp:** Trong Testbench, gán dữ liệu tại `negedge tb_clk` để đảm bảo Setup Time cho FPGA.

### Bug 02: Deadlock (Treo Simulation)
- **Hiện tượng:** Testbench đứng đợi `wait(!tb_busy)` mãi mãi.
- **Nguyên nhân:** Logic thoát FSM từ `STOP` về `IDLE` quá nhanh khiến `o_busy` chưa kịp xóa về 0.
- **Giải pháp:** Ép `o_busy <= 0` ngay trong khối `state == IDLE`.

### Bug 03: Bus Contention (Xung đột bit thứ 9)
- **Hiện tượng:** Vệt đỏ (X) xuất hiện tại nhịp ACK.
- **Nguyên nhân:** Master vẫn giữ `sda_en = 1` trong khi Slave bắt đầu kéo bus xuống 0.
- **Giải pháp:** Cơ chế **Early Release** - Nhả `sda_en <= 0` ngay tại `TICK 3` của bit cuối cùng (`bit_idx == 0`).
