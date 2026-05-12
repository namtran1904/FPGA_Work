`timescale 1ns/1ps
module tb_Binary_count();
                       reg clk;
                       reg rst;
                       reg enb;
                       wire [3:0]count;


Binary_counter dut (.clk(clk),
                     .rst(rst),
                     .enb(enb),
                     .count(count)
);

initial clk=0;
always #5 clk=~clk;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb_Binary_count);
    
    //Pha Reset
    rst=1;enb=0;
    #15;
    rst=0;
    $display("T=%0t | Bat dau dem...",$time);

    //Pha cho phép đếm
    @(posedge clk)
    enb=1;
    repeat(20)@(posedge clk);

    //Pha Test tính năng enable(Freeze test)
    $display("T=%0t | Dung dem(Disable)...0",$time);
    enb=0;
    repeat(5)@(posedge clk);

    //Pha test dừng khẩn cấp
    $display("T=%0t | Reset khan cap...", $time);
    enb=1;
    repeat(3)@(posedge clk);
    rst=1;
    #5 rst=0;

    $display("-- Ket thuc mo phong--");
    $finish;
end

endmodule
