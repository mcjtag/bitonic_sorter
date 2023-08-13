`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 17.05.2020 20:17:43
// Design Name: 
// Module Name: axis_bitonic_block
// Project Name: axis_bitonic_sort
// Target Devices:
// Tool Versions:
// Description:
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// License: MIT
//  Copyright (c) 2020 Dmitry Matyunin
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

module axis_bitonic_block #(
	parameter DATA_WIDTH = 16,
	parameter USER_WIDTH = 8,
	parameter ORDER = 0,
	parameter POLARITY = 0,
	parameter SIGNED = 0
)
(
	input wire aclk,
	input wire aresetn,
	input wire [DATA_WIDTH*2**(ORDER+1)-1:0]s_axis_tdata,
	input wire [USER_WIDTH*2**(ORDER+1)-1:0]s_axis_tuser,
	input wire s_axis_tvalid,
	output wire s_axis_tready,
	input wire s_axis_tlast,
	output wire [DATA_WIDTH*2**(ORDER+1)-1:0]m_axis_tdata,
	output wire [USER_WIDTH*2**(ORDER+1)-1:0]m_axis_tuser,
	output wire m_axis_tvalid,
	input wire m_axis_tready,
	output wire m_axis_tlast
);

localparam STAGES = ORDER + 1;
localparam STAGE_DATA_WIDTH = DATA_WIDTH*2**(ORDER+1);
localparam STAGE_USER_WIDTH = USER_WIDTH*2**(ORDER+1);

wire [STAGE_DATA_WIDTH-1:0]axis_stage_tdata[STAGES:0];
wire [STAGE_USER_WIDTH-1:0]axis_stage_tuser[STAGES:0];
wire [STAGES:0]axis_stage_tvalid;
wire [STAGES:0]axis_stage_tready;
wire [STAGES:0]axis_stage_tlast;

assign axis_stage_tdata[0] = s_axis_tdata;
assign axis_stage_tuser[0] = s_axis_tuser;
assign axis_stage_tvalid[0] = s_axis_tvalid;
assign s_axis_tready = axis_stage_tready[0];
assign axis_stage_tlast[0] = s_axis_tlast;
assign m_axis_tdata = axis_stage_tdata[STAGES];
assign m_axis_tuser = axis_stage_tuser[STAGES];
assign m_axis_tvalid = axis_stage_tvalid[STAGES];
assign axis_stage_tready[STAGES] = m_axis_tready;
assign m_axis_tlast = axis_stage_tlast[STAGES];

genvar stage;
genvar node;

generate for (stage = 0; stage < STAGES; stage = stage + 1) begin: BLOCK_STAGE
	localparam NODES = 2**stage;
	localparam NODE_ORDER = STAGES - stage - 1;
		
	wire [STAGE_DATA_WIDTH-1:0]s_axis_stage_tdata;
	wire [STAGE_USER_WIDTH-1:0]s_axis_stage_tuser;
	wire s_axis_stage_tvalid;
	wire s_axis_stage_tready;
	wire s_axis_stage_tlast;
	wire [STAGE_DATA_WIDTH-1:0]m_axis_stage_tdata;
	wire [STAGE_USER_WIDTH-1:0]m_axis_stage_tuser;
	wire m_axis_stage_tvalid;
	wire m_axis_stage_tready;
	wire m_axis_stage_tlast;
		
	assign s_axis_stage_tdata = axis_stage_tdata[stage];
	assign s_axis_stage_tuser = axis_stage_tuser[stage];
	assign s_axis_stage_tvalid = axis_stage_tvalid[stage];
	assign axis_stage_tready[stage] = s_axis_stage_tready;
	assign s_axis_stage_tlast = axis_stage_tlast[stage];
	assign axis_stage_tdata[stage + 1] = m_axis_stage_tdata;
	assign axis_stage_tuser[stage + 1] = m_axis_stage_tuser;
	assign m_axis_stage_tready = axis_stage_tready[stage + 1];
	assign axis_stage_tvalid[stage + 1] = m_axis_stage_tvalid;
	assign axis_stage_tlast[stage + 1] = m_axis_stage_tlast;
		
	for (node = 0; node < NODES; node = node + 1) begin: NODE
		localparam NODE_DATA_WIDTH = DATA_WIDTH*2**(NODE_ORDER+1);
		localparam NODE_USER_WIDTH = USER_WIDTH*2**(NODE_ORDER+1);
		
		wire [NODE_DATA_WIDTH-1:0]s_axis_node_tdata;
		wire [NODE_DATA_WIDTH-1:0]m_axis_node_tdata;
		
		wire [NODE_USER_WIDTH-1:0]s_axis_node_tuser;
		wire [NODE_USER_WIDTH-1:0]m_axis_node_tuser;
			
		assign s_axis_node_tdata = s_axis_stage_tdata[NODE_DATA_WIDTH*(node + 1)-1-:NODE_DATA_WIDTH];
		assign m_axis_stage_tdata[NODE_DATA_WIDTH*(node + 1)-1-:NODE_DATA_WIDTH] = m_axis_node_tdata;
		
		assign s_axis_node_tuser = s_axis_stage_tuser[NODE_USER_WIDTH*(node + 1)-1-:NODE_USER_WIDTH];
		assign m_axis_stage_tuser[NODE_USER_WIDTH*(node + 1)-1-:NODE_USER_WIDTH] = m_axis_node_tuser;
		
		if (node == 0) begin
			axis_bitonic_node #(
				.DATA_WIDTH(DATA_WIDTH),
				.USER_WIDTH(USER_WIDTH),
				.ORDER(NODE_ORDER),
				.POLARITY(POLARITY),
				.SIGNED(SIGNED)
			) abn_inst (
				.aclk(aclk),
				.aresetn(aresetn),
				.s_axis_tdata(s_axis_node_tdata),
				.s_axis_tuser(s_axis_node_tuser),
				.s_axis_tvalid(s_axis_stage_tvalid),
				.s_axis_tready(s_axis_stage_tready),
				.s_axis_tlast(s_axis_stage_tlast),
				.m_axis_tdata(m_axis_node_tdata),
				.m_axis_tuser(m_axis_node_tuser),
				.m_axis_tvalid(m_axis_stage_tvalid),
				.m_axis_tready(m_axis_stage_tready),
				.m_axis_tlast(m_axis_stage_tlast)
			);
		end else begin
			axis_bitonic_node #(
				.DATA_WIDTH(DATA_WIDTH),
				.USER_WIDTH(USER_WIDTH),
				.ORDER(NODE_ORDER),
				.POLARITY(POLARITY),
				.SIGNED(SIGNED)
			) abn_inst (
				.aclk(aclk),
				.aresetn(aresetn),
				.s_axis_tdata(s_axis_node_tdata),
				.s_axis_tuser(s_axis_node_tuser),
				.s_axis_tvalid(s_axis_stage_tvalid),
				.s_axis_tready(),
				.s_axis_tlast(s_axis_stage_tlast),
				.m_axis_tdata(m_axis_node_tdata),
				.m_axis_tuser(m_axis_node_tuser),
				.m_axis_tvalid(),
				.m_axis_tready(m_axis_stage_tready),
				.m_axis_tlast()
			);
		end
	end
end endgenerate

endmodule
