`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/10 15:10:10
// Design Name: 
// Module Name: openmips
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

module openmips(
    input wire clk,
    input wire rst,

    
    input wire [`RegBus]    rom_data_i,
    output wire [`RegBus]   rom_addr_o,
    output wire             rom_ce_o,

    input wire [`RegBus]    ram_data_i,
    output wire [`RegBus]   ram_addr_o,
    output wire [`RegBus]   ram_data_o,
    output wire             ram_we_o,
    output wire [3:0]       ram_sel_o,
    output wire              ram_ce_o
    );
    
    //连接IF/ID模块与链接阶段ID模块的变量
    wire [`InstAddrBus] pc;
    wire [`InstAddrBus] id_pc_i;
    wire [`InstBus]     id_inst_i;
    
    
    //连接译码阶段ID模块输出与ID/EX模块的输入的变量
    wire [`AluOpBus] id_aluop_o;
    wire [`AluSelBus]   id_alusel_o;
    wire [`RegBus]      id_reg1_o;
    wire [`RegBus]      id_reg2_o;
    wire                id_wreg_o;
    wire[`RegAddrBus]   id_wd_o;
    wire id_is_in_delayslot_o;
    wire[`RegBus] id_link_address_o;
    wire[`RegBus] id_inst_o;
    
    //连接ID/EX模块输出与执行阶段EX模块的输入的变量
    wire [`AluOpBus] ex_aluop_i;
    wire [`AluSelBus] ex_alusel_i;
    wire [`RegBus]  ex_reg1_i;
    wire [`RegBus]  ex_reg2_i;
    wire            ex_wreg_i;
    wire [`RegAddrBus] ex_wd_i;
    wire ex_is_in_delayslot_i;
    wire[`RegBus] ex_link_address_i;
    wire[`RegBus] ex_inst_i;
    
    //连接执行EX模块的输出与EX/MEM模块的输入的变量
    wire            ex_wreg_o;
    wire[`RegAddrBus] ex_wd_o;
    wire[`RegBus]    ex_wdata_o;
    wire[`RegBus]   ex_hi_o;
    wire[`RegBus]   ex_lo_o;
    wire ex_whilo_o;
    wire[`AluOpBus] ex_aluop_o;
    wire[`RegBus] ex_mem_addr_o;
    wire[`RegBus] ex_reg1_o;
    wire[`RegBus] ex_reg2_o;
    
    wire[1:0]       cnt_o;
    wire[`DoubleRegBus] hilo_temp_o;
    wire [1:0]      cnt_i;
    wire [`DoubleRegBus] hilo_temp_i;
  
    
    //连接EX/MEM模块的输出与访存阶段MEM模块的输入的变量
    wire            mem_wreg_i;
    wire[`RegAddrBus] mem_wd_i;
    wire[`RegBus]     mem_wdata_i;
    wire[`RegBus]     mem_hi_i;
    wire[`RegBus]     mem_lo_i;
    wire mem_whilo_i;
    wire[`AluOpBus]  mem_aluop_i;
    wire[`RegBus]    mem_mem_addr_i;
    wire[`RegBus]    mem_reg1_i;
    wire[`RegBus]    mem_reg2_i;
    
    //连接访存阶段MEM模块的输出与MEM/WB模块的输入的变量
    wire            mem_wreg_o;
    wire[`RegAddrBus] mem_wd_o;
    wire [`RegBus]  mem_wdata_o;
    wire [`RegBus] mem_hi_o;
    wire [`RegBus] mem_lo_o;
    wire mem_whilo_o;
    
    
    //连接MEM/WB模块的输出与回写阶段的输入的变量
    wire            wb_wreg_i;
    wire[`RegAddrBus] wb_wd_i;
    wire [`RegBus]   wb_wdata_i;
    wire [`RegBus]  wb_hi_i;
    wire [`RegBus]  wb_lo_i;
    wire  wb_whilo_i;
    
    //连接译码阶段ID模块与通用寄存器Regfile模块的变量
    wire            reg1_read;
    wire            reg2_read;
    wire[`RegBus]   reg1_data;
    wire[`RegBus]   reg2_data;
    wire[`RegAddrBus]reg1_addr;
    wire[`RegAddrBus]reg2_addr;
    
    wire[`RegBus]  hi;
    wire[`RegBus]  lo;
    
    //连接CTRL模块的变量
    wire [5:0] stall;
    wire stallreq_from_id;
    wire stallreq_from_ex;

    //连接DIV模块的变量
    wire signed_div;
    wire [`RegBus] div_opdata1;
    wire [`RegBus] div_opdata2;
    wire  div_start;
    wire [`DoubleRegBus] div_result;
    wire div_ready;

    wire is_in_delayslot_i;
    wire is_in_delayslot_o;
    wire next_inst_in_delayslot_o;
    wire id_branch_flag_o;
    wire[`RegBus]branch_target_address;
    
    pc_reg pc_reg0(
        .clk(clk),
        .rst(rst),
        .pc(pc),
        .ce(rom_ce_o),
        .stall(stall),
        .branch_flag_i(id_branch_flag_o),
        .branch_target_address_i(branch_target_address)
        );
    
    assign rom_addr_o=pc;       //指令存储器的输入地址是PC的值
    
    //IF/ID模块例化
    if_id if_id0(
        .clk(clk),.rst(rst),.if_pc(pc),
        .if_inst(rom_data_i),.id_pc(id_pc_i),
        .id_inst(id_inst_i),.stall(stall)
        );
    
    //译码阶段ID模块例化
    id id0(
        .rst(rst),.pc_i(id_pc_i),.inst_i(id_inst_i),
        
        //来自Regfile模块的输入
        .reg1_data_i(reg1_data),.reg2_data_i(reg2_data),
        
        .ex_wreg_i(ex_wreg_o),.ex_wdata_i(ex_wdata_o),.ex_wd_i(ex_wd_o),

        .mem_wreg_i(mem_wreg_o),.mem_wdata_i(mem_wdata_o),.mem_wd_i(mem_wd_o),

        .is_in_delayslot_i(is_in_delayslot_i),
        
        //送到regfile模块的信息
        .reg1_read_o(reg1_read),    .reg2_read_o(reg2_read),
        .reg1_addr_o(reg1_addr),    .reg2_addr_o(reg2_addr),

        .next_inst_in_delayslot_o(next_inst_in_delayslot_o),
        .branch_flag_o(id_branch_flag_o),
        .branch_target_address_o(branch_target_address),
        .link_addr_o(id_link_address_o),

        .is_in_delayslot_o(id_is_in_delayslot_o),
        
        //送到ID/EX模块的信息
        .inst_o(id_inst_o),
        .aluop_o(id_aluop_o),   .alusel_o(id_alusel_o),
        .reg1_o(id_reg1_o), .reg2_o(id_reg2_o),
        .wd_o(id_wd_o), .wreg_o(id_wreg_o),.stallreq(stallreq_from_id)
    );
    
    //通用寄存器Regfile模块例化
    regfile regfile1(
        .clk(clk),      .rst(rst),
        .we(wb_wreg_i), .waddr(wb_wd_i),
        .wdata(wb_wdata_i), .re1(reg1_read),
        .raddr1(reg1_addr),.rdata1(reg1_data),
        .re2(reg2_read),    .raddr2(reg2_addr),
        .rdata2(reg2_data)
    );
    
    // ID/EX模块例化
    id_ex id_ex0(
        .clk(clk),  .rst(rst),
        
        .id_inst(id_inst_o),
        .id_aluop(id_aluop_o),  .id_alusel(id_alusel_o),
        .id_reg1(id_reg1_o),    .id_reg2(id_reg2_o),
        .id_wd(id_wd_o),    .id_wreg(id_wreg_o),
        .stall(stall),
		.id_link_address(id_link_address_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot_o),		
	
        .ex_inst(ex_inst_i),
        .ex_aluop(ex_aluop_i),  .ex_alusel(ex_alusel_i),
        .ex_reg1(ex_reg1_i),.ex_reg2(ex_reg2_i),
        .ex_wd(ex_wd_i),.ex_wreg(ex_wreg_i),
        .ex_link_address(ex_link_address_i),
        .ex_is_in_delayslot(ex_is_in_delayslot_i),
        .is_in_delayslot_o(is_in_delayslot_i)
        );
     
     //EX模块例化
     ex ex0(
        .rst(rst),
        
        .inst_i(ex_inst_i),
        .aluop_i(ex_aluop_i), .alusel_i(ex_alusel_i),
        .reg1_i(ex_reg1_i),.reg2_i(ex_reg2_i),
        .wd_i(ex_wd_i),.wreg_i(ex_wreg_i),
        .hi_i(hi),
        .lo_i(lo),

        .is_in_delayslot_i(is_in_delayslot_i),
        .link_address_i(ex_link_address_i),
        
        
        .wb_hi_i(wb_hi_i),
        .wb_lo_i(wb_lo_i),
        .wb_whilo_i(wb_whilo_i),
        .mem_hi_i(mem_hi_o),
        .mem_lo_i(mem_lo_o),
        .mem_whilo_i(mem_whilo_o),
        
        .cnt_i(cnt_i),
        
        .hilo_temp_i(hilo_temp_i),

        .div_result_i(div_result),
        .div_ready_i(div_ready),

        .aluop_o(ex_aluop_o),
        .mem_addr_o(ex_mem_addr_o),
        .reg2_o(ex_reg2_o),
        
        .stallreq(stallreq_from_ex),
        .wd_o(ex_wd_o),.wreg_o(ex_wreg_o),
        .wdata_o(ex_wdata_o),
        
        .cnt_o(cnt_o),
        .hilo_temp_o(hilo_temp_o),
        
        .hi_o(ex_hi_o),
        .lo_o(ex_lo_o),
        .whilo_o(ex_whilo_o),

        .div_start_o(div_start),
        .div_opdata2_o(div_opdata2),
        .div_opdata1_o(div_opdata1),
        .signed_div_o(signed_div)


        
        );
    //EX/MEM模块例化
    ex_mem ex_mem0(
        .clk(clk),  .rst(rst),
        
        .cnt_i(cnt_o),
        .hilo_i(hilo_temp_o),
        .stall(stall),
        
        
        //来自执行阶段EX模块的信息 
        .ex_aluop(ex_aluop_o),
        .ex_mem_addr(ex_mem_addr_o),
        .ex_reg2(ex_reg2_o),

        .ex_wd(ex_wd_o),    .ex_wreg(ex_wreg_o),
        .ex_wdata(ex_wdata_o),
        .ex_hi(ex_hi_o),
        .ex_lo(ex_lo_o),
        .ex_whilo(ex_whilo_o),
        
        .mem_aluop(mem_aluop_i),
        .mem_mem_addr(mem_mem_addr_i),
        .mem_reg2(mem_reg2_i),

        .cnt_o(cnt_i),
        .hilo_o(hilo_temp_i),
        
        //送到访存阶段MEM模块的信息
        .mem_wd(mem_wd_i),.mem_wreg(mem_wreg_i),
        .mem_wdata(mem_wdata_i),
        .mem_hi(mem_hi_i),
        .mem_lo(mem_lo_i),
        .mem_whilo(mem_whilo_i)
    );
    
    //MEM模块化
    mem mem0(
        .rst(rst),
        
        //来自EX/MEM模块的信息
        .aluop_i(mem_aluop_i),
        .mem_addr_i(mem_mem_addr_i),
        .reg2_i(mem_reg2_i),

        .wd_i(mem_wd_i),    .wreg_i(mem_wreg_i),
        .wdata_i(mem_wdata_i),
        .hi_i(mem_hi_i),
        .lo_i(mem_lo_i),
        .whilo_i(mem_whilo_i),

        .mem_data_i(ram_data_i),
        
        //送到MEM/WB模块的信息
        .wd_o(mem_wd_o), .wreg_o(mem_wreg_o),
        .wdata_o(mem_wdata_o),
        .hi_o(mem_hi_o),
        .lo_o(mem_lo_o),
        .whilo_o(mem_whilo_o),

        .mem_addr_o(ram_addr_o),
        .mem_we_o(ram_we_o),
        .mem_sel_o(ram_sel_o),
        .mem_data_o(ram_data_o),
        .mem_ce_o(ram_ce_o)
        );
     
    //MEM/WB模块例化
    mem_wb mem_wb0(
        .clk(clk),  .rst(rst),
        
        .mem_wd(mem_wd_o),  .mem_wreg(mem_wreg_o),
        .mem_wdata(mem_wdata_o),
        .mem_hi(mem_hi_o),
		.mem_lo(mem_lo_o),
		.mem_whilo(mem_whilo_o),	
		.stall(stall),
        
        .wb_wd(wb_wd_i),.wb_wreg(wb_wreg_i),
        .wb_wdata(wb_wdata_i),
        .wb_hi(wb_hi_i),
		.wb_lo(wb_lo_i),
		.wb_whilo(wb_whilo_i)
        
        );
    hilo_reg hilo_reg0(
        .clk(clk),
        .rst(rst),
        
        .we(wb_whilo_i),
        .hi_i(wb_hi_i),
        .lo_i(wb_lo_i),
        
        .hi_o(hi),
        .lo_o(lo));
        
    ctrl ctrl0(
        .rst(rst),
        .stall(stall),
        .stallreq_from_id(stallreq_from_id),
        .stallreq_from_ex(stallreq_from_ex)
        );
        
    div div0(
        .clk(clk),
        .rst(rst),
        
        .signed_div_i(signed_div),
        .opdata1_i(div_opdata1),
        .opdata2_i(div_opdata2),
        .start_i(div_start),
        .annul_i(1'b0),

        .result_o(div_result),
        .ready_o(div_ready)
    );
endmodule
