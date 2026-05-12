module MUX_DFF( input clk,
                input rst,
                output Q_out,
                input select_mode,
                input data_in1
);
                wire D_wire;
                reg Q_reg;
              
                
assign D_wire = select_mode ? Q_reg : data_in1 ;

always@(posedge clk ) begin
if (rst) begin
   Q_reg <= 1'b0;
   end
else begin
    Q_reg <= D_wire;
end
end 

assign Q_out = ~Q_reg;
endmodule