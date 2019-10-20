`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/20 21:35:14
// Design Name: 
// Module Name: wishbone_bus_if
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

module wishbone_bus_if(
    input   wire    clk,
    input   wire    rst,
    
    //来自ctrl模块
    input   wire[5:0] stall_i,
    input   wire    flush_i,

    //CPU侧的接口
    input   wire    cpu_ce_i,
    input   wire[`RegBus]   cpu_data_i,
    input   wire[`RegBus]   cpu_addr_i,
    input   wire    cpu_we_i,
    input   wire[3:0]   cpu_sel_i,
    output  reg[`RegBus]    cpu_data_o,


    //Wishbone侧的接口
    input   wire[`RegBus]   wishbone_data_i,
    input   wire            wishbone_ack_i,
    output  reg[`RegBus]    wishbone_addr_o,
    output  reg[`RegBus]    wishbone_data_o,
    output  reg             wishbone_we_o,
    output  reg[3:0]        wishbone_sel_o,
    output  reg             wishbone_stb_o,
    output  reg             wishbone_cyc_o,

    output  reg             stallreq

    );

    reg[1:0]    wishbone_state;         //保存Wishbone总线接口模块的状态
    reg[`RegBus]    rd_buf;             //寄存通过Wishboen总线接口访问到的数据

    //控制状态转化的时序电路
    always@(posedge clk)begin
        if(rst==`RstEnable)begin
            wishbone_state<=`WB_IDLE;
            wishbone_addr_o<=`ZeroWord;
            wishbone_data_o<=`ZeroWord;
            wishbone_we_o<=`WriteDisable;
            wishbone_sel_o<=4'b0000;
            wishbone_stb_o<=1'b0;
            wishbone_cyc_o<=1'b0;
            rd_buf<=`ZeroWord;
        end else begin
            case(wishbone_state)
                `WB_IDLE:begin                      //WB_IDLE状态
                    if((cpu_ce_i==1'b1)&&(flush_i==`False_v))begin
                        wishbone_stb_o<=1'b1;
                        wishbone_cyc_o<=1'b1;
                        wishbone_addr_o<=cpu_addr_i;
                        wishbone_data_o<=cpu_data_i;
                        wishbone_we_o<=cpu_we_i;
                        wishbone_sel_o<=cpu_sel_i;
                        wishbone_state<=`WB_BUSY;       //进入WB_BUSY状态
                        rd_buf<=`ZeroWord;
                    end
                end
                `WB_BUSY:begin                      //WB_BUSY状态
                    if(wishbone_ack_i==1'b1)begin
                        wishbone_stb_o<=1'b0;
                        wishbone_cyc_o<=1'b0;
                        wishbone_addr_o<=`ZeroWord;
                        wishbone_data_o<=`ZeroWord;
                        wishbone_we_o<=`WriteDisable;
                        wishbone_sel_o<=4'b0000;
                        wishbone_state<=`WB_IDLE;       //进入WB_BUSY状态
                        if(cpu_we_i==`WriteDisable)begin
                            rd_buf<=wishbone_data_i;
                        end
                        if(stall_i!=6'b000000)begin 
                            //进入WB_WAIT_FOR_STALL状态
                            wishbone_state<=`WB_WAIT_FOR_STALL;
                        end
                    end else if(flush_i==`True_v)begin
                        wishbone_stb_o<=1'b0;
                        wishbone_cyc_o<=1'b0;
                        wishbone_addr_o<=`ZeroWord;
                        wishbone_data_o<=`ZeroWord;
                        wishbone_we_o<=`WriteDisable;
                        wishbone_sel_o<=4'b0000;
                        wishbone_state<=`WB_IDLE;       //进入WB_BUSY状态
                    end
                end
                `WB_WAIT_FOR_STALL:begin    //WB_WAIT_FOR_STALL状态
                    if(stall_i==6'b000000)begin
                        wishbone_state<=`WB_IDLE;   //进入WB_IDLE状态
                    end
                end
                default:begin
                end
            endcase
        end     //if
    end     //always


    //给处理器接口信号赋值的组合电路
    always@(*)begin
        if(rst==`RstEnable)begin
            stallreq<=`NoStop;
            cpu_data_o<=`ZeroWord;
        end else begin
            stallreq<=`NoStop;
            case(wishbone_state)
                `WB_IDLE:begin      //WB_IDLE状态
                    if((cpu_ce_i==1'b1)&&(flush_i==`False_v))begin
                        stallreq<=`Stop;
                        cpu_data_o<=`ZeroWord;
                    end
                end
                `WB_BUSY:begin      //WB_BUSY状态
                    if(wishbone_ack_i==1'b1)begin
                        stallreq<=`NoStop;
                        if(wishbone_we_o==`WriteDisable)begin
                            cpu_data_o<=wishbone_data_i;
                        end else begin
                            cpu_data_o<=`ZeroWord;
                        end
                    end else begin
                        stallreq<=`Stop;
                        cpu_data_o<=`ZeroWord;
                    end
                end
                `WB_WAIT_FOR_STALL:begin  //WB_WAIT_FOR_STALL状态
                    stallreq<=`NoStop;
                    cpu_data_o<=rd_buf;
                end
                default:begin
                end
            endcase
        end
    end

endmodule
