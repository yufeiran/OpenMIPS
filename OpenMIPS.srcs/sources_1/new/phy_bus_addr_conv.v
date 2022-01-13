//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2014 leishangwen@163.com                       ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
// Module:  phy_bus_addr_conv
// File:    phy_bus_addr_conv.v
// Author:  shyoshyo
// E-mail:  shyoshyo@qq.com
// Description: phy addr => bus addr    
// Revision: 1.0
//////////////////////////////////////////////////////////////////////
`include"OpenMIPS\OpenMIPS.vh"

`define DDRRAM_PHYSICAL_ADDR_BEGIN           32'h0000_0000
`define DDRRAM_PHYSICAL_ADDR_LEN             32'h0800_0000

`define UART_PHYSICAL_ADDR_BEGIN            32'h0800_0000
`define UART_PHYSICAL_ADDR_LEN              32'h0000_0008

`define GPIO_PHYSICAL_ADDR_BEGIN            32'h0900_0000
`define GPIO_PHYSICAL_ADDR_LEN              32'h0000_0010

`define FLASH_PHYSICAL_ADDR_BEGIN           32'h0A00_0000
`define FLASH_PHYSICAL_ADDR_LEN             32'h0100_0000

`define VGA_PHYSICAL_ADDR_BEGIN             32'h0B00_0000
`define VGA_PHYSICAL_ADDR_LEN               32'h0000_1800

`define KEYBOARD_PHYSICAL_ADDR_BEGIN        32'h0C00_0000
`define KEYBOARD_PHYSICAL_ADDR_LEN          32'h0000_0010




module phy_bus_addr_conv(
	input wire rst_n,

	input wire[`PhyAddrBus] phy_addr_i,
	output reg[`WishboneAddrBus] bus_addr_o
);
    wire [`PhyAddrBus] ddrram_index = ((phy_addr_i - `DDRRAM_PHYSICAL_ADDR_BEGIN));
    wire [`PhyAddrBus] uart_index = ((phy_addr_i - `UART_PHYSICAL_ADDR_BEGIN));
    wire [`PhyAddrBus] gpio_index = ((phy_addr_i - `GPIO_PHYSICAL_ADDR_BEGIN));
    wire [`PhyAddrBus] flash_index = ((phy_addr_i - `FLASH_PHYSICAL_ADDR_BEGIN));    
    wire [`PhyAddrBus] vga_index = ((phy_addr_i - `VGA_PHYSICAL_ADDR_BEGIN));  
    wire [`PhyAddrBus] keyboard_index = ((phy_addr_i - `KEYBOARD_PHYSICAL_ADDR_BEGIN));    


	always @(*)
		if (rst_n == `RstEnable)
		begin
			bus_addr_o <= `ZeroWord;
		end
		else
		begin
		    if(ddrram_index<`DDRRAM_PHYSICAL_ADDR_LEN)
		        bus_addr_o<=ddrram_index;
		    else if(uart_index<`UART_PHYSICAL_ADDR_LEN)
		        bus_addr_o<={8'h10,uart_index[23:0]};
		    else if(gpio_index<`GPIO_PHYSICAL_ADDR_LEN)
		        bus_addr_o<={8'h20,gpio_index[23:0]};
		    else if(flash_index<`FLASH_PHYSICAL_ADDR_LEN)
		        bus_addr_o<={8'h30,flash_index[23:0]};
		    else if(vga_index<`VGA_PHYSICAL_ADDR_LEN)
		        bus_addr_o<={8'h40,vga_index[23:0]};
		    else if(keyboard_index<`KEYBOARD_PHYSICAL_ADDR_LEN)
		        bus_addr_o<={8'h50,keyboard_index[23:0]};
			else
				bus_addr_o <= ~`ZeroWord;
		end
endmodule