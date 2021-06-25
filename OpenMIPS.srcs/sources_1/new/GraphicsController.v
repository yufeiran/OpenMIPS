`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/17 21:45:14
// Design Name: 
// Module Name: GraphicsController
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
module GraphicsController(
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wb_cyc_i,
    input wire wb_stb_i,
    input wire wb_we_i,
    input wire [3:0] wb_sel_i,
    input wire [`DataMemNumLog2-1:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    output reg        wb_ack_o,
    output wire VGA_HS_O,
    output wire VGA_VS_O,
    output wire [3:0] VGA_R,
    output wire [3:0] VGA_G,
    output wire [3:0] VGA_B
    );
    wire rst=wb_rst_i;  //复位信号处理
    
    reg[12:0] inputAddrShowRam=0;
    reg[7:0] inputDataShowRam=0;
    reg[7:0] inputDataOuputShowRam=0;
    wire[7:0] inputDataOuputShowRamW;
    reg weaShowRam=0;
    
    `define waitrom 0
    `define waitrom1 1
    `define finishrom 2   
    reg[1:0] instate=`waitrom;  
    always@(posedge wb_clk_i)
    begin
        if(wb_cyc_i&wb_stb_i)
        begin
            inputAddrShowRam<=wb_adr_i[12:0];
            inputDataShowRam<=wb_dat_i[7:0];
            if(instate==`waitrom)
                instate<=`waitrom1;
            else if(instate==`waitrom1)
                instate<=`finishrom;
            else if(instate==`finishrom&& !wb_ack_o)
                wb_ack_o<=1'b1;
        end
        else 
        begin
            wb_ack_o<=1'b0;
            instate<=`waitrom;
        end
    end
    
    always@(posedge wb_clk_i)
    begin
        inputDataOuputShowRam<=inputDataOuputShowRamW;
        wb_dat_o<={24'd0,inputDataOuputShowRam};
    end
    
    
    //=======================================================================================
    //VGA信号时钟生成器
    reg [15:0] cnt=16'd0;
    reg pix_stb;
    //1024 x 768 @ 70 Hz
    // need generate a 75MHz pixel strobe
    always@(posedge wb_clk_i)
        {pix_stb,cnt} <= cnt+16'hC000;       //divide by 4/3: (2^16)/4*3 = 0xC000
    //=======================================================================================
    wire [9:0] x;           // x坐标
    wire [9:0] y;            // y坐标
      
      //=======================================================================================
    //实例化vga显示
    vga1024x768 display(.i_clk(wb_clk_i),.i_pix_stb(pix_stb),.i_rst(rst),.o_hs(VGA_HS_O),.o_vs(VGA_VS_O),.o_x(x),.o_y(y));
    //=======================================================================================
     
    //=======================================================================================
    //RAM
    reg[6:0] AsciiAddr;
    wire [127:0] AsciiDataW;
    reg [127:0]AsciiData=0;

    
    blk_mem_gen_0 ascii(.addra(AsciiAddr),.clka(wb_clk_i),.douta(AsciiDataW),.ena(1'b1));
    

    
    reg[12:0] vgaAddrShowRam=0;
    wire [7:0] vgaDataShowRamW;
    reg [7:0]vgaDataShowRam=0;
    wire vgaWriteEnable=wb_we_i&wb_cyc_i&wb_stb_i&(instate==1);
    
    blk_mem_gen_1 showRam(.addra(inputAddrShowRam),.clka(wb_clk_i),.dina(inputDataShowRam),.ena(1'b1),.wea(vgaWriteEnable),
    .addrb(vgaAddrShowRam),.clkb(wb_clk_i),.doutb(vgaDataShowRamW),.enb(1'b1));
    //=======================================================================================
     
    reg [7:0] DrawAscii=8'd72;
    reg [5:0] lineNow=0;
    reg [4:0] lineNowX=0;
    reg [3:0] lineBuffer=0;
    reg [4:0] state=0;
    reg [4:0] next_state=0;
    reg [10:0] drawX=11'd50; //待绘制的符号位置起始
    reg [9:0] drawY=11'd70;
    reg [4:0] drawHeight=5'd16;
    reg [4:0] drawWidth=5'd8;
    
    reg [127:0] wordbuf=128'd0;
    reg [5:0] lineNowCount=6'd0; //读取的字的行数

    reg isDrawPoint=0; //最终绘制的数据
    reg [7:0] loadAsciiAddr=0;
    reg [10:0] nowYInShowRam=0; //在showram里面的位置
    reg [9:0] nowXInShowRam=0;
    

    reg [12:0] writeAddr=0;
    
    reg [1023:0] screenlinebuf=0;
    
    always@(posedge wb_clk_i or posedge wb_rst_i)
    begin
        if(wb_rst_i)begin
            state<=0;
        end
        else begin
            state<=next_state;
        end
    end
    
    
    always@(posedge wb_clk_i)
    begin
        case(state)
        0:begin
         //初始化状态
            lineNow<=0;
            lineBuffer<=0;
            isDrawPoint<=0;
            lineNowX<=0;
             wordbuf<=128'd0;
             screenlinebuf<=0;
 
            next_state<=state+1;
        end
        1:  //等待VGA到行末尾
        begin
            if(VGA_HS_O==0)
            begin
                nowYInShowRam<=y>>4;
                nowXInShowRam<=0;
                screenlinebuf<=1024'd0;
                next_state<=state+1;
            end
            else if(x==10'h3ff)
            begin
                screenlinebuf<=1024'd0;
            end
        end
        2:  //获取当前ASCII值
        begin
            nowYInShowRam<=y>>4;
            vgaAddrShowRam<=nowYInShowRam*128+nowXInShowRam;
            next_state<=state+1;
        end
        3: //获取当前点阵数据
        begin
             AsciiAddr<=(vgaDataShowRamW[7:0]>32)?(vgaDataShowRamW[7:0]-32):0;
             lineNow<=y-nowYInShowRam*16;
             next_state<=state+1;
        end
        4:
        begin
            if(lineNow<8)
            begin
               screenlinebuf[nowXInShowRam*8]<=AsciiDataW[(15-0)*8+lineNow];
               screenlinebuf[nowXInShowRam*8+1]<=AsciiDataW[(15-1)*8+lineNow];
               screenlinebuf[nowXInShowRam*8+2]<=AsciiDataW[(15-2)*8+lineNow];
               screenlinebuf[nowXInShowRam*8+3]<=AsciiDataW[(15-3)*8+lineNow];
               screenlinebuf[nowXInShowRam*8+4]<=AsciiDataW[(15-4)*8+lineNow];
               screenlinebuf[nowXInShowRam*8+5]<=AsciiDataW[(15-5)*8+lineNow];
               screenlinebuf[nowXInShowRam*8+6]<=AsciiDataW[(15-6)*8+lineNow];
               screenlinebuf[nowXInShowRam*8+7]<=AsciiDataW[(15-7)*8+lineNow];
            end
            else 
            begin
               screenlinebuf[nowXInShowRam*8]<=AsciiDataW[(15-(0+8))*8+(lineNow-8)];
               screenlinebuf[nowXInShowRam*8+1]<=AsciiDataW[(15-(1+8))*8+(lineNow-8)];
               screenlinebuf[nowXInShowRam*8+2]<=AsciiDataW[(15-(2+8))*8+(lineNow-8)];
               screenlinebuf[nowXInShowRam*8+3]<=AsciiDataW[(15-(3+8))*8+(lineNow-8)];
               screenlinebuf[nowXInShowRam*8+4]<=AsciiDataW[(15-(4+8))*8+(lineNow-8)];
               screenlinebuf[nowXInShowRam*8+5]<=AsciiDataW[(15-(5+8))*8+(lineNow-8)];
               screenlinebuf[nowXInShowRam*8+6]<=AsciiDataW[(15-(6+8))*8+(lineNow-8)];
               screenlinebuf[nowXInShowRam*8+7]<=AsciiDataW[(15-(7+8))*8+(lineNow-8)];
            end
            next_state<=state+1;
            if(next_state!=state)begin
                 nowXInShowRam<=nowXInShowRam+1;
            end
            if(nowXInShowRam>=128)
            begin
                next_state<=state+1;
            end
            else 
            begin
               next_state<=2; 
            end
        end
        5:
        begin
            if(VGA_HS_O==1)
            begin
              next_state<=1;
            end
        end
        endcase
    end
    
    
    wire vga_r_data=screenlinebuf[x];
    wire vga_g_data=screenlinebuf[x];
    wire vga_b_data=screenlinebuf[x];
    
    assign VGA_R[0]=vga_r_data;
    assign VGA_R[1]=vga_r_data;
    assign VGA_R[2]=vga_r_data;
    assign VGA_R[3]=vga_r_data;

    assign VGA_G[0]=vga_g_data;
    assign VGA_G[1]=vga_g_data;
    assign VGA_G[2]=vga_g_data;
    assign VGA_G[3]=vga_g_data;

    assign VGA_B[0]=vga_b_data;
    assign VGA_B[1]=vga_b_data;
    assign VGA_B[2]=vga_b_data;
    assign VGA_B[3]=vga_b_data;

    
endmodule
