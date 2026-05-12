module Decoder(input wire [1:0] physical_button,             
               output wire [3:0] led_out
 );
               wire [3:0]w_button;

assign w_button=(1<<physical_button);

assign led_out=~w_button;

endmodule