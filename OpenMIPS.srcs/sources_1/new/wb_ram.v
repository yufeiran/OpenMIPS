`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/24 16:23:44
// Design Name: 
// Module Name: wb_ram
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

module wb_ram(
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wb_cyc_i,
    input wire wb_stb_i,
    input wire wb_we_i,
    input wire [3:0] wb_sel_i,
    input wire [`DataMemNumLog2-1:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    output reg        wb_ack_o
    );
    
    wire [31:0] wr_data;
    
    assign wr_data[31:24]=wb_sel_i[3]?wb_dat_i[31:24]:wb_dat_o[31:24];
    assign wr_data[23:16]=wb_sel_i[2]?wb_dat_i[23:16]:wb_dat_o[23:16];
    assign wr_data[15:8]=wb_sel_i[1]?wb_dat_i[15:8]:wb_dat_o[15:8];
    assign wr_data[7:0]=wb_sel_i[0]?wb_dat_i[7:0]:wb_dat_o[7:0];
    
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
    
    reg [31:0] ram[0:`DataMemNum-1];
    
    always@(posedge wb_clk_i)
    begin
        wb_dat_o<=ram[wb_adr_i[`DataMemNumLog2-1:2]];
        if(wb_cyc_i&wb_stb_i&wb_we_i&wb_ack_o)
            ram[wb_adr_i[`DataMemNumLog2-1:2]]<=wr_data;
    end
    
endmodule