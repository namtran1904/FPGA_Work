module top_slave(input wire clk,
                 input wire rst,

                 input wire i_spi_clk,
                 input wire i_spi_cs,
                 input wire i_spi_MOSI,
                 output wire o_spi_MISO,
                 
                 output wire [7:0]o_led
);
                 wire [7:0]w_data;
SPI_Slave spi_slave(.rst(!rst),
                    .spi_clk(i_spi_clk),
                    .spi_cs(i_spi_cs),
                    .MOSI(i_spi_MOSI),
                    .MISO(o_spi_MISO),
                    .led_out(o_led),
                    .tx_data(),
                    .rx_data(w_data)
);
endmodule