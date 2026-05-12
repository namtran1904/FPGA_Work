module I2C_Slave(input wire clk,
                 input wire rst,
                 input wire [7:0] tx_data_to_master,
                 output reg [7:0] rx_data_from_master,

                 input wire SCL,
                 inout wire SDA,

                 output reg [7:0]o_led
);
                 reg scl_1,scl_2;
                 reg sda_1,sda_2;
                 wire start_detected,stop_detected;
                 wire scl_rising,scl_falling;

                 reg sda_en;
                 reg sda_out;
                 wire sda_in;

                 reg [6:0]address = 7'h27;
                 reg [7:0]i2c_buffer_temp;
                 reg [3:0]bit_idx;
                 reg [2:0]state;

                 localparam IDLE = 3'b000;
                 localparam RX_ADDR = 3'b001;
                 localparam SEND_ACK_ADDR = 3'b010;
                 localparam RX_DATA = 3'b011;
                 localparam SEND_ACK_DATA = 3'b100;
                 localparam WAIT_STOP = 3'b101;

assign SDA = (sda_en && (sda_out == 1'b0)) ? 1'b0 : 1'bz;
assign sda_in = SDA;

always@(posedge clk) begin
    scl_1<=SCL;
    scl_2<=scl_1;
    sda_1<=SDA;
    sda_2<=sda_1;
end

assign start_detected = (sda_1 == 0 && sda_2 == 1) && (scl_1 == 1 && scl_2 == 1);
assign stop_detected = (sda_1 == 1 && sda_2 == 0) && (scl_1 == 1 && scl_2 == 1);
assign scl_rising = scl_1 == 1 && scl_2 == 0 ;
assign scl_falling = scl_1 == 0 && scl_2 == 1 ;

always@(posedge clk or posedge rst) begin
    if(rst) begin
        bit_idx<=7;
        state<=IDLE;
        sda_en<=1'b0;
        sda_out<=1'b0;
        o_led<=0;
    end 
else begin
    if(start_detected) begin
        state<=RX_ADDR;
        bit_idx<=7;
        sda_en<=1'b0;
    end

    else begin
        case(state)

        IDLE: begin
            sda_en<=1'b0;
        end

        RX_ADDR: begin
            if(scl_rising) begin
                i2c_buffer_temp<={i2c_buffer_temp[6:0],sda_in};
            end
            if(scl_falling) begin
                if(bit_idx == 0) begin
                    rx_data_from_master<=i2c_buffer_temp;
                    if(i2c_buffer_temp[7:1] == address) begin
                        state<=SEND_ACK_ADDR;
                        bit_idx<=7;
                    end
                    else begin
                        state<=IDLE;
                    end
                end
                else begin
                    bit_idx<=bit_idx-1;
                end
            end
        end

        SEND_ACK_ADDR: begin
            sda_en<=1'b1;
            sda_out<=1'b0;
            if(scl_falling) begin
                sda_en<=1'b0;
                bit_idx<=7;
                state<=RX_DATA;
            end
        end

        RX_DATA: begin
            if(scl_rising) begin
                i2c_buffer_temp<={i2c_buffer_temp[6:0],sda_in};
            end
            if (scl_falling) begin
                if(bit_idx == 0) begin
                    rx_data_from_master<=i2c_buffer_temp;
                    state<=SEND_ACK_DATA;
                end
                else begin 
                    bit_idx<=bit_idx-1;
                end
            end
        end

        SEND_ACK_DATA: begin
            sda_en<=1'b1;
            sda_out<=1'b0;
            if(scl_falling) begin
                sda_en<=1'b0;
                state<=WAIT_STOP;
            end
        end

        WAIT_STOP: begin
            if(stop_detected) begin
                state<=IDLE;
                o_led<=rx_data_from_master;
            end
        end

        endcase
    end
    end
end


endmodule

