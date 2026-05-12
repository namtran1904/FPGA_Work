`timescale 1ns/1ps  
module tb_signed_adder();
                       reg clk;
                       reg rst;
                       reg signed[3:0]a;
                       reg signed[3:0]b;
                       wire signed[4:0]sum;
signed_adder dut(
    .clk(clk),
    .rst(rst),
    .a(a),
    .b(b),
    .sum(sum)
);

initial clk=0;

always #5 clk=~clk;

integer  i,j;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb_signed_adder);
    rst=1; a=0; b=0;
    #20
    rst=0;
    $display("--Bắt đầu stress test--");
    for(i=-8 ; i<=7 ; i=i+1)begin
        for(j=-8 ; j<=7 ; j=j+1)begin
            @(posedge clk);
            a=i;
            b=j;
            @(posedge clk);
            #1;
            if(sum !== (a+b)) begin
                $display("Lỗi! Thời gian: %0t | a = %d, b = %d | Kết quả chip = %d | Kết quả đúng = %d", $time,a,b,sum,(a+b));
            end
        end
    end
    $display("--Mô phỏng kết thúc--");
    $finish;
end

endmodule
