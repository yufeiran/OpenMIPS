`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/10 16:39:37
// Design Name: 
// Module Name: openmips_min_sopc_tb
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

module openmips_min_sopc_tb(

    );
    
    reg CLOCK_50;
    reg rst;
    reg uart_in;
    wire uart_out;
    reg [15:0] gpio_in;
    wire [3:0] dtube_cs_n;
    wire [7:0] dtube_data;
    wire rst_n;
    
    initial begin
        CLOCK_50=1'b0;
        uart_in=1'b0;
        gpio_in=16'b0;
        forever #10 CLOCK_50=~CLOCK_50;
        
    end
    
    initial begin
        rst=`RstEnable;
        #195 rst=`RstDisable;
    end
    
    assign rst_n=~rst;
    
    openmips_min_sopc openmips_min_sopc0(
        .clk(CLOCK_50),
        .rst_n(rst_n),.uart_in(uart_in),
        .uart_out(uart_out),.gpio_i(gpio_in),
         .dtube_cs_n(dtube_cs_n),
        .dtube_data(dtube_data)
        );
    
endmodule
