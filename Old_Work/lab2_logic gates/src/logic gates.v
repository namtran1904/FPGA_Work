module logic_gates(
    input physical_button_1,
    input physical_button_2,
    output wire led_r
    //output wire led_g
    //output wire led_b
);
    wire pressed_button_1;
    wire pressed_button_2;

    assign pressed_button_1 = ~physical_button_1;
    assign pressed_button_2 = ~physical_button_2;

    assign led_r = (pressed_button_1 & pressed_button_2);
    //assign led_g = (pressed_button_1 | pressed_button_2);
    //assign led_b = ~(pressed_button_1 & pressed_button_2);
endmodule
