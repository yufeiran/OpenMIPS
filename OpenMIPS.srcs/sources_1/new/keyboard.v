`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/07/23 22:43:09
// Design Name: 
// Module Name: keyboard
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
module ps2_keyboard_driver(clk_in,rst_n,read,ps2k_clk,ps2k_data,sm_bit,sm_seg,ps2_state,int,wb_cyc_i,wb_stb_i,wb_we_i,wb_sel_i,wb_adr_i,wb_dat_i,wb_dat_o,wb_ack_o);

input clk_in;		//50M时钟信号
input rst_n;	//复位信号
input read;
input ps2k_clk;	//PS2接口时钟信号
input ps2k_data;		//PS2接口数据信号
wire [7:0] ps2_byte;	// 1byte键值，只做简单的按键扫描
output ps2_state;		//键盘当前状态，ps2_state=1表示有键被按下 
output reg [1:0] sm_bit='b01;
output reg [7:0]sm_seg;
output wire int;

 input wire wb_cyc_i;
 input wire wb_stb_i;
 input wire wb_we_i;
 input wire [3:0] wb_sel_i;
 input wire [`DataMemNumLog2-1:0] wb_adr_i;
 input wire [31:0] wb_dat_i;
 output reg [31:0] wb_dat_o;
 output reg        wb_ack_o;
 
 
 
 reg[7:0] ps2_asci;	//接收数据的相应ASCII码
reg [7:0]sm_seg_;

reg readflag=0;

reg int_r=0;
reg clk=0;
reg count=0;
always@(posedge clk_in)
begin
    if(count==0)
        clk=~clk;
    count<=count+1;
end

assign int=int_r;



    `define waitrom 0
    `define waitrom1 1
    `define finishrom 2   
    reg[1:0] state=`waitrom;  
    always@(posedge clk)
    begin
        if(wb_cyc_i&wb_stb_i)
        begin
            if(state==`waitrom)
                state<=`waitrom1;
            else if(state==`waitrom1)
                state<=`finishrom;
            else if(state==`finishrom&& !wb_ack_o)
			begin
                wb_ack_o<=1'b1;
				readflag<=1;
			end
        end
        else 
        begin
			readflag<=0;
            wb_ack_o<=1'b0;
            state<=`waitrom;
        end
    end

//------------------------------------------
reg ps2k_clk_r0,ps2k_clk_r1,ps2k_clk_r2;	//ps2k_clk状态寄存器
//wire pos_ps2k_clk; 	// ps2k_clk上升沿标志位
wire neg_ps2k_clk;	// ps2k_clk下降沿标志位
//设备发送向主机的数据在下降沿有效，首先检测PS2k_clk的下降沿
//利用上面逻辑赋值语句可以提取得下降沿，neg_ps2k_clk为高电平时表示数据可以被采集
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			ps2k_clk_r0 <= 1'b0;
			ps2k_clk_r1 <= 1'b0;
			ps2k_clk_r2 <= 1'b0;
		end
	else begin								//锁存状态，进行滤波
			ps2k_clk_r0 <= ps2k_clk;
			ps2k_clk_r1 <= ps2k_clk_r0;
			ps2k_clk_r2 <= ps2k_clk_r1;
		end
end
 
assign neg_ps2k_clk = ~ps2k_clk_r1 & ps2k_clk_r2;	//下降沿
 
//-----------------数据采集-------------------------
	/*
	帧结构：设备发往主机数据帧为11比特，（主机发送数据包为12bit） 
			1bit start bit ,This is always 0,
			 8bit data bits, 
			 1 parity bit,(odd parity)校验位，奇校验，
			 data bits 为偶数个1时该位为1，
			 data bits 为奇数个1时该位为0.
	         1bit stop bit ,this is always 1.
				num 范围为 'h00,'h0A;
	*/
reg[7:0] ps2_byte_r;		//PC接收来自PS2的一个字节数据存储器
reg[7:0] temp_data;			//当前接收数据寄存器
reg[3:0] num;				//计数寄存器
 
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			num <= 4'd0;
			temp_data <= 8'd0;
		end
	else if(neg_ps2k_clk) begin	//检测到ps2k_clk的下降沿
			case (num)
			 /*
		帧结构中数据位为一个字节，且低位在前，高位在后，
		这里要定义一个buf,size is one Byte.
	 */   
				4'd0:	num <= num+1'b1;
				4'd1:	begin
							num <= num+1'b1;
							temp_data[0] <= ps2k_data;	//bit0
						end
				4'd2:	begin
							num <= num+1'b1;
							temp_data[1] <= ps2k_data;	//bit1
						end
				4'd3:	begin
							num <= num+1'b1;
							temp_data[2] <= ps2k_data;	//bit2
						end
				4'd4:	begin
							num <= num+1'b1;
							temp_data[3] <= ps2k_data;	//bit3
						end
				4'd5:	begin
							num <= num+1'b1;
							temp_data[4] <= ps2k_data;	//bit4
						end
				4'd6:	begin
							num <= num+1'b1;
							temp_data[5] <= ps2k_data;	//bit5
						end
				4'd7:	begin
							num <= num+1'b1;
							temp_data[6] <= ps2k_data;	//bit6
						end
				4'd8:	begin
							num <= num+1'b1;
							temp_data[7] <= ps2k_data;	//bit7
						end
				4'd9:	begin
							num <= num+1'b1;	//奇偶校验位，不做处理
						end
				4'd10: begin
							num <= 4'd0;	// num清零
						end
				default: ;
				endcase
		end	
end
 
reg key_f0;		//松键标志位，置1表示接收到数据8'hf0，再接收到下一个数据后清零
reg ps2_state_r;	//键盘当前状态，ps2_state_r=1表示有键被按下 
//+++++++++++++++数据处理开始++++++++++++++++=============
always @ (posedge clk or negedge rst_n) begin	//接收数据的相应处理，这里只对1byte的键值进行处理
	if(!rst_n) begin
			key_f0 <= 1'b0;
			ps2_state_r <= 1'b0;
		end
	else if(num==4'd10) ///一帧数据是否采集完。
			begin	//刚传送完一个字节数据
					if(temp_data == 8'hf0)begin
					    key_f0 <= 1'b1;//判断该接收数据是否为断码
					    int_r<=1'b0;
					 end
				else
					begin
					//========================理解困难==================================
						if(!key_f0) 
								begin	//说明有键按下
									ps2_state_r <= 1'b1;
									ps2_byte_r <= temp_data;	//锁存当前键值
									wb_dat_o<={24'd0,ps2_asci};
									int_r<=1'b1;
								end
						else 
								begin
									ps2_state_r <= 1'b0;
									key_f0 <= 1'b0;
									int_r<=1'b0;
								end
					//=====================================================
					end
			end
    else 
    begin
        if(readflag==1)
        begin
            int_r<=1'b0;
        end
    end
end
/*+++++++++++++等效写法+++++++++++++++++++++++++++++
reg key_released;//收到码段后是否松开
reg [7:0] ps2_byte;
always @(posedge clk or negedge rst)
begin
	if(!rst)
	 key_released<='b0;
	else if(cnt=='h0A)//一帧数据是否采集完。
		begin
			if(ps2_byte_buf==8'hF0)//数据为段码f0
				key_released<='b1;//松开标志位置位
			else
				key_released<='b0;
		end
end
always @ (posedge clk or negedge rst) 
begin             
  if(!rst)
    key_pressed<= 0;
  else if (cnt == 4'hA)                 // 采集完一个字节？ 
  begin      
    if (!key_released)                  // 有键按过？
    begin 
      ps2_byte<= ps2_byte_buf;      // 锁存当前键值
      key_pressed <= 'b1;                 // 按下标志置一
    end
    else 
      key_pressed <= 'b0;                 // 按下标志清零
  end
end 
*/
 

 
always @ (ps2_byte_r) begin
	case (ps2_byte_r)		//键值转换为ASCII码，这里做的比较简单，只处理字母
		8'h15: ps2_asci <= 8'h51;	//Q
		8'h1d: ps2_asci <= 8'h57;	//W
		8'h24: ps2_asci <= 8'h45;	//E
		8'h2d: ps2_asci <= 8'h52;	//R
		8'h2c: ps2_asci <= 8'h54;	//T
		8'h35: ps2_asci <= 8'h59;	//Y
		8'h3c: ps2_asci <= 8'h55;	//U
		8'h43: ps2_asci <= 8'h49;	//I
		8'h44: ps2_asci <= 8'h4f;	//O
		8'h4d: ps2_asci <= 8'h50;	//P				  	
		8'h1c: ps2_asci <= 8'h41;	//A
		8'h1b: ps2_asci <= 8'h53;	//S
		8'h23: ps2_asci <= 8'h44;	//D
		8'h2b: ps2_asci <= 8'h46;	//F
		8'h34: ps2_asci <= 8'h47;	//G
		8'h33: ps2_asci <= 8'h48;	//H
		8'h3b: ps2_asci <= 8'h4a;	//J
		8'h42: ps2_asci <= 8'h4b;	//K
		8'h4b: ps2_asci <= 8'h4c;	//L
		8'h1a: ps2_asci <= 8'h5a;	//Z
		8'h22: ps2_asci <= 8'h58;	//X
		8'h21: ps2_asci <= 8'h43;	//C
		8'h2a: ps2_asci <= 8'h56;	//V
		8'h32: ps2_asci <= 8'h42;	//B
		8'h31: ps2_asci <= 8'h4e;	//N
		8'h3a: ps2_asci <= 8'h4d;	//M
		8'h45:ps2_asci<=8'h30;      //0
		8'h16:ps2_asci<=8'h31;
		8'h1e:ps2_asci<=8'h32;
		8'h26:ps2_asci<=8'h33;
		8'h25:ps2_asci<=8'h34;
		8'h2e:ps2_asci<=8'h35;
		8'h36:ps2_asci<=8'h36;
		8'h3d:ps2_asci<=8'h37;
		8'h3e:ps2_asci<=8'h38;
		8'h46:ps2_asci<=8'h39;    //9
		8'h29:ps2_asci<=8'h20;    //空格
		8'h66:ps2_asci<=8'h08;    //backSpace
		8'h5a:ps2_asci<=8'h0a;    //enter
        8'h75:ps2_asci<=8'h26;    //up
		8'h72:ps2_asci<=8'h28;    //down
		8'h6B:ps2_asci<=8'h25;    //left
		8'h74:ps2_asci<=8'h27;    //right
		default: ;
		endcase
end
 
assign ps2_byte = ps2_asci;	 
assign ps2_state = ps2_state_r;
//==================keyboard driver part over======================
 
//=======================1KHz div====display part start===================	
		parameter N2=50000;
		reg clk3=1'b0;
		reg [16:0]count3=17'd0;
	//assign clk_out=clk3;	
		
	always @(posedge clk or negedge rst_n)
	begin
		if (!rst_n)
		  begin
			count3<=17'd0;
			clk3<=1'b0;
		  end
		else
			if(count3<N2-1)
				begin
					count3<=count3+1'b1;
					if(count3<(N2/2-1))
					  clk3<=1'b0;
					else
					  clk3<=1'b1;
				end 
			else
			begin
				count3<=17'd0;
				clk3<=1'b0;
			end	
	end
//==================state select================
reg[3:0] Num;
always @(posedge clk3)
begin
	case (sm_bit)
	'b01:  begin
	           Num<=ps2_byte[3:0];
			
			sm_bit<='b10;
		end
	'b10:  begin
	           Num<=ps2_byte[7:4];
				
				sm_bit<='b01;
			end
	default:
			Num<='b0;
	endcase
	/*if(sm_bit=='b01)
	   begin
			Num<=ps2_byte[3:0];
			sm_bit<='b10;
		end
	else if(sm_bit=='b10)
        begin
				Num<=ps2_byte[7:4];
				sm_bit<='b01;
			end
		*/	
end
//=========================================================
  always @ (Num)//
	begin
		case (Num)  
			4'h0 : sm_seg_ = 8'h3f;   // "0"
			4'h1 : sm_seg_ = 8'h06;   // "1"
			4'h2 : sm_seg_ = 8'h5b;   // "2"
			4'h3 : sm_seg_ = 8'h4f;   // "3"
			4'h4 : sm_seg_ = 8'h66;   // "4"
			4'h5 : sm_seg_ = 8'h6d;   // "5"//共阴极数码管表
			4'h6 : sm_seg_ = 8'h7d;   // "6"
			4'h7 : sm_seg_ = 8'h07;   // "7"
			4'h8 : sm_seg_ = 8'h7f;   // "8"
			4'h9 : sm_seg_ = 8'h6f;   // "9"
			4'ha : sm_seg_ = 8'h77;   // "a"
			4'hb : sm_seg_ = 8'h7c;   // "b"
			4'hc : sm_seg_ = 8'h39;   // "c"
			4'hd : sm_seg_ = 8'h5e;   // "d"
			4'he : sm_seg_ = 8'h79;   // "e"
			4'hf : sm_seg_ = 8'h71;   // "f"
		endcase 
		sm_seg=~sm_seg_;
    end
 
//==============================================
endmodule

