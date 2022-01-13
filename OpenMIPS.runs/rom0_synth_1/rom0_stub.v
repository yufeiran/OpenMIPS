// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Thu Jan 13 07:40:31 2022
// Host        : DESKTOP-5BPV03O running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub E:/codehub/OpenMIPS_final/OpenMIPS.runs/rom0_synth_1/rom0_stub.v
// Design      : rom0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a100tcsg324-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_3,Vivado 2019.1" *)
module rom0(clka, ena, addra, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,addra[14:0],douta[31:0]" */;
  input clka;
  input ena;
  input [14:0]addra;
  output [31:0]douta;
endmodule