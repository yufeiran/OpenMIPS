`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/10 14:15:56
// Design Name: 
// Module Name: ex_mem
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

module ex_mem(

    input wire clk,
    input wire rst,
    
    //来自执行阶段的信息
    input wire [`RegAddrBus] ex_wd,
    input wire               ex_wreg,
    input wire [`RegBus]     ex_wdata,
    input wire [`RegBus]     ex_hi,
    input wire [`RegBus]     ex_lo,
    input wire               ex_whilo,
    
    input wire  [5:0]        stall,

    input wire [`DoubleRegBus] hilo_i,
    input wire [1:0]           cnt_i,

    input wire [`AluOpBus]  ex_aluop,
    input wire [`RegBus]    ex_mem_addr,
    input wire [`RegBus]    ex_reg2,

    output reg[`AluOpBus]   mem_aluop,
    output reg[`RegBus]     mem_mem_addr,
    output reg[`RegBus]     mem_reg2,
    
    //送到访存阶段的信息
    output reg  [`RegAddrBus] mem_wd,
    output reg                mem_wreg,
    output reg  [`RegBus]     mem_wdata,
    output reg  [`RegBus]     mem_hi,
    output reg  [`RegBus]     mem_lo,
    output reg                mem_whilo,

    //增加的输出接口
    output reg[`DoubleRegBus] hilo_o,
    output reg[1:0]           cnt_o
    );
    
    always@(posedge clk) begin
        if(rst==`RstEnable)begin
            mem_wd<=`NOPRegAddr;
            mem_wreg<=`WriteDisable;
            mem_wdata<=`ZeroWord;
            mem_hi<=`ZeroWord;
            mem_lo<=`ZeroWord;
            mem_whilo<=`WriteDisable;
            hilo_o<={`ZeroWord,`ZeroWord};
            cnt_o<=2'b00;
            mem_aluop<=`EXE_NOP_OP;
            mem_mem_addr<=`ZeroWord;
            mem_reg2<=`ZeroWord;
        end else if(stall[3]==`Stop && stall[4]==`NoStop)begin
            mem_wd<=`NOPRegAddr;
            mem_wreg<=`WriteDisable;
            mem_wdata<=`ZeroWord;
            mem_hi<=`ZeroWord;
            mem_lo<=`ZeroWord;
            mem_whilo<=`WriteDisable;
            hilo_o<=hilo_i;
            cnt_o<=cnt_i;
            mem_aluop<=`EXE_NOP_OP;
            mem_mem_addr<=`ZeroWord;
            mem_reg2<=`ZeroWord;
        end else if(stall[3]==`NoStop) begin
            mem_wd<=ex_wd;
            mem_wreg<=ex_wreg;
            mem_wdata<=ex_wdata;
            mem_hi<=ex_hi;
            mem_lo<=ex_lo;
            mem_whilo<=ex_whilo;
            hilo_o<={`ZeroWord,`ZeroWord};
            cnt_o<=2'b00;
            mem_aluop<=ex_aluop;
            mem_mem_addr<=ex_mem_addr;
            mem_reg2<=ex_reg2;
        end else begin 
            hilo_o<=hilo_i;
            cnt_o<=cnt_i;
        end     // if
     end    // always
endmodule
