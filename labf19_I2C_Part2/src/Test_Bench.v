`timescale 1ns/1ps
module Test_Bench();
                  reg tb_clk;
                  reg tb_rst;
                  reg tb_start;
                  reg tb_stop_enable;
                  reg tb_rw_bit;
                  wire tb_busy;
                  wire tb_SCL;
                  wire tb_sda_bus;
                  wire tb_o_ack_error;
                  reg [6:0]tb_addr;
                  reg [7:0]tb_data;
                  wire [7:0] tb_rx_data;

I2C_V1_1 dut(
    .i_clk(tb_clk),
    .i_rst(tb_rst),
    .i_start(tb_start),
    .i_stop_enable(tb_stop_enable),
    .i_rw_bit(tb_rw_bit),
    .o_busy(tb_busy),
    .SCL(tb_SCL),
    .SDA(tb_sda_bus),
    .data(tb_data),
    .addr(tb_addr),
    .o_rx_data(tb_rx_data),
    .o_ack_error(tb_o_ack_error)
);

pullup(tb_sda_bus);
reg sda_drive_low = 0;
assign tb_sda_bus = (sda_drive_low)? 0 : 1'bz;

integer i;
reg[7:0]rand_data;

initial begin 
    sda_drive_low = 0;
    forever begin
        wait(tb_SCL == 1 && tb_sda_bus == 0); 

        // Slave gửi ACK
        repeat(9) @(negedge tb_SCL);
        sda_drive_low = 1;
        @(negedge tb_SCL);
        sda_drive_low = 0;

        // kiểm tra bit rw - Master Read mode
        if(tb_rw_bit == 1)begin
            rand_data = $urandom % 256;
            for(i = 7; i>= 0; i=i-1)begin
                sda_drive_low = (rand_data[i] == 0);
                @(negedge tb_SCL);
            end
            sda_drive_low = 0;
            @(negedge tb_SCL);
        end
        else begin // Master Write mode
                repeat(8) @(posedge tb_SCL);

                sda_drive_low = 1;
                @(negedge tb_SCL);
                sda_drive_low = 0;
            end
        end
    end

task Master_Write(input[7:0]i_data,input[6:0]i_addr, input i_stop);
     begin
        @(negedge tb_clk);
        tb_data = i_data;
        tb_addr = i_addr;
        tb_stop_enable = i_stop;
        tb_rw_bit = 0;

        @(posedge tb_clk);
        tb_start = 1;
        @(posedge tb_clk);
        tb_start = 0;

        wait(tb_busy);
        $display("[%0t] Master bat dau ghi: Addr=%h, Data=%h", $time, i_addr, i_data);

        wait(!tb_busy);
        $display("[%0t] Master da hoan thanh chu ky truyenn.", $time);

        repeat(10)@(posedge tb_clk);

     end
endtask

task Master_Read(input[6:0]i_addr, input i_stop);
    begin
        @(negedge tb_clk);
        tb_addr = i_addr;
        tb_stop_enable = i_stop;
        tb_rw_bit = 1;

        @(posedge tb_clk);
        tb_start = 1;
        @(posedge tb_clk);
        tb_start = 0;

        wait(tb_busy);
        $display("[%0t] Master bat dau doc: Addr=%h", $time, i_addr);

        wait(!tb_busy);
        $display("[%0t] Master da hoan thanh chu ky doc. Du lieu nhan đuoc: %h", $time, tb_rx_data);
        repeat(10)@(posedge tb_clk);

    end
endtask

initial tb_clk = 0;
always #18.5 tb_clk=~tb_clk;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,Test_Bench);

    tb_rst = 1; tb_start = 0; 
    #10000;
    tb_rst = 0;
    #10000;

    $display("[%0t] Bat dau stress test", $time);
    repeat(5) Master_Write($urandom%256,7'h68,1);

    #50000;

    repeat(5) Master_Read(7'h68,1);

    #50000;

    $display("[%0t] Mo phong ket thuc",$time);
    $finish;
end

endmodule

