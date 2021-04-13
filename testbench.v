`timescale 1ps/1ps

module testbench;

	reg clk = 0;
	reg up  = 0;
	reg down = 0;
	wire hsync;
	wire vsync;
	wire[3:0] red;
	wire[3:0] green;
	wire[3:0] blue;
	wire[15:0] disp1;
	wire[15:0] disp2;
	
	PongProject dut(clk, up, down, hsync, vsync, red, green, blue, disp1, disp2);
	
	always begin
		#1 clk = ~clk;
	end
	
endmodule