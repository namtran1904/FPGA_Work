module Exp01_Heartbeat(input wire i_clk,
                       input wire i_rst,
                       input wire i_uart_rx,
                       output wire o_uart_tx,
                       input wire i_button
);
                       wire [7:0]w_rx_data;
                       wire w_rx_done;
                       wire stable_signal;

UART_Receiver #(.CLK_FREQ(27000000), .BAUD_RATE(115200))
uart_rx(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_rx_serial(i_uart_rx),
    .o_rx_data(w_rx_data),
    .o_rx_done(w_rx_done)
);

UART_Transmitter #(.CLK_FREQ(27000000), .BAUD_RATE(115200))
uart_tx(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .o_tx_serial(o_uart_tx),
    .i_tx_data(w_rx_data),
    .o_tx_busy(), // Không dùng trong thí nghiệm EXP-01
    .i_tx_start(w_rx_done)
);

Debounce #(.WAIT_TIME(270000))
u_debounce(
    .i_clk(i_clk),
    .i_rst(i_rst),
    .i_signal(i_button),
    .o_debounced_signal(stable_signal)
);
endmodule
