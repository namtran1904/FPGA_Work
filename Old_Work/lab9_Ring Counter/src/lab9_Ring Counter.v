module Ring_counter(input wire clk,
                    input wire rst,
                    input wire w_press_button,
                    output wire [2:0]led_out
 );
                    wire i_posedge_button;
                    reg prev_button_state;
                    reg [2:0]led_state;   //trạng thái nội của led

assign i_posedge_button=(~prev_button_state & w_press_button);

always@(posedge clk or posedge rst) begin
    if(rst) begin
        led_state<=3'b001;
        prev_button_state<=1'b0;
    end
    else begin
        if (i_posedge_button) begin
            led_state<={led_state[1:0],led_state[2]};
        end
        prev_button_state<=w_press_button;
    end
end  

assign led_out=led_state;
endmodule