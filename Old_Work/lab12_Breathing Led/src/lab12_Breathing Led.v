module led_breathing(input wire clk,
                     input wire rst,
                     output wire o_pwm
); 
                     reg [9:0]r_reg_count;
                     parameter  MAX_COUNT=10'd999;
                     reg [9:0]r_reg_duty_cycle;

                     reg [15:0] r_get_tick;
                     parameter MAX_TICK=16'd53999;
                     wire pulse_tick;

                     parameter S_INCREASING=1'b0;
                     parameter S_DECREASING=1'b1;
                     reg state;
          
always@(posedge clk or posedge rst) begin //Bộ đếm tick 
    if(rst) begin
        r_get_tick<=1'd0;
    end
    else begin
        if (r_get_tick < MAX_TICK)begin
            r_get_tick<=r_get_tick+1'd1;
        end
        if (r_get_tick >= MAX_TICK) begin
            r_get_tick<=1'd0;
        end
    end
end

assign pulse_tick=(r_get_tick==MAX_TICK); // Tín hiệu đếm dutycycle

always@(posedge clk or posedge rst) begin // Bộ thay đổi duty cycle
    if (rst) begin
        r_reg_duty_cycle<=10'd0;
        state<=S_INCREASING;
    end
    else begin
        if (pulse_tick) begin
            case(state)
            S_INCREASING: begin // Nên phát hiện biên trước
                if (r_reg_duty_cycle < MAX_COUNT) begin
                    r_reg_duty_cycle<=r_reg_duty_cycle+1'd1;
                end
                if (r_reg_duty_cycle>=MAX_COUNT) begin
                    state<=S_DECREASING;
                end
            end
            S_DECREASING: begin
                if (r_reg_duty_cycle > 0) begin
                    r_reg_duty_cycle<=r_reg_duty_cycle-1'd1;
                end
                if (r_reg_duty_cycle<=0) begin
                    state<=S_INCREASING;
                end
            end
            endcase

        end
    end
end

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

assign o_pwm=(r_reg_duty_cycle > r_reg_count); //Bộ gán pwm

endmodule