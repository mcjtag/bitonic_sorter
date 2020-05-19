`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 05.02.2018 14:00:10
// Design Name: 
// Module Name: comparator
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

module bitonic_comp #(
	parameter DATA_WIDTH = 16,
	parameter POLARITY = 0,
	parameter SIGNED = 0
)
(
	input wire CLK,
	input wire [DATA_WIDTH-1:0]A,
	input wire [DATA_WIDTH-1:0]B,
	output wire [DATA_WIDTH-1:0]H,
	output wire [DATA_WIDTH-1:0]L,
	output wire O
);

reg [DATA_WIDTH-1:0]H_REG;
reg [DATA_WIDTH-1:0]L_REG;
reg O_REG;

wire LESS;

assign H = H_REG;
assign L = L_REG;
assign O = O_REG;

generate
	if (SIGNED == 0) begin
		assign LESS = $unsigned(A) < $unsigned(B);	
	end else begin
		assign LESS = $signed(A) < $signed(B);
	end
	
	if (POLARITY == 0) begin
		always @(posedge CLK) begin
			H_REG <= (LESS) ? A : B;
			L_REG <= (LESS) ? B : A;
			O_REG <= LESS;
		end
	end else begin
		always @(posedge CLK) begin
			H_REG <= (LESS) ? B : A;
			L_REG <= (LESS) ? A : B;
			O_REG <= ~LESS;
		end
	end
endgenerate

endmodule
