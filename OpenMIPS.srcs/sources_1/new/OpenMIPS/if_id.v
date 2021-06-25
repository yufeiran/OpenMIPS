`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/09 23:06:44
// Design Name: 
// Module Name: if_id
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
`include "OpenMIPS.vh"

module if_id(
    input wire clk,
    input wire rst,
    
    input wire [5:0] stall,

    input wire flush,
    
    //来自取址阶段的信号，其中宏定义InstBus表示指令宽度,为32
    input wire [`InstAddrBus]       if_pc,
    input wire [`InstBus]           if_inst,
    input wire inst_tlb_refillF, inst_tlb_invalidF,
    
    //对应译码阶段的信号
    output reg[`InstAddrBus]        id_pc,
    output reg[`InstBus]            id_inst,
    output reg inst_tlb_refillD, inst_tlb_invalidD
    );
    
    always@(posedge clk)begin
        if(rst==`RstEnable) begin
            id_pc<=`ZeroWord;   //复位的时候pc为0
            id_inst<=`ZeroWord; //复位的时候指令也为0，实际就是空指令
            inst_tlb_refillD    <= 0;
            inst_tlb_invalidD   <= 0;
        end else if(flush==1'b1)begin
            //flush==1表示异常发生，要清除流水线
            //所以复位id_pc,id_inst寄存器的值
            id_pc<=`ZeroWord;
            id_inst<=`ZeroWord;
            inst_tlb_refillD    <= 0;
            inst_tlb_invalidD   <= 0;
        end else if(stall[1]==`Stop && stall[2]==`NoStop)begin
            id_pc<=`ZeroWord;
            id_inst<=`ZeroWord;
            inst_tlb_refillD    <= 0;
            inst_tlb_invalidD   <= 0;
        end else if(stall[1]==`NoStop)begin
            id_pc<=if_pc;       //其余时刻向下传递取值阶段的值
            id_inst<=if_inst;
            inst_tlb_refillD    <= inst_tlb_refillF     ;
            inst_tlb_invalidD   <= inst_tlb_invalidF    ;
        end
    end
    
endmodule
