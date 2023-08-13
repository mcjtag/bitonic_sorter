`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 17.05.2020 20:16:25
// Design Name: 
// Module Name: axis_bitonic_sort
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

module axis_bitonic_sort #(
	parameter DATA_WIDTH = 16,	//
	parameter USER_WIDTH = 8,	// 
	parameter CHAN_NUM = 32,	// 
	parameter DIR = 0,			// 0 - ascending, 1 - descending
	parameter SIGNED = 0,		// 0 - unsigned, 1 - signed
	parameter IS_TLAST = 1,		// 1 - enable, 0 - disable
	parameter IS_TREADY = 1,	// 1 - enable, 0 - disable,
	parameter IS_TUSER = 1		// 1 - enable, 0 - disable
)
(
	input wire aclk,
	input wire aresetn,
	input wire [DATA_WIDTH*CHAN_NUM-1:0]s_axis_tdata,
	input wire [USER_WIDTH*CHAN_NUM-1:0]s_axis_tuser,
	input wire s_axis_tvalid,
	output wire s_axis_tready,
	input wire s_axis_tlast,
	output wire [DATA_WIDTH*CHAN_NUM-1:0]m_axis_tdata,
	output wire [USER_WIDTH*CHAN_NUM-1:0]m_axis_tuser,
	output wire m_axis_tvalid,
	input wire m_axis_tready,
	output wire m_axis_tlast
);

localparam CHAN_ACT = 2**$clog2(CHAN_NUM);
localparam CHAN_ADD = CHAN_ACT - CHAN_NUM;

localparam STAGES = $clog2(CHAN_ACT);
localparam STAGE_DATA_WIDTH = DATA_WIDTH*CHAN_ACT;
localparam STAGE_USER_WIDTH = USER_WIDTH*CHAN_ACT;

wire [STAGE_DATA_WIDTH-1:0]axis_stage_tdata[STAGES:0];
wire [STAGE_USER_WIDTH-1:0]axis_stage_tuser[STAGES:0];
wire [STAGE_DATA_WIDTH-1:0]m_axis_tdata_tmp;
wire [STAGE_USER_WIDTH-1:0]m_axis_tuser_tmp;
wire [STAGES:0]axis_stage_tvalid;
wire [STAGES:0]axis_stage_tlast;
wire [STAGES:0]axis_stage_tready;

assign axis_stage_tdata[0] = {s_axis_tdata, {CHAN_ADD{SIGNED?{1'b1,{(DATA_WIDTH-1){1'b0}}}:{DATA_WIDTH{1'b0}}}}};
assign axis_stage_tuser[0] = IS_TUSER ? s_axis_tuser : {STAGE_USER_WIDTH{1'b0}};
assign axis_stage_tvalid[0] = s_axis_tvalid;
assign s_axis_tready = IS_TREADY ? axis_stage_tready[0] : 1'b1;
assign axis_stage_tlast[0] = IS_TLAST ? s_axis_tlast : 1'b0;
assign m_axis_tdata_tmp = axis_stage_tdata[STAGES];
assign m_axis_tuser_tmp = IS_TUSER ? axis_stage_tuser[STAGES] : {STAGE_USER_WIDTH{1'b0}};
assign m_axis_tdata = DIR ? m_axis_tdata_tmp[DATA_WIDTH*CHAN_NUM-1:0] : m_axis_tdata_tmp[DATA_WIDTH*CHAN_ACT-1-:DATA_WIDTH*CHAN_NUM];
assign m_axis_tuser = DIR ? m_axis_tuser_tmp[USER_WIDTH*CHAN_NUM-1:0] : m_axis_tuser_tmp[USER_WIDTH*CHAN_ACT-1-:USER_WIDTH*CHAN_NUM];
assign m_axis_tvalid = axis_stage_tvalid[STAGES];
assign axis_stage_tready[STAGES] = IS_TREADY ? m_axis_tready : 1'b1;
assign m_axis_tlast = IS_TLAST ? axis_stage_tlast[STAGES] : 1'b0;

genvar stage;
genvar block;

generate for (stage = 0; stage < STAGES; stage = stage + 1) begin: SORT_STAGE
	localparam BLOCKS = CHAN_ACT / 2**(stage+1);
	localparam BLOCK_ORDER = stage;
		
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

	for (block = 0; block < BLOCKS; block = block + 1) begin: BLOCK
		localparam BLOCK_DATA_WIDTH = DATA_WIDTH*2**(BLOCK_ORDER+1);
		localparam BLOCK_USER_WIDTH = USER_WIDTH*2**(BLOCK_ORDER+1);
		localparam BLOCK_POLARITY = DIR ? (~block & 1) : (block & 1);
			
		wire [BLOCK_DATA_WIDTH-1:0]s_axis_block_tdata;
		wire [BLOCK_DATA_WIDTH-1:0]m_axis_block_tdata;
		wire [BLOCK_USER_WIDTH-1:0]s_axis_block_tuser;
		wire [BLOCK_USER_WIDTH-1:0]m_axis_block_tuser;
			
		assign s_axis_block_tdata = s_axis_stage_tdata[BLOCK_DATA_WIDTH*(block+1)-1-:BLOCK_DATA_WIDTH];
		assign m_axis_stage_tdata[BLOCK_DATA_WIDTH*(block+1)-1-:BLOCK_DATA_WIDTH] = m_axis_block_tdata;
		assign s_axis_block_tuser = s_axis_stage_tuser[BLOCK_USER_WIDTH*(block+1)-1-:BLOCK_USER_WIDTH];
		assign m_axis_stage_tuser[BLOCK_USER_WIDTH*(block+1)-1-:BLOCK_USER_WIDTH] = m_axis_block_tuser;
		
		if (block == 0) begin
			axis_bitonic_block #(
				.DATA_WIDTH(DATA_WIDTH),
				.USER_WIDTH(USER_WIDTH),
				.ORDER(BLOCK_ORDER),
				.POLARITY(BLOCK_POLARITY),
				.SIGNED(SIGNED)
			) abb_inst (
				.aclk(aclk),
				.aresetn(aresetn),
				.s_axis_tdata(s_axis_block_tdata),
				.s_axis_tuser(s_axis_block_tuser),
				.s_axis_tvalid(s_axis_stage_tvalid),
				.s_axis_tready(s_axis_stage_tready),
				.s_axis_tlast(s_axis_stage_tlast),
				.m_axis_tdata(m_axis_block_tdata),
				.m_axis_tuser(m_axis_block_tuser),
				.m_axis_tvalid(m_axis_stage_tvalid),
				.m_axis_tready(m_axis_stage_tready),
				.m_axis_tlast(m_axis_stage_tlast)
			);
		end else begin
			axis_bitonic_block #(
				.DATA_WIDTH(DATA_WIDTH),
				.USER_WIDTH(USER_WIDTH),
				.ORDER(BLOCK_ORDER),
				.POLARITY(BLOCK_POLARITY),
				.SIGNED(SIGNED)
			) abb_inst (
				.aclk(aclk),
				.aresetn(aresetn),
				.s_axis_tdata(s_axis_block_tdata),
				.s_axis_tuser(s_axis_block_tuser),
				.s_axis_tvalid(s_axis_stage_tvalid),
				.s_axis_tready(),
				.s_axis_tlast(),
				.m_axis_tdata(m_axis_block_tdata),
				.m_axis_tuser(m_axis_block_tuser),
				.m_axis_tvalid(),
				.m_axis_tready(m_axis_stage_tready),
				.m_axis_tlast()
			);
		end
	end
end endgenerate

endmodule
