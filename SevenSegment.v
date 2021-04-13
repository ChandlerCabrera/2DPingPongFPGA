module SevenSegment(
	input clk,
	input [6:0] value,
	output[15:0] display
	);
	
	reg [15:0] encoding = 16'b00000000_00000000;
	
	always @ (posedge clk) begin
	
		case(value)
			// encoding pattern:  dotgfedcba
          4'd0 : encoding[15:0] = 16'b11000000_11000000; //0
          4'd1 : encoding[15:0] = 16'b11000000_11111001; //1
          4'd2 : encoding[15:0] = 16'b11000000_10100100; //2
          4'd3 : encoding[15:0] = 16'b11000000_10110000; //3
          4'd4 : encoding[15:0] = 16'b11000000_10011001; //4
          4'd5 : encoding[15:0] = 16'b11000000_10010010; //5
          4'd6 : encoding[15:0] = 16'b11000000_10000010; //6
          4'd7 : encoding[15:0] = 16'b11000000_11111000; //7
          4'd8 : encoding[15:0] = 16'b11000000_10000000; //8
          4'd9 : encoding[15:0] = 16'b11000000_10010000; //9
          4'd10: encoding[15:0] = 16'b11111001_11000000; //10
		endcase
	end	
	assign display = encoding[15:0];
endmodule

