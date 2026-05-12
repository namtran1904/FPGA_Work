module Binary_count(input wire clk,
                    input wire rst,
                    input wire w_press_button,
                    output wire [2:0]led_out //3 bit led 
);
                    reg [7:0]r_reg_count; //8 bit nội bộ
                    reg prev_button_state;
                    wire i_posedge_button;

assign i_posedge_button=(~prev_button_state & w_press_button);

always@( posedge clk or posedge rst) begin
    if (rst) begin
        r_reg_count<=8'b0;
        prev_button_state<=1'b0;
    end
    else begin
        if (i_posedge_button) begin
            r_reg_count<=r_reg_count+1'b1;
        end    
        prev_button_state<=w_press_button;

    end
end

assign led_out=r_reg_count[2:0];
endmodule