`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/10 16:19:10
// Design Name: 
// Module Name: inst_rom
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

module inst_rom(
    input wire ce,
    input wire [`InstAddrBus] addr,
    output reg[`InstBus]    inst
    );
    
    //定义一个数组，大小是InstMemNum,元素宽度是InstBus
    reg[`InstBus] inst_mem[0:`InstMemNum-1];
    
    //使用文件inst_rom.data初始化指令存储器
    initial $readmemh("inst_rom.data",inst_mem);
    
    //当复位信号无效时，依据输入的地址，给出指令存储器ROM中对应的元素
    always@(*)begin
        if(ce==`ChipDisable) begin
            inst<=`ZeroWord;
        end else begin
            inst<=inst_mem[addr[`InstMemNumLog2+1:2]];
        end
     end
endmodule
