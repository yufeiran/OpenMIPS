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
    
    wire [31:0] wr_data;
    
    assign wr_data[31:24]=wb_sel_i[3]?wb_dat_i[31:24]:wb_dat_o[31:24];
    assign wr_data[23:16]=wb_sel_i[3]?wb_dat_i[23:16]:wb_dat_o[23:16];
    assign wr_data[15:8]=wb_sel_i[3]?wb_dat_i[15:8]:wb_dat_o[15:8];
    assign wr_data[7:0]=wb_sel_i[3]?wb_dat_i[7:0]:wb_dat_o[7:0];
    
    `define waitrom 0
    `define finishrom 1   
    reg state;  
    always@(posedge wb_clk_i)
    begin
        if(wb_ack_o)
            wb_ack_o<=1'b0;
        else if(wb_cyc_i&wb_stb_i)
        begin
            if(state==`waitrom)
                state<=`finishrom;
            else if(!wb_ack_o)
                wb_ack_o<=1'b1;
        end
        else 
        begin
            wb_ack_o<=1'b0;
            state<=`waitrom;
        end
    end
    
    
    

    reg [31:0] ram[0:`InstMemNum-1];
    wire [31:0] wb_dat_o_w;
    
    always@(posedge wb_clk_i)
    begin
        wb_dat_o<=wb_dat_o_w;
    end
    
    
    rom_0 rom(.addra({2'b00,wb_adr_i[`InstMemNumLog2-1:2]}),.clka(wb_clk_i),.douta(wb_dat_o_w),.ena(1'b1));
    
endmodule
