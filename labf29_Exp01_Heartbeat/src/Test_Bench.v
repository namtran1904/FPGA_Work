`timescale 1ns/1ps
module Test_Bench();
                  reg tb_clk;
                  reg tb_rst;
                  reg tb_rx;
                  wire tb_tx;
                  reg tb_button;
                  localparam BIT_PERIOD = 8680; // 1/115200 baud x 10^9 ns

Exp01_Heartbeat dut(
    .i_clk(tb_clk),
    .i_rst(tb_rst),
    .o_uart_tx(tb_tx),
    .i_uart_rx(tb_rx),
    .i_button(tb_button)
);

integer k;
reg [7:0]rand_data;

task send_byte(input [7:0]i_data);
     integer i;
     begin
      tb_rx = 0;
      #BIT_PERIOD;

      for(i=0;i<8;i=i+1)begin
        tb_rx = i_data[i];
        #BIT_PERIOD;
      end

      tb_rx = 1;
      #BIT_PERIOD;
      
      #1000;
   end
endtask

initial tb_clk = 0;
        
always #18.5 tb_clk = ~tb_clk; //nửa chu kỳ

initial begin
  $dumpfile("dump.vcd");
  $dumpvars(0,Test_Bench);

  tb_rst=1; tb_rx=1; tb_button=0;
  #100;
  tb_rst=0;
  #200;
  
  $display("--Bắt đầu stress test--");
  for (k=0;k<1000;k=k+1)begin
    rand_data = $urandom %256;
    send_byte(rand_data);

    #1000;
    
  end

  $display("--Mô phỏng kết thúc--");
  $finish;
end


endmodule
