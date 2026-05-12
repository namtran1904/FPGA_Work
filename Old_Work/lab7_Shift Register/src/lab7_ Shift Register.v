module shift_register ( input wire clk,
                        input wire rst,
                        input wire b_data,
                        input wire b_shift_enable, 
                        output wire [2:0]led_out
);
                        reg [2:0]r_shift_reg;
                        reg r_shift_enable_delay;
                        wire i_posedge_button;

assign i_posedge_button=(~r_shift_enable_delay & b_shift_enable);

always@(posedge clk or posedge rst) begin
    if (rst) begin
        r_shift_reg<=3'b000;
        r_shift_enable_delay<=1'b0;
    end
    else begin
        if (i_posedge_button) begin
            r_shift_reg<={r_shift_reg[1:0],b_data};
        end
        r_shift_enable_delay<=b_shift_enable;
    end
end

assign led_out=r_shift_reg;

endmodule                  