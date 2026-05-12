`timescale 1ns/1ps
module Test_Bench();
                  reg tb_clk;
                  reg tb_rst;
                  reg tb_start;
                  wire tb_busy;
                  wire tb_SCL;
                  wire tb_sda_bus;
                  wire tb_o_ack_error;
                  reg [6:0]tb_addr;
                  reg [7:0]tb_data;

I2C_V1_0 dut(
    .i_clk(tb_clk),
    .i_rst(tb_rst),
    .i_start(tb_start),
    .o_busy(tb_busy),
    .SCL(tb_SCL),
    .SDA(tb_sda_bus),
    .data(tb_data),
    .addr(tb_addr),
    .o_ack_error(tb_o_ack_error)
);

pullup(tb_sda_bus);
reg sda_drive_low = 0;
assign tb_sda_bus = (sda_drive_low)? 0 : 1'bz;

initial begin // Logic slave ACK
    sda_drive_low = 0;
    forever begin
        @(negedge tb_sda_bus) begin
            if(tb_SCL == 1) begin
                repeat(8) @(posedge tb_SCL);

                @(negedge tb_SCL);
                sda_drive_low = 1;
                @(negedge tb_SCL);
                sda_drive_low = 0;

                repeat(8) @(posedge tb_SCL);

                @(negedge tb_SCL);
                sda_drive_low = 1;
                @(negedge tb_SCL);
                sda_drive_low = 0;
            end
        end
    end
end

task Send_byte(input[7:0]i_data,input[6:0]i_addr);
     begin
        @(negedge tb_clk);
        tb_data = i_data;
        tb_addr = i_addr;

        @(posedge tb_clk);
        tb_start = 1;
        @(posedge tb_clk);
        tb_start = 0;

        wait(tb_busy);
        $display("[%0t] Master bat dau gui: Addr=%h, Data=%h", $time, i_addr, i_data);

        wait(!tb_busy);
        $display("[%0t] Master da hoan thanh chu ky truyenn.", $time);
        if (tb_o_ack_error == 1'b0) begin
        $display("[%0t] CHUC MUNG: Slave da phan hoi ACK, truyen du lieu %h thanh cong!", $time, i_data);
    end 
    else begin
        $display("[%0t] CANH BAO: Loi NACK! Slave khong ton tai hoac khong phan hoi.", $time);
    end

        repeat(10)@(posedge tb_clk);

     end
endtask

integer i;
reg[7:0]rand_data;

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
    for (i=0;i<10;i=i+1)begin
        rand_data=$urandom % 256;
        Send_byte(rand_data,7'h68);
    
      #50000;
    end

    $display("[%0t] Mo phong ket thuc",$time);
    $finish;
end

endmodule
