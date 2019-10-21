`timescale 1ns/1ps
module led_blink(
	clk,
	reset_n,
	led_fpga,
	ledm_sel,
	sp_clk,
	sp_dat,
	sp_ratch
	);
	input	wire	clk;	// 25MHz
	input	wire	reset_n;
	output reg led_fpga;
	output reg [2:0] ledm_sel;
	output sp_clk;	// Serial-para clock
	output sp_dat;	// serial-para data
	output sp_ratch;	// serial-para ratch
	
	reg [31:0] ctr;	// counter for time counting
	reg [31:0] ctr2;	// counter for time counting
	reg dot;
	reg [7:0] num0;
	reg [4:0] led8;
	
	reg [4:0] state595;
	
	reg req595;
	wire ack595;
//	reg state_led_update;
/*	
	always @ ( posedge clk ) begin
		if ( cnt_clk_for_subclk595 == 8'd100 ) begin
			cnt_clk_for_subclk595 <= 8'd0;
			subclk595 <= 1'b1;
		end else begin
			cnt_clk_for_subclk595 <= cnt_clk_for_subclk595 + 8'd1;
			subclk595 <= 1'b0;
		end
	end
*/	

	always @ (posedge clk)
	begin
		if ( ctr>=32'd25000000 ) begin
			ctr <= 32'h0000_0000;
			led_fpga <= (~led_fpga);
		end
		else begin
			if ( (ctr & 32'h0080_0000) == 32'h0080_0000 ) begin
				ledm_sel <= 3'd6;
			end
			else if ( (ctr & 32'h0000_0FFF) == 32'h0000_0000 ) begin
				if ( ledm_sel >= 3'd4 )
					ledm_sel <= 3'd0;
				else
					ledm_sel <= ledm_sel + 3'd1;
			end
			
			ctr <= ctr + 32'd1;
		end
	end


	always @ ( posedge clk or negedge reset_n ) begin
		if ( reset_n == 1'b0 ) begin
			ctr2 <= 32'h0;
			num0 <= 8'd0;
			req595 <= 1'b0;
			dot <= 1'd0;
		end else 
		if ( ctr2 >= 32'd25000000 ) begin
			ctr2 <= 32'h0;
			num0 <= 8'd0;
		end else begin
			if ( (ctr2 & 32'h0000_001F) == 32'h0000_0010 ) begin
				if ( req595 == 1'b0 && ack595 == 1'b0 ) begin
					req595 <= 1'b1;
				end
			end else if ( req595 == 1'b1 && ack595 == 1'b1 ) begin
				req595 <= 1'b0;
				num0 <= num0 + 8'd1;
			end	

			ctr2 <= ctr2+32'd1;
		end
	end
	
	ledm_code ledm_code1( .clk(clk), .reset_n(reset_n), .code(num0), .dot(dot), .req595(req595), .ack595(ack595), .sp_clk(sp_clk), .sp_dat(sp_dat), .sp_ratch(sp_ratch) ); 

endmodule

//
// digit桁目の7segに表示する情報code
//
module ledm_code(
	clk,
	reset_n,
	code,
	dot,
	req595,
	ack595,
	sp_clk,
	sp_dat,
	sp_ratch
	);
	input	wire	clk;	// 25MHz
	input	wire	reset_n;
	input wire [7:0] code;		// code for this digit's 7seg LED
	input wire dot;				// dot LED
	input wire req595;
	output reg ack595;
	output reg sp_clk;	// Serial-para clock
	output reg sp_dat;	// serial-para data
	output reg sp_ratch;	// serial-para ratch
	
	reg [7:0] cnt;	// counter for time counting
	reg subclk595;
	
	reg [4:0] state595;
	reg [7:0] ledcode;
	
	wire [7:0] ledcode2;
	wire ledcode_bit;
	
/*	
	always @ ( posedge clk or negedge reset_n ) begin
		if ( reset_n == 1'b0 ) begin
			cnt <= 8'd0;
		end else 
		if ( cnt == 8'd100 ) begin
			cnt <= 8'd0;
			subclk595 <= 1'b1;
		end else begin
			cnt <= cnt + 8'd1;
			subclk595 <= 1'b0;
		end
	end
*/	


//	always @ ( posedge subclk595 ) begin
	always @ ( posedge clk or negedge reset_n ) begin
		if ( reset_n == 1'b0 ) begin
			sp_clk <= 1'b0;
			sp_ratch <= 1'b0;
			sp_dat <= 1'b0;
			state595 <= 5'd0;
			ack595 <= 1'b0;
		end else if (state595 == 5'd0 ) begin
			if ( req595 == 1'b1 ) begin
				sp_clk <= 1'b0;
//				ledcode <= segdec(code[3:0]);
			// sp_dat <= ledcode[state595[4:1]];
//				sp_dat <= ~ledcode2[state595[4:1]];
				sp_dat <= ledcode_bit;
//				sp_dat <= code[state595[4:1]];
				state595 <= state595 + 5'd1;
//				ack595 <= 1'b1;
			end
		end else if ( state595 == 5'd17 ) begin
			// ack595 を2clk分の長さにするため
			state595 <= state595 + 5'd1;
			
		end else if ( state595 == 5'd18 ) begin
			ack595 <= 1'b0;
			state595 <= 5'd0;
		
		end else if ( state595[0] == 1'b0 ) begin
			sp_clk <= 1'b0;
			if ( state595 == 5'd14 ) begin
				sp_ratch <= 1'b0;
//				sp_dat <= code[7];
				sp_dat <= ledcode_bit;
			end else if ( state595 == 5'd16 ) begin
				sp_ratch <= 1'b1;
				ack595 <= 1'b1;
			end else begin
				sp_dat <= ledcode_bit;
//				sp_dat <= code[state595[4:1]];
			end
			
			state595 <= state595 + 5'd1;
		end else begin 
			sp_clk <= 1'b1;
			state595 <= state595 + 5'd1;
		end
	end

assign ledcode2 = {segdec( code ), dot};	// a,b,c,d,e,f,g,dot   595にはLSBから入れていく必要あり。
assign ledcode_bit = ~ledcode2[state595[4:1]];
	
function [6:0] segdec;
input [3:0] din;
begin
	case ( din )
		4'h0: segdec = 7'b1111_110;	// a,b,c,d,e,f,g
		4'h1: segdec = 7'b0110_000;
		4'h2: segdec = 7'b1101_101;
		4'h3: segdec = 7'b1111_001;
		4'h4: segdec = 7'b0110_011;
		4'h5: segdec = 7'b1011_011;
		4'h6: segdec = 7'b1011_111;
		4'h7: segdec = 7'b1110_000;
		4'h8: segdec = 7'b1111_111;
		4'h9: segdec = 7'b1111_011;
		default:	segdec = 7'bxxxx_xxx;
	endcase
end
endfunction
		
endmodule