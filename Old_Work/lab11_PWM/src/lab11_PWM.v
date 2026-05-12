module pwm_core (input wire clk,
                input wire rst,
                output wire o_pwm,

                input wire i_btn1,
                input wire i_btn2
); 
                reg [9:0]r_reg_count;
                parameter  MAX_COUNT=10'd999;
                reg [9:0]r_reg_duty_cycle;

                reg prev_dec_button_state;
                reg prev_inc_button_state;
                wire i_posedge_dec;
                wire i_posedge_inc;

always@(posedge clk or posedge rst) begin // Bộ đếm count
    if (rst) begin
        r_reg_count<=1'd0;
    end
    else begin
        r_reg_count<=r_reg_count+1'd1;
        if (r_reg_count >= MAX_COUNT) begin
            r_reg_count<=1'd0;
        end
    end
end

assign i_posedge_dec=(~prev_dec_button_state & i_btn2); //Giảm

assign i_posedge_inc=(~prev_inc_button_state & i_btn1); //Tăng

always@(posedge clk or posedge rst) begin // Bộ cập nhật duty cycle
    if (rst) begin
        prev_dec_button_state<=1'b0;
        prev_inc_button_state<=1'b0;
        r_reg_duty_cycle<=1'd0;
    end
    else begin
        prev_inc_button_state<=i_btn1;
        prev_dec_button_state<=i_btn2;
        if (i_posedge_inc) begin
            if (r_reg_duty_cycle < MAX_COUNT) begin
            r_reg_duty_cycle<=r_reg_duty_cycle+7'd100;
            end
        end
        if(i_posedge_dec) begin
            if(r_reg_duty_cycle > 0) begin
              r_reg_duty_cycle<=r_reg_duty_cycle-7'd100;
            end
        end
    end
end

assign o_pwm=(r_reg_duty_cycle > r_reg_count); //Bộ gán pwm

endmodule

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

module Top_module(input wire i_clk,
                  input wire i_rst,
                  input i_btn1,
                  input i_btn2,
                  output wire led_out
);
                  wire btn1_debounced;
                  wire btn2_debounced;

button_debouncing u_debouncer_1(.clk(i_clk) , .rst(i_rst) , .btn_in(i_btn1) , .btn_out(btn1_debounced));
button_debouncing u_debouncer_2(.clk(i_clk) , .rst(i_rst) , .btn_in(i_btn2) , .btn_out(btn2_debounced));
pwm_core u_pwm (.clk(i_clk) , .rst(i_rst) , .o_pwm(led_out) , .i_btn1(btn1_debounced) , .i_btn2(btn2_debounced));
endmodule

