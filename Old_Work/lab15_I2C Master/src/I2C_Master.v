module I2C_Master( input wire clk,
                   input wire rst,
                   input wire i2c_start,
                   output reg i2c_busy,
                   input wire [6:0]addr,
                   input wire [7:0]tx_data,
                   output reg [7:0]rx_data,

                   output reg SCL,
                   inout wire SDA // vừa là input, vừa là output
);                 
                   wire sda_in;
                   reg sda_en;
                   reg sda_out;

                   reg [6:0]baud_count;
                   reg [7:0]i2c_buffer_temp;
                   reg [3:0]bit_idx;
                   reg [1:0]tick;
                   reg [2:0]state;

                   localparam I2C_TICK_DIV = 67;
                   localparam IDLE = 3'b000;
                   localparam START = 3'b001;
                   localparam ADDRESS = 3'b010;
                   localparam ACK_ADDR = 3'b011;
                   localparam WRITE_DATA = 3'b100;
                   localparam ACK_DATA = 3'b101;
                   localparam STOP = 3'b110;

assign SDA = (sda_en && (sda_out == 0)) ? 1'b0 : 1'bz; //set up sda
assign sda_in = SDA;

always@(posedge clk or posedge rst) begin //set up tick
    if (rst) begin
        baud_count<=1'b0;
        tick<=1'b0;
    end
    else begin
        if (baud_count<I2C_TICK_DIV-1) begin
            baud_count<=baud_count+1'b1;
        end
        else begin
            baud_count<=1'b0;
            tick<=tick+1'b1;
        end
    end
end

always@(posedge clk) begin // set up scl trong từng trạng thái
    case(state)

    IDLE: begin
        SCL<=1'b1;
    end

    START: begin
        if (tick == 2'b11) begin 
            SCL<=1'b0;
        end
        else begin
            SCL<=1'b1;
        end
    end

    STOP: begin
        if (tick == 2'b00) begin
            SCL<=1'b0;
        end
        else begin
            SCL<=1'b1;
        end
    end

    ADDRESS,ACK_ADDR,WRITE_DATA,ACK_DATA: begin
        if (tick == 2'b00 || tick == 2'b01) begin
            SCL<=1'b0;
        end
        else begin
            SCL<=1'b1;
        end
    end
    endcase
end
always@(posedge clk or posedge rst) begin //set up sda trong máy trạng thái 
    if (rst) begin
        bit_idx<=7;
        i2c_busy<=1'b0;
        sda_en<=0;
    end
    else begin
        case(state) 

        IDLE: begin
            bit_idx<=7;
            i2c_busy<=1'b0;
            sda_en<=1'b0;
            sda_out<=1'b1;
            i2c_buffer_temp<={addr,0};
            if (i2c_start) begin
                i2c_busy<=1'b1;
                state<=START;
            end
        end

        START: begin
            if (baud_count == I2C_TICK_DIV-1) begin
                if (tick == 2'b00) begin
                    sda_en<=1'b1;
                    sda_out<=1'b1;
                end
                if (tick == 2'b01 )begin
                end
                if (tick == 2'b10) begin
                    sda_out<=1'b0;
                end
                if (tick == 2'b11) begin
                    bit_idx<=7;
                    state<=ADDRESS;
                end
            end
        end

        ADDRESS: begin
            if (baud_count == I2C_TICK_DIV-1) begin
                if (tick == 2'b00 ) begin
                    sda_out<=i2c_buffer_temp[bit_idx];
                end
                if (tick == 2'b01) begin
                end
                if (tick == 2'b10) begin
                end
                if (tick == 2'b11) begin
                    if(bit_idx == 0) begin
                       state<=ACK_ADDR;
                    end
                    else begin
                        bit_idx<=bit_idx-1;
                    end
                end
            end
        end

        ACK_ADDR: begin
            if (baud_count == I2C_TICK_DIV-1) begin
                if (tick == 2'b00) begin
                    sda_en<=1'b0;
                end
                if (tick == 2'b01) begin
                end
                if (tick == 2'b10) begin
                    if (sda_in == 1) begin
                        state<=IDLE;
                    end
                end
                if(tick == 2'b11) begin
                    bit_idx<=7;
                    i2c_buffer_temp<=tx_data;
                    state<=WRITE_DATA;
                end
            end
        end

        WRITE_DATA: begin
            if (baud_count == I2C_TICK_DIV-1) begin
                if (tick == 2'b00 ) begin
                    sda_en<=1'b1;
                    sda_out<=i2c_buffer_temp[bit_idx];
                end
                if (tick == 2'b01) begin
                end
                if (tick == 2'b10) begin
                end
                if (tick == 2'b11) begin
                    if(bit_idx == 0) begin
                       state<=ACK_DATA;
                    end
                    else begin
                        bit_idx<=bit_idx-1;
                    end
                end
            end
        end

        ACK_DATA: begin
            if (baud_count == I2C_TICK_DIV-1) begin
                if (tick == 2'b00) begin
                    sda_en<=1'b0;
                end
                if (tick == 2'b01) begin
                end
                if (tick == 2'b10) begin
                    if (sda_in == 1) begin
                        state<=IDLE;
                    end
                end
                if(tick == 2'b11) begin
                    state<=STOP ;
                end
            end
        end

        STOP: begin
            if( baud_count == I2C_TICK_DIV-1) begin
                if(tick == 2'b00) begin
                    sda_en<=1'b1;
                    sda_out<=1'b0;
                end
                if(tick == 2'b01) begin
                end
                if(tick == 2'b10) begin
                    sda_out<=1'b1;
                end
                if(tick == 2'b11) begin
                    state<=IDLE;
                    i2c_busy<=1'b0;
                end
            end
        end

    endcase
    end
end


endmodule