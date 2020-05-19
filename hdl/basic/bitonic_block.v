`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 10.02.2018 13:22:07
// Design Name: 
// Module Name: bitonic_block
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

module bitonic_block #(
	parameter DATA_WIDTH = 16,
	parameter ORDER = 0,
	parameter POLARITY = 0,
	parameter SIGNED = 0
)
(
	input wire clk,
	input wire [DATA_WIDTH*2**(ORDER+1)-1:0]data_in,
	output wire [DATA_WIDTH*2**(ORDER+1)-1:0]data_out
);

localparam STAGES = ORDER + 1;
localparam STAGE_DATA_WIDTH = DATA_WIDTH*2**(ORDER+1);

wire [DATA_WIDTH*2**(ORDER+1)-1:0]stage_data[STAGES:0];

assign stage_data[0] = data_in;
assign data_out = stage_data[STAGES];

genvar stage;
genvar node;

generate for (stage = 0; stage < STAGES; stage = stage + 1) begin: BLOCK_STAGE
	localparam NODES = 2**stage;
	localparam NODE_ORDER = STAGES - stage - 1;
		
	wire [STAGE_DATA_WIDTH-1:0]stage_data_in;
	wire [STAGE_DATA_WIDTH-1:0]stage_data_out;
		
	assign stage_data_in = stage_data[stage];
	assign stage_data[stage + 1] = 	stage_data_out;
		
	for (node = 0; node < NODES; node = node + 1) begin: NODE
		localparam NODE_DATA_WIDTH = DATA_WIDTH*2**(NODE_ORDER+1);
		wire [NODE_DATA_WIDTH-1:0]node_data_in;
		wire [NODE_DATA_WIDTH-1:0]node_data_out;
			
		assign node_data_in = stage_data_in[NODE_DATA_WIDTH*(node + 1)-1-:NODE_DATA_WIDTH];
		assign stage_data_out[NODE_DATA_WIDTH*(node + 1)-1-:NODE_DATA_WIDTH] = node_data_out;
			
		bitonic_node #(
			.DATA_WIDTH(DATA_WIDTH),
			.ORDER(NODE_ORDER),
			.POLARITY(POLARITY),
			.SIGNED(SIGNED)
		) bitonic_node_inst (
			.clk(clk),
			.data_in(node_data_in),
			.data_out(node_data_out)
		);		
	end
end endgenerate

endmodule
