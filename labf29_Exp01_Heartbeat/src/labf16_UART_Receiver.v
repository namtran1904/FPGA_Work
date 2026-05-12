module UART_Receiver#(parameter CLK_FREQ = 27000000,
                      parameter BAUD_RATE = 115200)
                     (input wire i_clk,
                      input wire i_rst,

                      output reg [7:0] o_rx_data,
                      input wire i_rx_serial,

                      output reg o_rx_done
);
                      localparam COUNT = CLK_FREQ/BAUD_RATE;
                      localparam COUNT_HALF = COUNT/2;

                      localparam IDLE = 2'b00;
                      localparam START = 2'b01;
                      localparam DATA = 2'b10;
                      localparam STOP = 2'b11;

                      reg [2:0]bit_idx;
                      reg [15:0]wait_count;
                      reg [1:0]state,next_state;
                      reg [7:0]data_buffer;

                      reg r_rx_sync1;
                      reg r_rx_sync2;

always@(posedge i_clk)begin
    r_rx_sync1 <= i_rx_serial;
    r_rx_sync2 <= r_rx_sync1;
end

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
        if(r_rx_sync2 == 0)begin
            next_state = START;
        end
    end

    START: begin
        if(wait_count == COUNT_HALF-1)begin
            if(r_rx_sync2 == 0)begin
                next_state = DATA;
            end
            if(r_rx_sync2 == 1)begin
                next_state = IDLE;
            end
        end
    end

    DATA: begin
        if(wait_count == COUNT-1)begin
            if(bit_idx == 3'b111)begin
                next_state = STOP;
            end
        end
    end
    
    STOP: begin
        if(wait_count == COUNT-1)begin
            next_state = IDLE;
        end
    end

    default: next_state = IDLE;
    endcase
end

always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        bit_idx <= 0;
        wait_count <= 0;
        data_buffer <= 0;
        o_rx_done <= 0;
    end
    else begin
        case(state)

        IDLE: begin
            o_rx_done <= 0;
            bit_idx <= 0;
            wait_count <= 0;
        end

        START: begin
            if(wait_count != COUNT_HALF-1)begin
                wait_count <= wait_count + 1;
            end
            else begin
                wait_count <= 0;
            end
        end

        DATA: begin
        if(wait_count == COUNT-1) begin
          wait_count <= 0;
          data_buffer[bit_idx] <= r_rx_sync2;
          bit_idx <= bit_idx + 1;
          end 
        else begin
          wait_count <= wait_count + 1;
        end
        end

        STOP: begin
            if(wait_count == COUNT-1)begin
                wait_count <= 0;
                o_rx_done <= 1;
                o_rx_data <= data_buffer;
            end 
            else begin
                wait_count <= wait_count + 1;
                o_rx_done <= 0;
            end
        end
        endcase
    end
end

endmodule
