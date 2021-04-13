/*
	Author: 	Chandler Cabrera
	Course:	EECS3216
	
	Culminating Course Project: 2D Pong Game displayed on monitor through a VGA Signal
*/

module PongProject(
	input clk,
	input rst,
	input up,
	input down,
	input speed,
	output hsync, 
	output vsync,
	output [3:0] red, 
	output [3:0]green, 
	output [3:0]blue,
	output [15:0] player_scoreboard,
	output [15:0] enemy_scoreboard
	);
	
	// register and wire reset 
	reg rst_reg = 0;
	wire reset;
	
	// four counters for clock divider
	reg [20:0] i = 0;
	reg [20:0] j = 0;
	reg [25:0] k = 0;
	
	// colour registers
	reg [3:0] r;
	reg [3:0] g;
	reg [3:0] b;
	
	//BALL coordinates and direction of travel
	reg [15:0] ball_x = 220;
	reg [15:0] ball_y = 275;
	reg ball_x_dir = 1;
	reg ball_y_dir = 1;
	
	//PADDLE position, top of paddle, bottom of paddle
	reg [15:0] paddle_x = 200;
	reg [15:0] paddle_y = 275;
	reg [15:0] paddle_bottom;
	reg [15:0] paddle_top;
	
	//ENEMY paddle position, top of paddle, bottom of paddle
	reg [15:0] paddle2_x = 710;
	reg [15:0] paddle2_y = 275;
	reg [15:0] paddle2_bottom;
	reg [15:0] paddle2_top;
	
	reg [4:0] paddle_width = 5'b10100;
	
	//SCORE
	reg [6:0] score 		 = 7'b0000000;
	reg [6:0] enemy_score = 7'b0000000;
	
	//BALL SPAWN LOCATION
	parameter ball_start_x = 220;
	parameter ball_start_y = 275;
	
	//SCREEN BOUNDARY PARAMETERS
	parameter h_min = 143, h_max = 784, v_min = 34, v_max = 515;
	
	//GAME PARAMETERS and MODIFIERS
	parameter ball_slow = 2, ball_fast = 5, enemy_paddle_bonus = 5;
	reg[1:0] bounce_variance_x = 2'b01;
	reg[1:0] bounce_variance_y = 2'b01;
	
	//VARIOUS CLOCKS
	reg clk25 = 0;
	reg clk2  = 0;
	reg clk3  = 0;
	reg clkslow = 0;
	reg enemy_clk = 0;
	
	// HORIZONTAL SYNC AND VERTICAL SYNC RELATED
	reg enable_v_counter;
	reg [15:0] h_counter = 0;
	reg [15:0] v_counter = 0;
	
	SevenSegment p2_score_tracker(.clk(clk), .value(enemy_score), 	.display(enemy_scoreboard));
	SevenSegment p1_score_tracker(.clk(clk), .value(score), 			.display(player_scoreboard));
	
	// clock dividers to achieve 25MHz clock (for 60Hz display), slower clock for paddle control, and even slower clock for ball movement
	always @(posedge clk) begin
		clk25 <= ~clk25;
		
		if (i >= 625_000) begin
			clk2 <= ~ clk2;
			i <= 0;
		end else begin
			if (speed)
				i <= i + 10;
			else
				i <= i + 5;
		end
					
		if (j >= 625_000) begin
			clk3 <= ~clk3;
			j <= 0;
		end else begin
			if (speed)
				j <= j + ball_fast;
			else
				j <= j + ball_slow;
		end
		
		if (k >= 25_000_000) begin
			clkslow = ~clkslow;
			k <= 0;
		end else
			k <= k + 1;
	end
	
	//horizontal counter
	always @(posedge clk25) begin
		if (h_counter < 799) begin
			h_counter <= h_counter + 1;
			enable_v_counter <= 0;
		end
		else begin
			h_counter <= 0;
			enable_v_counter <= 1;
		end
	end
	
	//vertical counter
	always @(posedge clk25) begin
		if (enable_v_counter == 1'b1) begin
			if (v_counter < 524)
				v_counter <= v_counter + 1;
			else
				v_counter <= 0;
		end
	end
	
	// BALL MOVEMENT AND COLLISION HANDLING
	always @(posedge clk3) begin
		if (reset) begin
			ball_x = ball_start_x;
			ball_y = ball_start_y;
			ball_x_dir = 1;
			ball_y_dir = 1;
			score <= 0;
			enemy_score = 0;
		end
		
		if (ball_x <= h_min + 1) begin
				ball_x = ball_start_x;
				ball_y = ball_start_y;
				ball_x_dir = 1;
				ball_y_dir = 1;
				enemy_score = enemy_score + 1;
		end
		
		// ball exited screen right
			if (ball_x >= h_max - 1) begin
				ball_x = ball_start_x + 400;
				ball_y = ball_start_y;
				ball_x_dir = 0;
				ball_y_dir = ~ball_y_dir;
				score <= score + 1;
			end
			
		// collision occurred
			if (ball_x >= paddle_x && ball_x <= paddle_x + 1 && ball_y >= paddle_bottom && ball_y <= paddle_top) begin
				if ((up && ball_y_dir) || down && ~ball_y_dir) begin
					bounce_variance_y <= 2'b10;
					bounce_variance_x <= 2'b01;
				end else if ((up && ~ball_y_dir) || (down && ~ball_y_dir)) begin
					bounce_variance_x <= 2'b10;
					bounce_variance_y <= 2'b01;
				end else begin
					bounce_variance_x <= 2'b01;
					bounce_variance_y <= 2'b01;
				end
					
				ball_x_dir = ~ball_x_dir;	
				
			end else if (ball_x <= paddle2_x && ball_x >= paddle2_x - 1 && ball_y >= paddle2_bottom && ball_y <= paddle2_top) begin
				ball_x_dir = ~ball_x_dir;
			end
			
			if (ball_y >= (v_max - 3) || ball_y <= (v_min + 3))
				ball_y_dir = ~ball_y_dir;
				
			ball_x = (ball_x_dir) ? ball_x + bounce_variance_x : ball_x - bounce_variance_x;
			ball_y = (ball_y_dir) ? ball_y + bounce_variance_y : ball_y - bounce_variance_y;
	end

	
	// CONTROLLING THE PLAYER'S PADDLE
	always @(posedge clk2) begin

			if (up && ~down) begin
				if (paddle_y < v_max - paddle_width)
					paddle_y <= paddle_y + 1;
			end
			else if (~up && down) begin
				if (paddle_y > v_min + paddle_width)
					paddle_y <= paddle_y - 1;
			end	

		paddle_top    <= paddle_y + paddle_width;
		paddle_bottom <= paddle_y - paddle_width;	
	end
	
	//ENEMY AI BEHAVIOUR
	always @(posedge clk2) begin
		enemy_clk = ~enemy_clk;
		if (enemy_clk) begin
			if (ball_y > paddle2_y)
				paddle2_y <= paddle2_y + 1;
			else if (ball_y < paddle2_y)
				paddle2_y <= paddle2_y - 1;
		end else begin
			if (paddle2_y >= v_max - 250 && ~ball_y_dir && paddle2_y > ball_y)
				paddle2_y <= paddle2_y - 1;
			else if (ball_y <= v_min + 250 && ball_y_dir && paddle2_y < ball_y)
				paddle2_y <= paddle2_y + 1;
		end
		paddle2_top <= paddle2_y + paddle_width + enemy_paddle_bonus;
		paddle2_bottom <= paddle2_y - paddle_width - enemy_paddle_bonus;
	end


	// GAME STATE HANDLING
	always @(posedge clkslow) begin
		if (rst_reg)
			rst_reg = 0;
			
		if ((score >= 10 || enemy_score >= 10) && (up || down)) begin
			rst_reg = 1;
		end
	end
	
	
	// DRAWING THE SCENARIO ON THE BOARD	
	always @(posedge clk) begin
				if (score >= 10) begin
					r <= 4'h0;
					g <= 4'hF;
					b <= 4'h0;
				end else if (enemy_score >= 10) begin
					r <= 4'hF;
					g <= 4'h0;
					b <= 4'h0;					
				//draw ball
				end else if ((h_counter <= ball_x + 2 && h_counter >= ball_x && v_counter <= ball_y + 1 && v_counter >= ball_y - 1)) begin
					r <= 4'hF;
					g <= 4'hF;
					b <= 4'hF;
				// draw paddle
				end else if (v_counter >= paddle_bottom && v_counter <= paddle_top && h_counter == paddle_x) begin
					r <= 4'h0;
					g <= 4'hF;
					b <= 4'hF;
				// draw enemy paddle
				end else if (v_counter >= paddle2_bottom && v_counter <= paddle2_top && h_counter == paddle2_x) begin
					r <= 4'hF;
					g <= 4'h0;
					b <= 4'h0;	
				// draw background
				end else if (h_counter < h_max && h_counter > h_min && v_counter < v_max && v_counter > v_min) begin
					r <= 4'h0;
					g <= 4'h0;
					b <= 4'h0;
				end
	end
	
	assign hsync = (h_counter < 96) ? 1 : 0;
	assign vsync = (v_counter < 2) ? 1 : 0;
	
	assign red = r;
	assign green = g;
	assign blue = b;
	
	assign reset = (rst_reg || rst);
	
endmodule
	
	
	