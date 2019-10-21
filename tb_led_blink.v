`timescale 1ns/1ps
module tb_led_blink();

reg clk;
reg reset_n;
wire led_fpga;
wire [2:0] ledm_sel;
wire sp_clk;
wire sp_dat;
wire sp_ratch;

led_blink i1(
.clk(clk),
.reset_n(reset_n),
.led_fpga(led_fpga),
.ledm_sel(ledm_sel),
.sp_clk(sp_clk),
.sp_dat(sp_dat),
.sp_ratch(sp_ratch)
);

always #10 clk <= ~clk;

initial
begin
 clk <= 1'b0;
 reset_n <= 1'b1;
 #100 reset_n <= 1'b0;
 #100 reset_n <= 1'b1;
end

endmodule 
