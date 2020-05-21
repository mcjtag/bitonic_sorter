`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 10.02.2018 14:30:25
// Design Name: 
// Module Name: bitonic_sort
// Project Name: bitonic_sort
// Target Devices:
// Tool Versions:
// Description:
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// License: MIT
//  Copyright (c) 2019 Dmitry Matyunin
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
// 
//////////////////////////////////////////////////////////////////////////////////

module bitonic_sort #(
	parameter DATA_WIDTH = 16,	// 
	parameter CHAN_NUM = 8,		// 
	parameter DIR = 0,		// 0 - ascending, 1 - descending
	parameter SIGNED = 0		// 0 - unsigned, 1 - signed
)
(
	input wire clk,
	input wire [DATA_WIDTH*CHAN_NUM-1:0]data_in,
	output wire [DATA_WIDTH*CHAN_NUM-1:0]data_out
);

localparam CHAN_ACT = 2**$clog2(CHAN_NUM);
localparam CHAN_ADD = CHAN_ACT - CHAN_NUM;

localparam STAGES = $clog2(CHAN_ACT);
localparam STAGE_DATA_WIDTH = DATA_WIDTH*CHAN_ACT;

wire [STAGE_DATA_WIDTH-1:0]stage_data[STAGES:0];
wire [STAGE_DATA_WIDTH-1:0]data_out_tmp;

assign stage_data[0] = {data_in, {CHAN_ADD{SIGNED?{1'b1,{(DATA_WIDTH-1){1'b0}}}:{DATA_WIDTH{1'b0}}}}};
assign data_out_tmp = stage_data[STAGES];
assign data_out = DIR ? data_out_tmp[DATA_WIDTH*CHAN_NUM-1:0] : data_out_tmp[DATA_WIDTH*CHAN_ACT-1-:DATA_WIDTH*CHAN_NUM];

genvar stage;
genvar block;

generate for (stage = 0; stage < STAGES; stage = stage + 1) begin: SORT_STAGE
	localparam BLOCKS = CHAN_ACT / 2**(stage+1);
	localparam BLOCK_ORDER = stage;
		
	wire [STAGE_DATA_WIDTH-1:0]stage_data_in;
	wire [STAGE_DATA_WIDTH-1:0]stage_data_out;
		
	assign stage_data_in = stage_data[stage];
	assign stage_data[stage + 1] = stage_data_out;

	for (block = 0; block < BLOCKS; block = block + 1) begin: BLOCK
		localparam BLOCK_DATA_WIDTH = DATA_WIDTH*2**(BLOCK_ORDER+1);
		localparam BLOCK_POLARITY = DIR ? (~block & 1) : (block & 1);
			
		wire [BLOCK_DATA_WIDTH-1:0]block_data_in;
		wire [BLOCK_DATA_WIDTH-1:0]block_data_out;
			
		assign block_data_in = stage_data_in[BLOCK_DATA_WIDTH*(block+1)-1-:BLOCK_DATA_WIDTH];
		assign stage_data_out[BLOCK_DATA_WIDTH*(block+1)-1-:BLOCK_DATA_WIDTH] = block_data_out;
		
		bitonic_block #(
			.DATA_WIDTH(DATA_WIDTH),
			.ORDER(BLOCK_ORDER),
			.POLARITY(BLOCK_POLARITY),
			.SIGNED(SIGNED)
		) bitonic_block_inst (
			.clk(clk),
			.data_in(block_data_in),
			.data_out(block_data_out)
		);
	end
end endgenerate

endmodule
