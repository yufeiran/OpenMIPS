`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/04/07 16:39:46
// Design Name: 
// Module Name: vga800x600
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


module vga1024x768(
    input wire i_clk,
    input wire i_pix_stb,
    input wire i_rst,
    output wire o_hs,
    output wire o_vs,
    output wire o_blanking,
    output wire o_active,
    output wire o_screenend,
    output wire o_animate,
    output wire [9:0] o_x,
    output wire [9:0] o_y
    );
    
    localparam HS_STA=24;
    localparam HS_END=24+136;
    localparam HA_STA=24+136+144;
    localparam VS_STA=768+3;
    localparam VS_END=768+3+6;
    localparam VA_END=768;
    localparam LINE=1328;
    localparam SCREEN=806;
    
    reg [10:0] h_count;      
    reg [10:0] v_count;
    
    assign o_hs=~((h_count>=HS_STA)&(h_count<HS_END));
    assign o_vs=~((v_count>=VS_STA)&(v_count<VS_END));
    
    assign o_x=(h_count<HA_STA)?0:(h_count-HA_STA);
    assign o_y=(v_count>=VA_END)?(VA_END-1):(v_count);
    
    assign o_blanking = ((h_count<HA_STA)|(v_count>VA_END-1));
    
    assign o_active=~((h_count<HA_STA)|(v_count>VA_END-1));
    
    assign o_screenend=((v_count==SCREEN-1)&(h_count==LINE));
    
    assign o_animate=((v_count==VA_END-1)&(h_count==LINE));
    
    always@(posedge i_clk)
    begin
        if(i_rst)
        begin
            h_count<=0;
            v_count<=0;
        end
        if(i_pix_stb)   //once per pixel
        begin
             if(h_count==LINE)
             begin 
                h_count<=0;
                v_count<=v_count+1;
             end
             else
                h_count<=h_count+1;
                
             if(v_count==SCREEN)
                v_count<=0;
          end
       end
    
endmodule
