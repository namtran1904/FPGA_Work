module Gray_count #(parameter WIDTH = 4)
                  (input wire clk,
                  input wire rst,
                  output wire [WIDTH-1:0]gray_count,
                  output reg [WIDTH-1:0]bin_count
                  );
    
always@(posedge clk or posedge rst)begin
    if(rst)begin
        bin_count<={WIDTH{1'b0}};
    end
    else begin
        bin_count<=bin_count+1'b1;
    end
end

assign gray_count = bin_count^(bin_count>>1);
endmodule
