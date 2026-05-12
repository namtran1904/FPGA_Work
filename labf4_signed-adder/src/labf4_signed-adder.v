module signed_adder(input wire clk,
                    input wire rst,
                    input wire signed [3:0]a,
                    input wire signed [3:0]b,
                    output reg signed [4:0]sum
);
always@(posedge clk or posedge rst)begin
    if (rst) begin
        sum <= 0;
    end
    else begin
    sum <= a + b;
    end
end
endmodule
