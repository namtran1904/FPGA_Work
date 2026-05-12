module UART_Transmitter #(parameter CLK_FREQ = 27000000,
                        parameter BAUD_RATE = 115200
                        )(
                        input wire i_clk,
                        input wire i_rst,

                        input wire i_tx_start,
                        input wire [7:0]i_tx_data,
                        output reg o_tx_serial,

                        output reg o_tx_busy
);
                        localparam COUNT=CLK_FREQ/BAUD_RATE;

                        localparam IDLE = 2'b00;
                        localparam START = 2'b01;
                        localparam DATA = 2'b10;
                        localparam STOP = 2'b11;

                        reg [3:0]bit_idx;
                        reg [15:0]wait_count;
                        reg [7:0]data_buffer;
                        reg [1:0]state,next_state;

always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

always@(*)begin
    next_state=state;
    case (state)

    IDLE: begin
        if(i_tx_start)begin
            next_state = START;
        end
    end

    START: begin
        if(wait_count == COUNT-1)begin
            next_state = DATA;
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
        wait_count <= 0;
        bit_idx <= 0;
        data_buffer <= 0;
        o_tx_busy <= 0;
        o_tx_serial <= 1'b1;
    end
    else begin
        
        case(state)
        IDLE: begin
        o_tx_serial <= 1;
        wait_count <= 0;
        bit_idx <= 0;
        o_tx_busy <= 0;
        if(i_tx_start)begin
            data_buffer <= i_tx_data;
            o_tx_busy <= 1;
        end
        end

        START: begin
            o_tx_busy <= 1;
            o_tx_serial <= 0;
            if(wait_count != COUNT-1)begin
                wait_count <= wait_count+1;
            end
            else begin
                wait_count <=0;
            end
        end

        DATA: begin
            o_tx_busy <= 1;
            o_tx_serial <= data_buffer[bit_idx];
            if(wait_count != COUNT-1)begin
                wait_count <= wait_count+1;
            end
            else begin
                wait_count <=0;
                bit_idx <= bit_idx+1;
            end
        end

        STOP: begin
            o_tx_busy <= 1;
            o_tx_serial <= 1;
             if(wait_count != COUNT-1)begin
                wait_count <= wait_count+1;
            end
            else begin
                wait_count <= 0;
            end
        end
        endcase
    end
end
endmodule
