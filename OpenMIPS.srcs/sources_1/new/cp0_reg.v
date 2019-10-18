`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/18 22:10:04
// Design Name: 
// Module Name: cp0_reg
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

module cp0_reg(
    input wire          clk,
    input wire          rst,

    input wire          we_i,
    input wire [4:0]    waddr_i,
    input wire [4:0]    raddr_i,
    input wire [`RegBus]    data_i,

    input wire [5:0]    int_i,

    output reg[`RegBus] data_o,
    output reg[`RegBus] count_o,
    output reg[`RegBus] compare_o,
    output reg[`RegBus] status_o,
    output reg[`RegBus] cause_o,
    output reg[`RegBus] epc_o,
    output reg[`RegBus] config_o,
    output reg[`RegBus] prid_o,

    output reg          timer_int_o
    );

    always@(posedge clk)begin
        
        if(rst==`RstEnable)begin
            //Count寄存器的初始值，为0
            count_o<=`ZeroWord;

            //Compare寄存器的初始值，为0
            compare_o<=`ZeroWord;

            status_o<=32'b00010000000000000000000000000000;

            cause_o<=`ZeroWord;

            epc_o<=`ZeroWord;

            config_o<=32'b00000000000000001000000000000000;

            prid_o<=32'b00000000010011000000000100000010;

            timer_int_o<=`InterruptNotAssert;
        end else begin
            count_o<=count_o+1;
            cause_o[15:0]<=int_i;       //Cause的第10~15bit保存外部中断声明


            if(compare_o!=`ZeroWord && count_o==compare_o)begin
                timer_int_o<=`InterruptAssert;
            end

            if(we_i==`WriteEnable)begin
                case(waddr_i)
                    `CP0_REG_COUNT:begin
                        count_o<=data_i;
                    end
                    `CP0_REG_COMPARE:begin
                        compare_o<=data_i;
                        timer_int_o<=`InterruptNotAssert;
                    end
                    `CP0_REG_STATUS:begin
                        status_o<=data_i;
                    end
                    `CP0_REG_EPC:begin
                        epc_o<=data_i;
                    end
                    `CP0_REG_CAUSE:begin    
                        //Cause寄存器只有IP[1:0]\IV\WP字段是可写的
                        cause_o[9:8]<=data_i[9:8];
                        cause_o[23]<=data_i[23];
                        cause_o[22]<=data_i[22];
                    end
                endcase
            end
        end
    end

    always@(*)begin
        if(rst==`RstEnable)begin
            data_o<=`ZeroWord;
        end else begin
            case(raddr_i)
                `CP0_REG_COUNT:begin
                    data_o<=count_o;
                end
                `CP0_REG_COMPARE:begin
                    data_o<=compare_o;
                end
                `CP0_REG_STATUS:begin
                    data_o<=status_o;
                end
                `CP0_REG_CAUSE:begin
                    data_o<=cause_o;
                end
                `CP0_REG_EPC:begin
                    data_o<=epc_o;
                end
                `CP0_REG_PRId:begin
                    data_o<=prid_o;
                end
                `CP0_REG_CONFIG:begin
                    data_o<=config_o;
                end
                default:begin
                end
            endcase
        end
    end
            
endmodule
