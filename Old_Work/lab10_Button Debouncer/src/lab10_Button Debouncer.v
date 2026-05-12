module button_debouncing(input wire clk,
                         input wire rst,
                         input wire btn_in,
                         output reg btn_out
);
                         parameter Delay_count = 20'd540_000;
                         reg [19:0] r_reg_delay;

always@( posedge clk or posedge rst) begin
    if (rst) begin
        r_reg_delay<=20'd0;
    end
    else begin
        if (btn_out != btn_in) begin
            r_reg_delay<=r_reg_delay + 1'd1;
            if (r_reg_delay == Delay_count) begin
                btn_out <= btn_in;
            end
        end
    end
end
endmodule

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

module Top_module (input wire i_clk,
                   input wire i_rst,
                   input wire i_btn,
                   output wire [2:0] o_led_out
);
                   wire w_button_debounced;
                   
button_debouncing u_debouncer (.clk(i_clk) , .rst(i_rst) , .btn_out(w_button_debounced) , .btn_in(i_btn) );    
Ring_counter u_counter (.clk(i_clk) , .rst(i_rst) , .w_press_button(w_button_debounced) , .led_out(o_led_out));
endmodule