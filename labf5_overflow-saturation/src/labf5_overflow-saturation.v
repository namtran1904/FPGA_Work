module signed_adder(
    input wire clk, rst,
    input wire signed [3:0] a, b,
    output reg signed [3:0] final_out_saturated,
    output reg [1:0] ovr_flag
);
    parameter Non_Overflow = 2'b00, P_Overflow = 2'b01, N_Overflow = 2'b10;
    wire signed [4:0] w_full_sum = a + b;
    wire w_is_overflow = w_full_sum[4] ^ w_full_sum[3];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            final_out_saturated <= 0;
            ovr_flag <= Non_Overflow;
        end else begin
            if (!w_is_overflow) begin
                final_out_saturated <= w_full_sum[3:0];
                ovr_flag <= Non_Overflow;
            end else begin
                final_out_saturated <= w_full_sum[4] ? 4'b1000 : 4'b0111;
                ovr_flag <= w_full_sum[4] ? N_Overflow : P_Overflow;
            end
        end
    end
endmodule 
















