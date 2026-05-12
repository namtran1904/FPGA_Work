/*module I2C_V1_0#(parameter CLK_FREQ = 27000000,
                 parameter I2C_FREQ = 100000
               )(input wire i_clk,
                 input wire i_rst,
                 input wire i_start,
                 output reg o_busy,
                 output reg o_ack_error,

                 output reg SCL,
                 inout wire SDA,

                 input wire[7:0]data,
                 input wire[6:0]addr
);
                 wire sda_in;
                 reg sda_en;
                 reg sda_out;

                 reg [1:0]tick;
                 reg [2:0]bit_idx;
                 reg [7:0]count;
                 reg [7:0]data_buffer;
                 reg [7:0]addr_buffer;
                 reg [2:0]state,next_state;
                 
                 localparam IDLE       = 3'b000;
                 localparam START      = 3'b001;
                 localparam ADDR       = 3'b010;
                 localparam ADDR_ACK   = 3'b011;
                 localparam WRITE_DATA = 3'b100;
                 localparam DATA_ACK   = 3'b101;
                 localparam STOP       = 3'b110;

                 localparam TICK0 = 2'b00;
                 localparam TICK1 = 2'b01;
                 localparam TICK2 = 2'b10;
                 localparam TICK3 = 2'b11;

                 localparam COUNT = CLK_FREQ / (I2C_FREQ*4);

assign SDA = (sda_en && (sda_out==0))? 0 : 1'bz;
assign sda_in = SDA;

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
        end
        if(state != IDLE)begin
            count <= count +1;
            if(count == COUNT-1)begin
                tick <= tick +1;
                count <= 0;
            end
        end
        state <= next_state;
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
            if(o_ack_error == 0)begin
                next_state = WRITE_DATA;
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

    STOP: begin
        if(tick == TICK2)begin
            next_state = IDLE;
        end
    end

    default: next_state = IDLE;    
    endcase
end

always@(posedge i_clk)begin
        if(state == IDLE)begin
            SCL <= 1;
            sda_en <= 0;
            sda_out <= 0;
            bit_idx <= 3'b111;
            o_busy <= 0;
            o_ack_error <= 0;
            if(i_start)begin
                addr_buffer <= {addr , 1'b0};
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
            end

            ADDR: begin
                SCL <= (tick>=2);

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
                SCL <= (tick>=2);
                sda_en <= 0;
                sda_out <= 1;// 1 hay 0 đều được
                if(tick == TICK2) begin
                    o_ack_error <= (sda_in)? 1 : 0;
                end
            end

            WRITE_DATA: begin
                SCL <= (tick>=2);
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
                SCL <= (tick>=2);
                sda_en <= 0;
                sda_out <= 1;// 1 hay 0 đều được
                if (tick == TICK2)begin
                    o_ack_error <= (sda_in)? 1 : 0;
                end
            end

            STOP: begin
                SCL <= (tick >= TICK1)? 1 : 0;
                sda_en <= (tick >= TICK2) ? 0 : 1;
                if (tick == TICK3)begin
                   o_busy <= 0;
                end
                sda_out <= (tick >= TICK2)? 1: 0;
            end
            endcase
        end
        end
end
endmodule*/

module I2C_V1_1 #(
    parameter CLK_FREQ = 27000000,
    parameter I2C_FREQ = 100000
)(
    input wire i_clk, i_rst, i_start,
    output reg o_busy, o_ack_error,
    input wire i_rw_bit, i_stop_enable,
    output reg SCL,
    inout wire SDA,
    input wire [7:0] data,
    input wire [6:0] addr,
    output wire [7:0] o_rx_data
);
    localparam COUNT_MAX = CLK_FREQ / (I2C_FREQ * 4);
    
    // State machine
    localparam IDLE=0, START=1, ADDR=2, ADDR_ACK=3, WRITE=4, DATA_ACK=5, READ=6, M_ACK=7, STOP=8;
    reg [3:0] state;
    reg [7:0] count;
    reg [1:0] tick;
    reg [2:0] bit_idx;
    reg [7:0] addr_buf, data_buf, rx_buf;
    reg sda_out, sda_en;

    // Bộ đồng bộ SDA đầu vào (Chống Metastability)
    reg s1, s2;
    always @(posedge i_clk) {s2, s1} <= {s1, SDA};
    wire sda_in = s2;

    assign SDA = (sda_en && !sda_out) ? 1'b0 : 1'bz;
    assign o_rx_data = rx_buf;

    // --- KHỐI ĐIỀU KHIỂN CHÍNH ---
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            state <= IDLE; o_busy <= 0; SCL <= 1; sda_en <= 0; o_ack_error <= 0;
        end else begin
            if (state == IDLE) begin
                o_busy <= 0; SCL <= 1; sda_en <= 0; count <= 0; tick <= 0;
                if (i_start) begin
                    state <= START;
                    addr_buf <= {addr, i_rw_bit};
                    data_buf <= data;
                    bit_idx <= 7;
                end
            end else begin
                o_busy <= 1;
                // Bộ đếm Tick (Luôn chạy khi không IDLE)
                if (count < COUNT_MAX - 1) begin
                    count <= count + 1;
                end else begin
                    count <= 0;
                    tick <= tick + 1;
                    
                    // Logic chuyển trạng thái tại cuối Tick 3
                    if (tick == 2'b11) begin
                        case (state)
                            START:    state <= ADDR;
                            ADDR:     if (bit_idx == 0) state <= ADDR_ACK; else bit_idx <= bit_idx - 1;
                            ADDR_ACK: if (sda_in == 0) state <= (addr_buf[0] ? READ : WRITE); else state <= STOP;
                            WRITE:    if (bit_idx == 0) state <= DATA_ACK; else bit_idx <= bit_idx - 1;
                            DATA_ACK: state <= STOP;
                            READ:     if (bit_idx == 0) state <= M_ACK; else bit_idx <= bit_idx - 1;
                            M_ACK:    state <= STOP;
                            STOP:     state <= IDLE;
                        endcase
                    end
                end

                // --- ĐIỀU KHIỂN TÍN HIỆU VẬT LÝ (Cập nhật mỗi Clock) ---
                case (state)
                    START: begin
                        sda_en <= 1; sda_out <= (tick < 2); // SDA xuống trước
                        SCL <= (tick < 3); // SCL xuống sau
                    end
                    ADDR, WRITE: begin
                        sda_en <= 1;
                        sda_out <= (state == ADDR) ? addr_buf[bit_idx] : data_buf[bit_idx];
                        SCL <= (tick >= 2); // SCL High ở Tick 2, 3
                    end
                    ADDR_ACK, DATA_ACK, READ: begin
                        sda_en <= 0; // Thả SDA cho Slave
                        SCL <= (tick >= 2);
                        // Lấy mẫu (Sample) tại Tick 3 (An toàn nhất)
                        if (state == READ && tick == 3 && count == 0)
                            rx_buf[bit_idx] <= sda_in;
                        if ((state == ADDR_ACK || state == DATA_ACK) && tick == 3 && count == 0)
                            o_ack_error <= sda_in;
                    end
                    M_ACK: begin
                        sda_en <= 1; 
                        sda_out <= i_stop_enable; // Gửi NACK (1) để kết thúc
                        SCL <= (tick >= 2);
                    end
                    STOP: begin
                        sda_en <= 1; sda_out <= (tick >= 2); // SDA lên sau
                        SCL <= (tick >= 1); // SCL lên trước
                    end
                endcase
            end
        end
    end
endmodule
