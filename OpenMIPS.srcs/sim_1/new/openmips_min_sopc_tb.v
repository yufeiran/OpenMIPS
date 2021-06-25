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
    
    reg CLOCK_100;
    reg rst;
    reg uart_in;
    wire uart_out;
    reg flash_continue;
    reg [15:0] gpio_in;
    wire [3:0] dtube_cs_n;
    wire [7:0] dtube_data;
    wire rst_n;
    
    wire  cs_n;
    reg sdi;
    wire  sdo;
    wire  wp_n;
    wire  hld_n;
    
    
    wire [12:0] ddr2_addr;
    wire [2:0]  ddr2_ba;
    wire        ddr2_cas_n;
    wire [0:0]  ddr2_ck_n;
    wire [0:0]  ddr2_ck_p;
    wire [0:0]  ddr2_cke;
    wire        ddr2_ras_n;
    wire        ddr2_we_n;
    wire [15:0] ddr2_dq;
    wire [1:0]  ddr2_dqs_n;
    wire [1:0]  ddr2_dqs_p;
    wire [0:0]  ddr2_cs_n;
    wire [1:0]  ddr2_dm;
    wire [0:0]  ddr2_odt;
   
   
    initial begin
        CLOCK_100=1'b0;
        uart_in=1'b0;
        gpio_in=16'b0;
        flash_continue=1'b1;
      sdi=1'b0;
        forever #5 CLOCK_100=~CLOCK_100;
         
    end
    
    
    initial begin
        rst=`RstEnable;
        #195 rst=`RstDisable;
    end
    
    assign rst_n=~rst;
    openmips_min_sopc openmips_min_sopc0(
        .clk_in(CLOCK_100),
        .rst_n(rst_n),.uart_in(uart_in),
        .uart_out(uart_out),.gpio_i(gpio_in),
         .dtube_cs_n(dtube_cs_n),
        .dtube_data(dtube_data),
        .cs_n(cs_n),
        .sdi(sdi),
        .flash_continue(flash_continue),
      
        .sdo(sdo),
        .wp_n(wp_n),
        .hld_n(hld_n),
        
          //Memory interface ports
        .ddr2_addr(ddr2_addr),
        .ddr2_ba(ddr2_ba),
        .ddr2_cas_n(ddr2_cas_n),
        .ddr2_ck_n(ddr2_ck_n),
        .ddr2_ck_p(ddr2_ck_p),
        .ddr2_cke(ddr2_cke),
        .ddr2_ras_n(ddr2_ras_n),
        .ddr2_we_n(ddr2_we_n),
        .ddr2_dq(ddr2_dq),
        .ddr2_dqs_n(ddr2_dqs_n),
        .ddr2_dqs_p(ddr2_dqs_p),
        .ddr2_cs_n(ddr2_cs_n),
        .ddr2_dm(ddr2_dm),
        .ddr2_odt(ddr2_odt)
        /************tempLook********/

        
        );

   ddr2_model ddr2_model(
        .ck (ddr2_ck_p),
        .ck_n (ddr2_ck_n),
        .cke(ddr2_cke),
        .cs_n(ddr2_cs_n),
        .ras_n(ddr2_ras_n),
        .cas_n(ddr2_cas_n),
        .we_n(ddr2_we_n),
        .dm_rdqs(ddr2_dm),
        .ba(ddr2_ba),
        .addr(ddr2_addr),
        .dq(ddr2_dq),
        .dqs(ddr2_dqs_p),
        .dqs_n(ddr2_dqs_n),
        .rdqs_n(),
        .odt(ddr2_odt)
        );
   
   
endmodule
