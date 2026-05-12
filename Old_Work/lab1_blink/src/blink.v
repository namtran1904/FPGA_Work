module blink(
       input clk,
       output reg led_b
);

reg [4:0]rst_counter = 5'd0;
wire rst_n;

parameter INSIDE_COUNTER = 5'd31;
parameter SYS_COUNT = 24'd1_000_000;
reg [23:0] counter;

assign rst_n=(INSIDE_COUNTER <= rst_counter);

always@(posedge clk) begin
       if (!rst_n) begin
           rst_counter<=rst_counter+4'd1;
           end      
end

always@(posedge clk or negedge rst_n) begin
       if (!rst_n) begin
           counter<=24'd0;
           led_b<=1'b1;
           end
       else begin
           if (counter >= SYS_COUNT) begin
           counter<=24'd0;
           led_b<=~led_b;
           end
           else begin 
           counter<=counter+1'd1;
           end
       end
end
endmodule