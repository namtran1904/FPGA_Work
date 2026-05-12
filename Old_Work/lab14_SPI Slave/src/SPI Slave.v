module SPI_Slave(input wire rst,
                 input wire spi_clk,
                 input wire spi_cs,
                 output reg [7:0]rx_data,
                 input wire [7:0]tx_data,
                 output reg [7:0]led_out,

                 input wire MOSI,
                 output reg MISO
);
                 reg [7:0]spi_buffer_temp;
                 reg [3:0]bit_idx;

always@(posedge spi_clk or posedge rst) begin
    if (rst) begin
        spi_buffer_temp<=0;
    end
    else begin
        if (spi_cs == 1'b0) begin
            spi_buffer_temp<={spi_buffer_temp[6:0],MOSI};
            end    
    end
end

always@(posedge spi_cs or posedge rst) begin
    if (rst) begin
        led_out<=0;
        rx_data<=0;
    end
    else begin
        led_out<=spi_buffer_temp;
        rx_data<=spi_buffer_temp;
    end
end

always@(negedge spi_clk or posedge spi_cs or posedge rst) begin
    if (rst) begin
        bit_idx<=7;
        MISO<=0;
    end
    else if (spi_cs == 1'b1) begin
        bit_idx<=7;
        MISO<=tx_data[7];
    end
    else begin
        if (bit_idx >0) begin
            bit_idx<=bit_idx-1;
            MISO<=tx_data[bit_idx-1];
        end
    end
end
endmodule