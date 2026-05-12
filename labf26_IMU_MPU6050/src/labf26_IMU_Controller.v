module IMU_Controller(input wire i_clk,
                      input wire i_rst,
                      input wire i_start,

                      // Bộ tín hiệu giao tiếp I2C Module
                      output reg [7:0]o_i2c_addr,
                      output reg [7:0]o_i2c_data,
                      input wire [7:0]i_i2c_data,
                      output reg o_i2c_start,
                      input wire i_i2c_busy,
                      input wire i_ack_error,

                      output reg o_i2c_rw,
                      output reg o_i2c_repeat,
                      output reg o_i2c_stop,

                      // Bộ tín hiệu giao tiếp module ngoài (STM32)
                      input wire i_stm_start,
                      input wire i_stm_rw,
                      input wire [7:0]i_stm_reg_addr,
                      input wire [7:0]i_stm_data_in,
                      output reg [14*8-1:0]o_imu_data,
                      output reg o_data_valid

);
                      localparam IDLE            = 3'b000;
                      localparam SEND_REG_ADDR   = 3'b001;
                      localparam WAIT_ACK        = 3'b010;
                      localparam WAIT_WRITE_DONE = 3'b011;
                      localparam REPEATED_START  = 3'b100;
                      localparam READ_BYTE       = 3'b101;
                      localparam STOP            = 3'b110;
                      
                      localparam COUNT           = 4'b1110;

                      reg[2:0]state,next_state;
                      reg[3:0]byte_count;

reg i2c_prev_signal;
always@(posedge i_clk or posedge i_rst)begin
    i2c_prev_signal <= i_i2c_busy;
end
wire i2c_done_pulse = (i_i2c_busy == 0) && (i2c_prev_signal == 1); 

wire xong_1_byte = (state == READ_BYTE) && i2c_done_pulse;                      

wire xong_byte_count = (byte_count == COUNT);

always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

always@(*)begin
    next_state = state;

    case(state)
    IDLE: begin
        if(i_stm_start) next_state = SEND_REG_ADDR;
    end

    SEND_REG_ADDR: begin
        if(i_i2c_busy)begin
            next_state = WAIT_ACK;
        end
    end

    WAIT_ACK: begin
        if(!i_i2c_busy)begin
            if(i_ack_error)begin
                next_state = STOP;
            end
            else begin
                next_state = WAIT_WRITE_DONE;
            end
        end 
    end

    WAIT_WRITE_DONE: begin
        if(!i_i2c_busy)begin
            if(i_stm_rw)begin
                next_state = REPEATED_START;
            end
            else begin
                next_state = STOP;
            end
        end
    end

    REPEATED_START: begin
        if(!i_i2c_busy) next_state = READ_BYTE;
    end

    READ_BYTE: begin
        if(!i_i2c_busy)begin
            if (xong_byte_count)begin
                next_state = STOP;
            end
            else begin
                next_state = READ_BYTE;
            end
        end
    end

    default: next_state = IDLE;
    endcase
end

always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        byte_count <= 0;
        o_i2c_start <= 0;
        o_i2c_stop <= 0;
        o_i2c_repeat <= 0;
    end
    else begin
        // Bộ đếm byte_count
        if(state == IDLE) byte_count <= 0;
        else if (xong_1_byte) byte_count <= byte_count + 1;

        // Bộ nhồi dữ liệu 
        if(state == READ_BYTE && xong_1_byte)begin
            o_imu_data[((13-byte_count) * 8) +:8] <= i_i2c_data;
        end
        if((state == STOP) && (next_state == IDLE)) o_data_valid <= 1;
        else o_data_valid <= 0;

        // Bộ đầu ra trạng thái
        if(i_i2c_busy)begin
            o_i2c_start <= 0;
            o_i2c_stop <= 0;
            o_i2c_repeat <= 0;
        end
        case(state)
        IDLE:begin
            if(i_stm_start)begin
                o_i2c_start <= 1;
            end
        end

        SEND_REG_ADDR:begin
            o_i2c_addr <= 7'h68;
            o_i2c_data <= 8'h3B;
        end

        WAIT_ACK:begin
            if(i_ack_error) o_i2c_stop <= 1;
        end

        WAIT_WRITE_DONE:begin
            if(i_ack_error) o_i2c_stop <= 1;
        end

        REPEATED_START:begin
            o_i2c_rw   <= 1;
            o_i2c_repeat <= 1;
            o_i2c_start <= 1;
        end

        READ_BYTE:begin
            if(i2c_done_pulse && !xong_byte_count) o_i2c_start <= 1;
        end

        STOP:begin
            o_i2c_stop <= 1;
        end
        endcase
    end
end
endmodule
