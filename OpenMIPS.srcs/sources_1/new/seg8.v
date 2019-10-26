/////////////////////////////////////////////////////////////////////////////
//特权同学 携手 威视锐V3学院 精心打造 Xilinx FPGA开发板系列
//工程硬件平台： Xilinx Artix7 FPGA 
//开发套件型号： STAR 入门FPGA开发套件
//版   权  申   明： 本例程由《深入浅出玩转FPGA》作者“特权同学”原创，
//				仅供STAR开发套件学习使用，谢谢支持
//官方淘宝店铺： http://myfpga.taobao.com/
//最新资料下载： http://pan.baidu.com/s/1kU4WWvH
/////////////////////////////////////////////////////////////////////////////
module seg8(
			input clk_i,		//时钟信号，100MHz
			input rst,	//复位信号，低电平有效
			input[31:0] gpio_out,	//数码管显示数据，[15:12]--数码管千位，[11:8]--数码管百位，[7:4]--数码管十位，[3:0]--数码管个位
			output reg[3:0] dtube_cs_n,	//7段数码管位选信号
			output reg[7:0] dtube_data	//7段数码管段选信号（包括小数点为8段）
		);

//-------------------------------------------------
//参数定义3
    wire rst_n=~rst;
   reg clk=0;
   reg [1:0]clk_count=0;
   always@(posedge clk_i or negedge rst_n)begin
        if(!rst_n)begin
            clk<=1'b0;
            clk_count=0;
        end else begin
            clk_count<=clk_count+1'b1;
            if(clk_count==2'b11)
            begin
                clk<=~clk;
            end
        end
   end

//数码管位选 0~3 对应输出
parameter	CSN		= 4'b1111,
			CS0		= 4'b1110,
			CS1		= 4'b1101,
			CS2		= 4'b1011,
			CS3		= 4'b0111;

//-------------------------------------------------
//分时显示数据控制单元
reg[8:0] current_display_data;	//当前显示数据
reg[7:0] div_cnt;	//分时计数器

	//分时计数器
always @(posedge clk or negedge rst_n)
	if(!rst_n) div_cnt <= 8'd0;
	else div_cnt <= div_cnt+1'b1;

	//显示数据
always @(posedge clk or negedge rst_n)
	if(!rst_n) dtube_data <= 8'h0;
	else begin
		case(div_cnt)
			8'hff: dtube_data <= (gpio_out[7:0]|8'h80);
			8'h3f: dtube_data <= (gpio_out[15:8]|8'h80);
			8'h7f: dtube_data <= (gpio_out[23:16]|8'h80);
			8'hbf: dtube_data <= (gpio_out[31:24]|8'h80);
			default: ;
		endcase
	end
		

	//位选译码
always @(posedge clk or negedge rst_n)
	if(!rst_n) dtube_cs_n <= CSN;
	else begin
		case(div_cnt[7:6])
			2'b00: dtube_cs_n <= CS0;
			2'b01: dtube_cs_n <= CS1;
			2'b10: dtube_cs_n <= CS2;
			2'b11: dtube_cs_n <= CS3;
			default:  dtube_cs_n <= CSN;
		endcase
	end
endmodule

