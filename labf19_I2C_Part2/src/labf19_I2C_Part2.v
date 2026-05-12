module I2C_V1_1#(parameter CLK_FREQ = 27000000,
                 parameter I2C_FREQ = 100000
               )(input wire i_clk,
                 input wire i_rst,
                 input wire i_start,
                 output reg o_busy,
                 output reg o_ack_error,
                 input wire i_rw_bit,
                 input wire i_stop_enable,

                 output reg SCL,
                 inout wire SDA,

                 input wire[7:0]data,
                 input wire[6:0]addr,
                 output wire [7:0] o_rx_data
);
                 wire sda_in;
                 reg sda_en;
                 reg sda_out;
                 reg sda_sync1,sda_sync2;

                 reg [1:0]tick;
                 reg [2:0]bit_idx;
                 reg [7:0]count;
                 reg [7:0]data_buffer;
                 reg [7:0]addr_buffer;
                 reg [7:0]rx_buffer;
                 reg [3:0]state,next_state;
                 
                 localparam IDLE           = 4'b0000;
                 localparam START          = 4'b0001;
                 localparam ADDR           = 4'b0010;
                 localparam ADDR_ACK       = 4'b0011;
                 localparam WRITE_DATA     = 4'b0100;
                 localparam DATA_ACK       = 4'b0101;
                 localparam READ_DATA      = 4'b0110;
                 localparam MASTER_ACK     = 4'b0111;
                 localparam STOP           = 4'b1000;

                 localparam TICK0 = 2'b00;
                 localparam TICK1 = 2'b01;
                 localparam TICK2 = 2'b10;
                 localparam TICK3 = 2'b11;

                 localparam COUNT = CLK_FREQ / (I2C_FREQ*4);

assign SDA = (sda_en && (sda_out==0))? 0 : 1'bz;
always@(posedge i_clk)begin
    sda_sync1 <= SDA;
    sda_sync2 <= sda_sync1;
end
assign sda_in = sda_sync2;

assign o_rx_data = rx_buffer;

always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        tick <= 0;
        count <= 0;
        state <= IDLE;
    end
    else begin
        if(state == IDLE)begin
            tick <= 0;
            count <= 0;
            if(i_start) begin
                state <= START;
            end
        end
        else begin
            if(count >= COUNT-1)begin
                count <= 0;
                tick <= tick + 1;
                if (tick == TICK3)begin
                    state <= next_state;
                end
            end
            else begin
                count <= count + 1;
            end
        end
    end
end

always@(*)begin
    next_state = state;

    case(state)
    IDLE: begin
        if(i_start)begin
            next_state = START;
        end
    end

    START: begin
        if(tick == TICK3)begin
            next_state = ADDR;
        end
    end

    ADDR: begin
        if(tick == TICK3 && bit_idx == 0)begin
            next_state = ADDR_ACK;
        end
    end

    ADDR_ACK: begin
        if(tick == TICK3)begin
            if(sda_in == 0)begin
                next_state = (addr_buffer[0])? READ_DATA: WRITE_DATA;
            end
            else begin
                next_state = STOP;
            end
        end
    end

    WRITE_DATA: begin
        if(tick == TICK3 && bit_idx == 0)begin
            next_state = DATA_ACK;
        end
    end

    DATA_ACK: begin
        if(tick == TICK3)begin
            if(o_ack_error == 0)begin
                next_state = STOP;
            end
            else begin
                next_state = STOP;
            end
        end
    end

    READ_DATA: begin
        if(tick == TICK3 && bit_idx == 0)begin
            next_state = MASTER_ACK;
        end
    end

    MASTER_ACK: begin
        if(tick == TICK3)begin
            next_state = (i_stop_enable)? STOP: READ_DATA;
        end
    end

    STOP: begin
        if(tick == TICK3)begin
            next_state = IDLE;
        end
    end

    default: next_state = IDLE;    
    endcase
end

always@(posedge i_clk or posedge i_rst)begin
        if(state == IDLE)begin
            SCL <= 1;
            sda_en <= 0;
            sda_out <= 0;
            bit_idx <= 3'b111;
            o_busy <= 0;
            if(i_start)begin
                addr_buffer <= {addr ,i_rw_bit};
                data_buffer <= data;
            end
        end
        else begin
            if(count == COUNT -1)begin
            case(state)
            START: begin
                SCL <= (tick >= TICK3)? 0 : 1;
                sda_en <= 1;
                sda_out <= (tick >= TICK1 )? 0: 1;
                o_busy <= 1;
                o_ack_error <= 0;
            end

            ADDR: begin
                SCL <= (tick>=TICK2);

                sda_en <= 1;
                if(tick == TICK0)begin
                  sda_out <= addr_buffer[bit_idx];
                end
                if(tick ==TICK3)begin
                    if(bit_idx != 0)begin
                        bit_idx <= bit_idx -1;
                    end
                    else begin
                        bit_idx <= 3'b111;
                    end
                end
            end

            ADDR_ACK: begin
                SCL <= (tick>=TICK2);
                sda_en <= 0;
                sda_out <= 1;// 1 hay 0 đều được
                if(tick == TICK2) begin
                    o_ack_error <= (sda_in)? 1 : 0;
                end
            end

            WRITE_DATA: begin
                SCL <= (tick>=TICK2);
                sda_en <= 1;
                if(tick ==TICK0)begin
                    sda_out <= data_buffer[bit_idx];
                end
                if(tick ==TICK3)begin
                    if(bit_idx != 0)begin
                        bit_idx <= bit_idx -1;
                    end
                    else begin
                        bit_idx <= 3'b111;
                    end
                end
            end

            DATA_ACK: begin
                SCL <= (tick>=TICK2);
                sda_en <= 0;
                sda_out <= 1;// 1 hay 0 đều được
                if (tick == TICK2)begin
                    o_ack_error <= (sda_in)? 1 : 0;
                end
            end

            READ_DATA: begin
                SCL <= (tick >= TICK2)? 1 : 0;
                sda_en <= 0;
                if(tick == TICK2)begin
                    rx_buffer[bit_idx] <= sda_in;
                end
                if(tick == TICK3)begin
                    if(bit_idx != 0)begin
                        bit_idx <= bit_idx -1;
                    end
                    else begin
                        bit_idx <= 3'b111;
                    end
                end
            end

            MASTER_ACK: begin
                SCL <= (tick >= TICK2);
                sda_en <= 1;
                sda_out <= (i_stop_enable)? 1 : 0; // 0 là đọc tiếp
            end

            STOP: begin
                SCL <= (tick >= TICK1)? 1 : 0;
                sda_en <= (tick >= TICK2) ? 0 : 1;
                if (tick == TICK3)begin
                    o_busy <= 0;
                end
                sda_out <= 0;
            end
            endcase
        end
        end
end
endmodule
