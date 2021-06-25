`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/24 16:34:31
// Design Name: 
// Module Name: wb_rom
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
`include"OpenMIPS/OpenMIPS.vh"

module wb_rom(
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wb_cyc_i,
    input wire wb_stb_i,
    input wire wb_we_i,
    input wire [3:0] wb_sel_i,
    input wire [`InstMemNumLog2-1:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    output reg        wb_ack_o
    );
    
    
    `define waitrom 0
    `define waitrom1 1
    `define finishrom 2   
    reg[1:0] state=`waitrom;  
    always@(posedge wb_clk_i)
    begin
        if(wb_cyc_i&wb_stb_i)
        begin
            if(state==`waitrom)
                state<=`waitrom1;
            else if(state==`waitrom1)
                state<=`finishrom;
            else if(state==`finishrom&& !wb_ack_o)
                wb_ack_o<=1'b1;
        end
        else 
        begin
            wb_ack_o<=1'b0;
            state<=`waitrom;
        end
    end
    
    wire [31:0] wb_dat_o_w;
    
    always@(posedge wb_clk_i)
    begin
        wb_dat_o<=wb_dat_o_w;
    end
    wire [14:0]addr_rom={2'b00,wb_adr_i[14:2]};
    
    rom_0 rom(.addra(addr_rom),.clka(wb_clk_i),.douta(wb_dat_o_w),.ena(1'b1));
    
endmodule
