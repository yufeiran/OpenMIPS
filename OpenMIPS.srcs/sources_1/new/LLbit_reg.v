`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/18 12:19:30
// Design Name: 
// Module Name: LLbit_reg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include"OpenMIPS.vh"

module LLbit_reg(
    input wire clk,
    input wire rst,

    //异常是否发生，1表示异常发生，0表示没有异常
    input wire flush,

    input wire LLbit_i,
    input wire we,

    //LLbit寄存器的值
    output reg LLbit_o

    );

    always@(posedge clk)begin
        
        if(rst==`RstEnable)begin
            LLbit_o<=1'b0;
        end else if((flush==1'b1))begin
            LLbit_o<=1'b0;
        end else if((we==`WriteEnable))begin
            LLbit_o<=1'b1;
        end 
    end
endmodule
