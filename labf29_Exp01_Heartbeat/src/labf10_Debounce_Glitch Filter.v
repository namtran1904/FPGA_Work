module Debounce #(parameter WAIT_TIME = 270000 )
                (input wire i_clk,
                input wire i_rst,

                input wire i_signal,
                output reg o_debounced_signal
);
                reg [20:0]count;
                reg signal_sync1;
                reg signal_sync2;

always@(posedge i_clk)begin
    signal_sync1 <= i_signal;
    signal_sync2 <= signal_sync1;
end
always@(posedge i_clk or posedge i_rst)begin
    if(i_rst)begin
        count <= 0;
        o_debounced_signal <= 0;
    end
    else begin
        if( signal_sync2 != o_debounced_signal)begin
            count <= count +1;
            if(count > WAIT_TIME-1)begin
                o_debounced_signal <= signal_sync2;
            end
        end
        else begin
            count <= 0;
        end
        
    end
end
endmodule
