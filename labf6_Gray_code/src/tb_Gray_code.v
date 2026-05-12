`timescale 1ns/1ps
module tb_Gray_code();
                   reg clk;
                   reg rst;
                   wire [3:0]bin_count;
                   wire [3:0]gray_count;
Gray_count dut(.clk(clk),
               .rst(rst),
               .bin_count(bin_count),
               .gray_count(gray_count));

initial clk=0;
always #5 clk=~clk;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb_Gray_code);

    $display("--Bat dau mo phong--");

    rst=1;
    #20;
    rst=0;
    
    repeat(20)@(posedge clk);

    $display("--Ket thuc mo phong--");
    $finish;

end
endmodule
