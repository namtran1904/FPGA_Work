module top_module(input wire clk,
                  input wire rst,
                  input wire i_rx,
                  output wire o_tx
); 
                  wire [7:0] w_data;
                  wire w_ready;

uart_rx u_receiver(.clk(clk),
                   .rst(!rst),
                   .rx_pin(i_rx),
                   .rx_done(w_ready),
                   .uart_byte(w_data)
);

uart_tx u_transmitter(.clk(clk),
                      .rst(!rst),
                      .tx_pin(o_tx),
                      .tx_start(w_ready),
                      .uart_byte(w_data),
                      .tx_busy()
);

endmodule
                  