`timescale 1ns/1ps
module tb_imu_system();
    reg i_clk;
    reg i_rst;
    reg i_stm_start;
    reg i_stm_rw;
    reg [7:0] i_stm_reg_addr;
    reg [7:0] i_stm_data_in;

    wire [111:0] o_imu_data; // 14 byte * 8
    wire o_data_valid;

    // Các tín hiệu kết nối nội bộ giữa Controller và Driver
    wire [6:0] i2c_addr;
    wire [7:0] i2c_data_tx;
    wire [7:0] i2c_data_rx;
    wire i2c_start;
    wire i2c_busy;
    wire ack_error;
    wire i2c_rw;
    wire i2c_repeat;
    wire i2c_stop;

    // Bus I2C Vật lý
    wire SCL;
    wire SDA;

    // Trở kéo lên (Pull-up) cho mô phỏng
    pullup(SDA);
    pullup(SCL);

    // 2. Khởi tạo 2 Module
    IMU_Controller u_controller (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_stm_start(i_stm_start),
        .i_stm_rw(1'b1), // Đọc
        .i_stm_reg_addr(8'h00),
        .i_stm_data_in(8'h00),
        .o_i2c_addr(i2c_addr),
        .o_i2c_data(i2c_data_tx),
        .i_i2c_data(i2c_data_rx),
        .o_i2c_start(i2c_start),
        .i_i2c_busy(i2c_busy),
        .i_ack_error(ack_error),
        .o_i2c_rw(i2c_rw),
        .o_i2c_repeat(i2c_repeat),
        .o_i2c_stop(i2c_stop),
        .o_imu_data(o_imu_data),
        .o_data_valid(o_data_valid)
    );

    I2C_DRIVER u_driver (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_start(i2c_start),
        .o_busy(i2c_busy),
        .o_ack_error(ack_error),
        .i_rw_bit(i2c_rw),
        .i_cmd_repeat(i2c_repeat),
        .i_cmd_stop(i2c_stop),
        .SCL(SCL),
        .SDA(SDA),
        .data(i2c_data_tx),
        .addr(i2c_addr),
        .o_rx_data(i2c_data_rx)
    );


    initial begin
        i_clk = 0;
        forever #18.5 i_clk = ~i_clk; 
    end


    // Mô phỏng MPU6050 (I2C Slave)
    reg sda_drive;
    assign SDA = sda_drive ? 1'bz : 1'b0;

    integer i, b;
    reg [7:0] rx_byte;
    reg [7:0] slave_send_data;

    initial begin
        sda_drive = 1; // Mặc định nhả bus
        slave_send_data = 8'h01; 

        forever begin
            // Đợi điều kiện START 
            wait(SCL == 1 && SDA == 0);
            
            // 1. Nhận Address + R/W bit (8 bit)
            for (i=7; i>=0; i=i-1) begin
                @(posedge SCL); rx_byte[i] = SDA;
            end
            
            // Phản hồi ACK cho Address
            @(negedge SCL); sda_drive = 0; 
            @(negedge SCL); sda_drive = 1;

            if (rx_byte[0] == 0) begin
                // CHẾ ĐỘ MASTER WRITE 
                // Nhận Data 
                for (i=7; i>=0; i=i-1) @(posedge SCL);
                
                // Phản hồi ACK cho Data
                @(negedge SCL); sda_drive = 0;
                @(negedge SCL); sda_drive = 1;
            end 
            else begin
                for (i = 0; i < 14; i = i + 1) begin
                    // Slave gửi 8 bit dữ liệu
                    for (b = 7; b >= 0; b = b - 1) begin
                        @(negedge SCL); sda_drive = slave_send_data[b];
                    end
                    
                    // Nhả bus đợi Master ACK/NACK
                    @(negedge SCL); sda_drive = 1;
                    
                    @(posedge SCL); // Kiểm tra bit Master gửi
                    if (SDA == 1) begin
                        $display("[%0t] Slave nhan NACK. Ngung gui.", $time);
                        slave_send_data = 8'h01; // Reset data mẫu
                        i=14; // Thoát vòng lặp nếu nhận NACK
                    end
                    
                    slave_send_data = slave_send_data + 1; 
                end
            end
        end
    end


    initial begin
        $dumpfile("imu_system.vcd");
        $dumpvars(0, tb_imu_system);

        // Khởi tạo
        i_rst = 1;
        i_stm_start = 0;
        
        #200;
        i_rst = 0;
        #1000;

        $display("-------------------------------------------------");
        $display("[%0t] STM32: Phat lenh Start cho FPGA...", $time);
        
        // Kích hoạt Controller
        @(posedge i_clk);
        i_stm_start = 1;
        @(posedge i_clk);
        i_stm_start = 0;

        // Chờ dữ liệu trả về
        wait(o_data_valid);
        
        $display("[%0t] STM32: Da nhan duoc du lieu tu FPGA!", $time);
        $display("Du lieu 14 byte thu duoc (Hex): %h", o_imu_data);
        $display("Ky vong (Hex): 0102030405060708090a0b0c0d0e");
        
        if (o_imu_data === 112'h0102030405060708090a0b0c0d0e)
            $display("=> KET QUA: PASSED! Logic Index và Dich Byte hoan hao!");
        else
            $display("=> KET QUA: FAILED!");
            
        $display("-------------------------------------------------");

        #50000;
        $finish;
    end

endmodule
