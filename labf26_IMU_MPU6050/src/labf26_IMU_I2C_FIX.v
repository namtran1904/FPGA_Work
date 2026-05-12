module I2C_DRIVER#(parameter CLK_FREQ = 27000000,
                 parameter I2C_FREQ = 100000)
                (input wire i_clk,
                 input wire i_rst,

                 input wire i_start,
                 output reg o_busy,
                 output reg o_ack_error,

                 input wire i_rw_bit,
                 input wire i_cmd_repeat,
                 input wire i_cmd_stop,

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
                 localparam REPEATED_START = 4'b0110;
                 localparam READ_DATA      = 4'b0111;
                 localparam MASTER_ACK     = 4'b1000;
                 localparam STOP           = 4'b1001;
                 localparam HOLD_BUS       = 4'b1010;

                 localparam TICK0 = 2'b00;
                 localparam TICK1 = 2'b01;
                 localparam TICK2 = 2'b10;
                 localparam TICK3 = 2'b11;

                 localparam COUNT = CLK_FREQ / (I2C_FREQ*4);

assign SDA = (sda_en && (sda_out==0))? 0 : 1'bz; // khai báo tristate sda

always@(posedge i_clk)begin // bộ lọc tín hiệu 
    sda_sync1 <= SDA;
    sda_sync2 <= sda_sync1;
end

assign sda_in = sda_sync2; // đưa tín hiệu vào sda_in

assign o_rx_data = rx_buffer;

wire xong_byte = ((tick == TICK3) && (bit_idx == 0)); // chuyển xong 1 byte

wire xong_tick = (count == COUNT-1); // hết 1 khoảng tick

wire bit_shift_en = (state == ADDR || state == WRITE_DATA || state == READ_DATA) && (tick == TICK3);

always@(posedge i_clk or posedge i_rst)begin // chuyển trạng thái
    if(i_rst)begin
        state <= IDLE;
    end
    else begin
        if(i_start && (state == IDLE))begin // chỉ được start khi rảnh hoặc chờ lệnh 
            state <= next_state;
        end
        else if ((tick == TICK3) && xong_tick) begin // chỉ đổi trạng thái tại clock cuối tick3 khi đang chạy giao tiếp i2c
            state <= next_state;
        end
        else if ((i_start || i_cmd_stop || i_cmd_repeat) && (state ==HOLD_BUS)) begin
            state <= next_state;
        end
    end
end

always@(*)begin // logic chuyển trạng thái
    next_state = state;

    case(state)
    IDLE: begin
        if(i_start)begin
            next_state = START;
        end
    end

    HOLD_BUS: begin
        if (i_cmd_stop) next_state = STOP;
        else if (i_cmd_repeat) next_state = REPEATED_START;
        else if(i_start) next_state = addr_buffer[0]? READ_DATA : WRITE_DATA;
        else next_state = HOLD_BUS;
    end

    START: begin
        if(tick == TICK3)begin
            next_state = ADDR;
        end
    end

    ADDR: begin
        if(xong_byte)begin
            next_state = ADDR_ACK;
        end
    end

    ADDR_ACK: begin
        if(tick == TICK3)begin
            next_state = HOLD_BUS;
        end
    end

    WRITE_DATA: begin
        if(xong_byte)begin
            next_state = DATA_ACK;
        end
    end

    DATA_ACK: begin
        if(tick == TICK3)begin
            next_state = HOLD_BUS;
        end
    end

    REPEATED_START: begin
        if(tick == TICK3)begin
            next_state = ADDR;
        end
    end

    READ_DATA: begin
        if(xong_byte)begin
            next_state = MASTER_ACK;
        end
    end

    MASTER_ACK: begin
        if(tick == TICK3)begin
            next_state = HOLD_BUS;
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

always@(posedge i_clk or posedge i_rst)begin // logic đầu ra
        if(i_rst)begin
           count <= 0;
           tick <= 0;
           bit_idx <= 3'b111;
           SCL <= 1;
           sda_en <= 0;
           o_ack_error <= 0;
        end
        else begin
        // Bộ đếm count
        if(state ==IDLE || state == HOLD_BUS) count <= 0;
        else if (xong_tick) count <= 0;
        else count <= count + 1;

        // Bộ đếm tick
        if(state == IDLE || state == HOLD_BUS) tick <= 0;
        else if (xong_tick) tick <= 0;
        else tick <= tick + 1;

        // Bộ điều khiển bit/counter
        if (state == IDLE || state == HOLD_BUS) bit_idx <= 3'b111;
        else if (xong_byte) bit_idx <= 3'b111;
        else if (bit_shift_en && xong_tick) bit_idx <= bit_idx - 1;

        // Bộ feedback o_busy
        o_busy <= (state != IDLE && state != HOLD_BUS);

        // Bộ feedback o_ack_error
        if (state == ADDR_ACK || state == DATA_ACK)begin
            if (tick == TICK2 && xong_tick)begin
                o_ack_error <= (sda_in)? 1 : 0;
            end
        end
        else if(i_start && (state == IDLE))begin
            o_ack_error <= 0;
        end
        else if(state == HOLD_BUS)begin
            o_ack_error <= o_ack_error;
        end

        // Bộ nạp dữ liệu khi có xung start và không bận 
        if(i_start && (state == IDLE || state == HOLD_BUS))begin
            addr_buffer <= {addr ,i_rw_bit};
            data_buffer <= data;
        end


        // Bộ đầu ra trạng thái
        if(state == IDLE)begin
            SCL <= 1;
            sda_en <= 0;
            sda_out <= 0;
        end

        else if (state == HOLD_BUS)begin
            SCL <= 0;
            sda_en <= 0;
            sda_out <= 1;
        end

        else if(xong_tick)begin
            case(state)
            START: begin
                SCL <= (tick >= TICK3)? 0 : 1;
                sda_en <= 1;
                sda_out <= (tick >= TICK1 )? 0: 1;
            end

            ADDR: begin
                SCL <= (tick>=TICK2);
                sda_en <= 1;
                if(tick == TICK0)begin
                  sda_out <= addr_buffer[bit_idx];
                end
            end

            ADDR_ACK: begin
                SCL <= (tick>=TICK2);
                sda_en <= 0;
                sda_out <= 0;// bắt buộc là 0
            end

            WRITE_DATA: begin
                SCL <= (tick>=TICK2);
                sda_en <= 1;
                if(tick ==TICK0)begin
                    sda_out <= data_buffer[bit_idx];
                end
            end

            DATA_ACK: begin
                SCL <= (tick>=TICK2);
                sda_en <= 0;
                sda_out <= 0;// bắt buộc là 0
            end

            REPEATED_START: begin
                SCL <= (tick >= TICK2)? 0 : 1;
                sda_en <= 1;
                sda_out <= (tick >= TICK1)? 0 : 1;
                if(tick ==TICK3)begin
                    //addr_buffer[0] <= !addr_buffer[0];
                end
                bit_idx <= 3'b111;
            end

            READ_DATA: begin
                SCL <= (tick >= TICK2)? 1 : 0;
                sda_en <= 0;
                sda_out <= 1;
                if(tick == TICK2)begin
                    rx_buffer[bit_idx] <= sda_in;
                end
            end

            MASTER_ACK: begin
                SCL <= (tick >= TICK2);
                sda_en <= 1;
                sda_out <= (i_cmd_stop)? 1 : 0; // 0 là đọc tiếp
            end

            STOP: begin
                SCL <= (tick >= TICK1)? 1 : 0;
                sda_en <= (tick >= TICK2) ? 0 : 1;
                sda_out <= 0;
            end
            endcase
            end
        end
    end
endmodule
