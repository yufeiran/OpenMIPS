`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/09 22:56:25
// Design Name: 
// Module Name: pc_reg
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

module pc_reg(
    input wire      clk,
    input wire      rst,
    input wire[5:0]  stall,     //来自控制模块CTRL
    output reg[`InstAddrBus] pc,
    output reg      ce
    );
    always@(posedge clk) begin
        if(rst==`RstEnable) begin
            ce<=`ChipDisable;       //复位的时候指令存储器被禁用
        end else begin
            ce<=`ChipEnable;        //复位结束后，指令存储器使能
        end
    end
    
    always@(posedge clk) begin
        if(ce ==`ChipDisable) begin
            pc<=32'h00000000;       //指令存储器禁用的时候，PC为0
        end else if(stall[0]==`NoStop) begin
            pc<=pc+4'h4;
        end else begin
            pc<=pc+4'h4;            //指令存储器使能的时候,PC的值每时钟周期加4
        end
    end
    
endmodule
