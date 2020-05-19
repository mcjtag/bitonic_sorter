`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 10.02.2018 12:29:58
// Design Name: 
// Module Name: bitonic_node
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

module bitonic_node #(
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

localparam COMP_NUM = 2**ORDER;

genvar i;

generate for (i = 0; i < COMP_NUM; i = i + 1) begin: COMP
	wire [DATA_WIDTH-1:0]A;
	wire [DATA_WIDTH-1:0]B;
	wire [DATA_WIDTH-1:0]H;
	wire [DATA_WIDTH-1:0]L;
	
	assign A = data_in[DATA_WIDTH*(i + 1 + COMP_NUM * 0)-1-:DATA_WIDTH];
	assign B = data_in[DATA_WIDTH*(i + 1 + COMP_NUM * 1)-1-:DATA_WIDTH];
	assign data_out[DATA_WIDTH*(i + 1 + COMP_NUM * 0)-1-:DATA_WIDTH] = H;
	assign data_out[DATA_WIDTH*(i + 1 + COMP_NUM * 1)-1-:DATA_WIDTH] = L;

	bitonic_comp #(
		.DATA_WIDTH(DATA_WIDTH),
		.POLARITY(POLARITY),
		.SIGNED(SIGNED)
	) comp_inst (
		.CLK(clk),
		.A(A),
		.B(B),
		.H(H),
		.L(L)
	);
end endgenerate

endmodule
