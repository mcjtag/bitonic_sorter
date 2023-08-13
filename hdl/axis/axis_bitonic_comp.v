`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 17.05.2020 20:19:03
// Design Name: 
// Module Name: axis_bitonic_comp
// Project Name: axis_bitonic_sort
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

module axis_bitonic_comp #(
	parameter DATA_WIDTH = 16,
	parameter USER_WIDTH = 8,
	parameter POLARITY = 0,
	parameter SIGNED = 0
)
(
	input wire aclk,
	input wire aresetn,
	input wire [DATA_WIDTH*2-1:0]s_axis_tdata,
	input wire [USER_WIDTH*2-1:0]s_axis_tuser,
	input wire s_axis_tvalid,
	output wire s_axis_tready,
	input wire s_axis_tlast,
	output wire [DATA_WIDTH*2-1:0]m_axis_tdata,
	output wire [USER_WIDTH*2-1:0]m_axis_tuser,
	output wire m_axis_tvalid,
	input wire m_axis_tready,
	output wire m_axis_tlast
);

wire [DATA_WIDTH-1:0]data_a;
wire [DATA_WIDTH-1:0]data_b;
reg [DATA_WIDTH-1:0]data_h;
reg [DATA_WIDTH-1:0]data_l;
wire [USER_WIDTH-1:0]user_a;
wire [USER_WIDTH-1:0]user_b;
reg [USER_WIDTH-1:0]user_h;
reg [USER_WIDTH-1:0]user_l;
reg last;
reg op_done;
wire valid_i;
wire valid_o;
wire less;

assign valid_i = s_axis_tvalid & s_axis_tready;
assign valid_o = m_axis_tvalid & m_axis_tready;
assign s_axis_tready = (op_done ? m_axis_tready : 1'b1) & aresetn;
assign m_axis_tvalid = op_done & aresetn;
assign m_axis_tdata = {data_h,data_l};
assign m_axis_tuser = {user_h,user_l};
assign m_axis_tlast = last;

assign data_a = s_axis_tdata[DATA_WIDTH*1-1-:DATA_WIDTH];
assign data_b = s_axis_tdata[DATA_WIDTH*2-1-:DATA_WIDTH];
assign user_a = s_axis_tuser[USER_WIDTH*1-1-:USER_WIDTH];
assign user_b = s_axis_tuser[USER_WIDTH*2-1-:USER_WIDTH];
assign less = (SIGNED == 0) ? ($unsigned(data_a) < $unsigned(data_b)) : $signed(data_a) < $signed(data_b);

always @(posedge aclk) begin
	if (aresetn == 1'b0) begin
		data_h <= 0;
		data_l <= 0;
		user_h <= 0;
		user_l <= 0;
		last <= 1'b0;
	end else begin
		if (valid_i == 1'b1) begin
			if (POLARITY == 0) begin
				data_h <= (less) ? data_a : data_b;
				data_l <= (less) ? data_b : data_a;
				user_h <= (less) ? user_a : user_b;
				user_l <= (less) ? user_b : user_a;
			end else begin
				data_h <= (less) ? data_b : data_a;
				data_l <= (less) ? data_a : data_b;
				user_h <= (less) ? user_b : user_a;
				user_l <= (less) ? user_a : user_b;
			end
			last <= s_axis_tlast;
		end
	end
end

always @(posedge aclk) begin
	if (aresetn == 1'b0) begin
		op_done <= 1'b0;
	end else begin
		case ({valid_i,valid_o})
		2'b01: op_done <= 1'b0;
		2'b10: op_done <= 1'b1;
		default: op_done <= op_done;
		endcase
	end
end	

endmodule
