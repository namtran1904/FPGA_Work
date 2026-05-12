module top_bridge_master(input wire clk,
                         input wire rst,
                         
                         input wire i_uart_rx,
                         output wire o_uart_tx,

                         output wire o_spi_clk,
                         output wire o_spi_cs,
                         output wire o_spi_MOSI,
                         input wire i_spi_MISO
);
                         wire [7:0] w_data;
                         wire w_ready;
                         
uart_rx u_receiver (.clk(clk),
                    .rst(!rst),
                    .uart_byte(w_data),
                    .rx_pin(i_uart_rx),
                    .rx_done(w_ready)
);

uart_tx u_transmitter(.clk(clk),
                      .rst(!rst),
                      .uart_byte(w_data),
                      .tx_pin(o_uart_tx),
                      .tx_busy(),
                      .tx_start(w_ready)
);

SPI_Master uart_spi_master(.clk(clk),
                           .rst(!rst),
                           .spi_start(w_ready),
                           .spi_busy(),
                           .tx_data(w_data),
                           .spi_clk(o_spi_clk),
                           .MISO(i_spi_MISO),
                           .MOSI(o_spi_MOSI),
                           .spi_cs(o_spi_cs)
);
                         
endmodule