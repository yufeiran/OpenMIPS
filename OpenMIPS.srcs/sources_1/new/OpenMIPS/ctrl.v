`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/15 12:11:41
// Design Name: 
// Module Name: ctrl
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

module ctrl(
    input wire rst,
    input wire stallreq_from_id,
    input wire stallreq_from_ex,
    input wire stallreq_from_if,
    input wire stallreq_from_mem,

    input wire inst_tlb_refill,
    input wire inst_tlb_invalid,
    input wire data_tlb_refill,
    input wire data_tlb_invalid,
    input wire data_tlb_modify,

    input wire [31:0] excepttype_i,
    input wire [`RegBus]    cp0_epc_i,

    output reg[5:0] stall,
    output reg[`RegBus]     new_pc,
    output reg              flush

    );
    
    always@(*)begin
        if(rst==`RstEnable)begin
            stall<=6'b000000;
            flush<=1'b0;
            new_pc<=`ZeroWord;
        end else if(excepttype_i!=`ZeroWord||inst_tlb_refill==1'b1||inst_tlb_invalid==1'b1||data_tlb_refill==1'b1
        ||data_tlb_invalid==1'b1||data_tlb_modify==1'b1)begin
            flush<=1'b1;
            stall<=6'b000000;
            case(excepttype_i)
                32'h00000001:begin
                    new_pc<=32'h00000020;   //中断
                end
                32'h00000008:begin
                    new_pc<=32'h00000040;   //系统调用异常syscall
                end
                32'h0000000a:begin
                    new_pc<=32'h00000040;   //无效指令异常
                end
                32'h0000000d:begin
                    new_pc<=32'h00000040;   //自陷异常
                end
                32'h0000000c:begin
                    new_pc<=32'h00000040;   //溢出异常
                end
                32'h0000000e:begin
                    new_pc<=cp0_epc_i;      //异常返回指令eret
                end
                default:begin
                    if(inst_tlb_refill==1'b1||inst_tlb_invalid==1'b1)begin
                        new_pc<=32'h00000200;
                    end
                    else if(data_tlb_refill==1'b1||data_tlb_invalid==1'b1)begin
                        new_pc<=32'h00000380;
                    end
                    else if(data_tlb_modify==1'b1)begin
                        new_pc<=32'h00000380;
                    end
                end
            endcase
        end else if(stallreq_from_mem==`Stop)begin
            stall<=6'b011111;
            flush<=1'b0;
        end else if(stallreq_from_ex==`Stop)begin
            stall<=6'b001111;
            flush<=1'b0;
        end else if(stallreq_from_id==`Stop)begin
            stall<=6'b000111;
            flush<=1'b0;
        end else if(stallreq_from_if==`Stop)begin
            stall<=6'b000111;
            flush<=1'b0;
        end else begin
            stall<=6'b000000;
            flush<=1'b0;
            new_pc<=`ZeroWord;
        end     //if
    end     //always
endmodule
