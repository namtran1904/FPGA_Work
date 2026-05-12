module Binary_counter #(parameter WIDTH = 4)
                     (input wire clk,
                      input wire rst,
                      input wire enb,
                      output reg[WIDTH-1:0] count
);

always@(posedge clk or posedge rst)begin
    if(rst)begin
      count<={WIDTH{1'b0}};
    end
    else begin
        if(enb)begin
            count<=count+1;
        end
    end
end
endmodule
