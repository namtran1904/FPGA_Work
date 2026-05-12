module toggle_ff(
    input wire clk,
    input wire physical_button,
    input wire rst,
    output wire led_out
);

    reg r_led_state;              //trạng thái nội của led
    reg r_prev_button_state;      //trạng thái trước của nút bấm
    wire i_posedge_button;        //bắt cạnh lên của nút bấm

    assign i_posedge_button = (~r_prev_button_state) & physical_button;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_led_state <= 1'b0;
            r_prev_button_state <= 1'b0;
        end
        else begin
            if (i_posedge_button) begin
                 r_led_state <= ~r_led_state;
                 end
            r_prev_button_state <= physical_button;
        end
    end

assign led_out=~r_led_state;
    
endmodule 