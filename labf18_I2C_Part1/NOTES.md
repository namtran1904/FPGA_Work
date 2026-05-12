# 📝 GHI CHÚ KỸ THUẬT NẰM LÒNG

1. **Triết lý nhả Bus:** SDA là đường dây chung. Khi không xuất mức 0, Master phải dùng `1'bz` (thông qua `sda_en = 0`). Việc đẩy mạnh `1'b1` sẽ gây cháy chập nếu Slave đang kéo xuống 0.
2. **Tính thời điểm:** 
   - Thay đổi SDA khi SCL thấp (TICK 0).
   - Lấy mẫu SDA khi SCL cao (TICK 2).
3. **Độ trễ Testbench:** Task truyền dữ liệu trong Testbench nên có khoảng nghỉ (`#delay`) giữa các lần gọi để Master kịp hoàn tất chu kỳ `STOP` vật lý.
