module Adder_2bit( input wire [1:0]in_1,
                   input wire [1:0]in_2,
                   input wire bit_in,
                   output [1:0]sum_2_bit,
                   output bit_out
);
                   wire [2:0]w_full_sum;

assign w_full_sum=(in_1 + in_2 + bit_in);

assign sum_2_bit=w_full_sum[1:0];

assign bit_out=w_full_sum[2];


endmodule
 