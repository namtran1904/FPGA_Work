`timescale 1ns/1ps
module tb_overflow_saturation();
                             reg clk;
                             reg rst;
                             reg signed[3:0]a;
                             reg signed[3:0]b;
                             wire signed[3:0]final_out_saturated;
                             wire [1:0]ovr_flag;

                             parameter Non_Overflow = 2'b00;
                             parameter N_Overflow = 2'b10;
                             parameter P_Overflow = 2'b01;

signed_adder dut(.clk(clk),
                 .rst(rst),
                 .a(a),
                 .b(b),
                 .final_out_saturated(final_out_saturated),
                 .ovr_flag(ovr_flag)
);

initial clk=0;
always #5 clk=~clk;

integer i,j,expected_out;
reg [1:0]expected_flag;

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0,tb_overflow_saturation);
    rst=1;a=0;b=0;
    #20;
    rst=0;
    $display("-- Bat dau test Overflow-Saturation--");
    for (i=-8 ; i<=7 ; i=i+1)begin
        for(j=-8 ; j<=7; j=j+1)begin
            @(posedge clk);
            a=i;
            b=j;
            if (i+j >7)begin
                expected_out=7;
                expected_flag=P_Overflow;
            end
            else if (i+j<-8)begin
                expected_out=-8;
                expected_flag=N_Overflow;
            end
            else begin
                expected_out=i+j;
                expected_flag=Non_Overflow;
            end
            @(posedge clk)
            #1;
            if (final_out_saturated !== expected_out || ovr_flag !== expected_flag) begin
                    $display("LOI! a=%d, b=%d | Chip=%d, Cờ=%b | Dung=%d, Cờ=%b", a, b, final_out_saturated, ovr_flag, expected_out, expected_flag);
            end
        end
    end
    $display("--- HOAN THANH TEST F5 ---");
    $finish;
end
endmodule







