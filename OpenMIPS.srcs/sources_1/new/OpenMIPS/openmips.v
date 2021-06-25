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

    input wire [5:0]        int_i,

    //指令wishbone总线
    input wire[`RegBus]     iwishbone_data_i,
    input wire              iwishbone_ack_i,
    output wire[`RegBus]    iwishbone_addr_o,
    output wire[`RegBus]    iwishbone_data_o,
    output wire             iwishbone_we_o,
    output wire[3:0]        iwishbone_sel_o,
    output wire             iwishbone_stb_o,
    output wire             iwishbone_cyc_o,

    //数据wishbone总线
    input wire[`RegBus]     dwishbone_data_i,
    input wire              dwishbone_ack_i,
    output wire[`RegBus]    dwishbone_addr_o,
    output wire[`RegBus]    dwishbone_data_o,
    output wire             dwishbone_we_o,
    output wire[3:0]        dwishbone_sel_o,
    output wire             dwishbone_stb_o,
    output wire             dwishbone_cyc_o,

    output wire             timer_int_o
    );
    
    //连接IF/ID模块与链接阶段ID模块的变量
     wire [`InstAddrBus] pc;
    wire [`InstBus] inst_i;
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
    wire[31:0] id_excepttype_o;
    wire[`RegBus] id_current_inst_address_o;
    wire inst_tlb_refillD, inst_tlb_invalidD;
    
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
    wire[31:0] ex_excepttype_i;
    wire[`RegBus] ex_current_inst_address_i;
    
    //连接执行EX模块的输出与EX/MEM模块的输入的变量
    wire            ex_wreg_o;
    wire[`RegAddrBus] ex_wd_o;
    wire[`RegBus]    ex_wdata_o;
    wire[`RegBus]   ex_hi_o;
    wire[`RegBus]   ex_lo_o;
    wire ex_whilo_o;
    wire[`AluOpBus] ex_aluop_o;
    wire[`RegBus] ex_mem_addr_o;
    wire[`RegBus] ex_reg2_o;
    wire ex_cp0_reg_we_o;
    wire[4:0] ex_cp0_reg_write_addr_o;
    wire[`RegBus] ex_cp0_reg_data_o;
    wire[31:0] ex_excepttype_o;
    wire[`RegBus] ex_current_inst_address_o;
    wire ex_is_in_delayslot_o;
    

    
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
    wire             mem_cp0_reg_we_i;
    wire[4:0]        mem_cp0_reg_write_addr_i;
    wire[`RegBus]    mem_cp0_reg_data_i;
    wire[31:0]       mem_excepttype_i;
    wire             mem_is_in_delayslot_i;
    wire[`RegBus]    mem_current_inst_address_i;
    wire inst_tlb_refillE, inst_tlb_invalidE;
    
    //连接访存阶段MEM模块的输出与MEM/WB模块的输入的变量
    wire            mem_wreg_o;
    wire[`RegAddrBus] mem_wd_o;
    wire [`RegBus]  mem_wdata_o;
    wire [`RegBus] mem_hi_o;
    wire [`RegBus] mem_lo_o;
    wire mem_whilo_o;
    wire mem_LLbit_value_o;
    wire mem_LLbit_we_o;
    wire            mem_cp0_reg_we_o;
    wire [4:0]      mem_cp0_reg_write_addr_o;
    wire [`RegBus]  mem_cp0_reg_data_o;
    wire[31:0]      mem_excepttype_o;
    wire            mem_is_in_delayslot_o;
    wire[`RegBus]   mem_current_inst_address_o;
    
    
    //连接MEM/WB模块的输出与回写阶段的输入的变量
    wire            wb_wreg_i;
    wire[`RegAddrBus] wb_wd_i;
    wire [`RegBus]   wb_wdata_i;
    wire [`RegBus]  wb_hi_i;
    wire [`RegBus]  wb_lo_i;
    wire  wb_whilo_i;
    wire  wb_LLbit_value_i;
    wire  wb_LLbit_we_i;
    wire  wb_cp0_reg_we_i;
    wire [4:0] wb_cp0_reg_write_addr_i;
    wire [`RegBus]  wb_cp0_reg_data_i;
    wire [31:0] wb_excepttype_i;
    wire wb_is_in_delayslot_i;
    wire [`RegBus] wb_current_inst_address_i;
    
    //连接译码阶段ID模块与通用寄存器Regfile模块的变量
    wire            reg1_read;
    wire            reg2_read;
    wire[`RegBus]   reg1_data;
    wire[`RegBus]   reg2_data;
    wire[`RegAddrBus]reg1_addr;
    wire[`RegAddrBus]reg2_addr;
    

    //连接执行阶段与hilo模块的输出，读取HI、LO寄存器
    wire[`RegBus]  hi;
    wire[`RegBus]  lo;

	//连接执行阶段与ex_reg模块，用于多周期的MADD、MADDU、MSUB、MSUBU指令
	wire[1:0]       cnt_o;
    wire[`DoubleRegBus] hilo_temp_o;
    wire [1:0]      cnt_i;
    wire [`DoubleRegBus] hilo_temp_i;
  
    


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

	//连接CTRL模块的变量
    wire [5:0] stall;
    wire stallreq_from_id;
    wire stallreq_from_ex;
    wire stallreq_from_if;
    wire stallreq_from_mem;
    

    wire LLbit_o;

    wire [`RegBus] cp0_data_o;
    wire [4:0] cp0_raddr_i;

    wire flush;
    wire [`RegBus] new_pc;

    wire [`RegBus] cp0_count;
	wire [`RegBus] cp0_compare;
    wire [`RegBus] cp0_status;
    wire [`RegBus] cp0_cause;
    wire [`RegBus] cp0_epc;
    wire [`RegBus] cp0_config;
    wire [`RegBus] cp0_prid;

    wire [`RegBus] latest_epc;

    wire rom_ce;

    wire[31:0] ram_addr_o;
    wire ram_we_o;
    wire [3:0] ram_sel_o;
    wire [`RegBus]ram_data_o;
    wire ram_ce_o;
    wire [`RegBus]ram_data_i;

    wire [3:0] tlb_typeD,tlb_typeE,tlb_typeM;
    wire [19:0] inst_pfn, data_pfn;
    wire no_cache_i,no_cache_d;


    wire [31:0] cp0_random;
    wire [31:0] cp0_index;
    wire [31:0] cp0_EntryHi;
    wire [31:0] cp0_EntryLo0;
    wire [31:0] cp0_EntryLo1;
    wire [31:0] cp0_PageMask;

    wire [31:0] tlb_EntryHi;
    wire [31:0] tlb_entry_lo0;
    wire [31:0] tlb_entry_lo1;
    wire [31:0] tlb_page_mask;
    wire [31:0] tlb_entry_hi;
    wire [31:0] tlb_index;

    wire inst_tlb_refillF;
    wire inst_tlb_invalidF;
    wire data_tlb_refillM;
    wire data_tlb_invalidM;
    wire data_tlb_modifyM;
    
    pc_reg pc_reg0(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .new_pc(new_pc),
        .pc(pc),
        .ce(rom_ce),
        .branch_flag_i(id_branch_flag_o),
        .branch_target_address_i(branch_target_address)
        );
    
    assign rom_addr_o=pc;       //指令存储器的输入地址是PC的值
    
    //IF/ID模块例化
    if_id if_id0(
        .clk(clk),.rst(rst),.if_pc(pc),.flush(flush),
        .if_inst(inst_i),.id_pc(id_pc_i),
        .id_inst(id_inst_i),.stall(stall),
        .inst_tlb_refillF(inst_tlb_refillF & rom_ce),
        .inst_tlb_invalidF(inst_tlb_invalidF&rom_ce),

        .inst_tlb_refillD(inst_tlb_refillD),
        .inst_tlb_invalidD(inst_tlb_invalidD)
        );
    
    //译码阶段ID模块例化
    id id0(
        .rst(rst),.pc_i(id_pc_i),.inst_i(id_inst_i),

        .ex_aluop_i(ex_aluop_o),
        
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
        .wd_o(id_wd_o), .wreg_o(id_wreg_o),.stallreq(stallreq_from_id),
        .excepttype_o(id_excepttype_o),
        .current_inst_address_o(id_current_inst_address_o),
        .tlb_typeD(tlb_typeD)
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
        
		.stall(stall),.flush(flush),
		
        .id_inst(id_inst_o),
        .id_aluop(id_aluop_o),  .id_alusel(id_alusel_o),
        .id_reg1(id_reg1_o),    .id_reg2(id_reg2_o),
        .id_wd(id_wd_o),    .id_wreg(id_wreg_o),
        
		.id_link_address(id_link_address_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot_o),	
        .id_excepttype(id_excepttype_o),
        .id_current_inst_address(id_current_inst_address_o),	
        .tlb_typeD(tlb_typeD),
        .inst_tlb_refillD(inst_tlb_refillD),
        .inst_tlb_invalidD(inst_tlb_invalidD),
	
        .ex_inst(ex_inst_i),
        .ex_aluop(ex_aluop_i),  .ex_alusel(ex_alusel_i),
        .ex_reg1(ex_reg1_i),.ex_reg2(ex_reg2_i),
        .ex_wd(ex_wd_i),.ex_wreg(ex_wreg_i),
        .ex_link_address(ex_link_address_i),
        .ex_is_in_delayslot(ex_is_in_delayslot_i),
        .is_in_delayslot_o(is_in_delayslot_i),
        .ex_excepttype(ex_excepttype_i),
        .ex_current_inst_address(ex_current_inst_address_i),
        .tlb_typeE(tlb_typeE),
        .inst_tlb_refillE(inst_tlb_refillE),
        .inst_tlb_invalidE(inst_tlb_invalidE)
        );
     
     //EX模块例化
     ex ex0(
        .rst(rst),
        
		//送到执行阶段EX模块的信息
        
        .aluop_i(ex_aluop_i), 
		.alusel_i(ex_alusel_i),
        .reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
        .wd_i(ex_wd_i),
		.wreg_i(ex_wreg_i),
        .hi_i(hi),
        .lo_i(lo),
		.inst_i(ex_inst_i),

		.wb_hi_i(wb_hi_i),
        .wb_lo_i(wb_lo_i),
        .wb_whilo_i(wb_whilo_i),
        .mem_hi_i(mem_hi_o),
        .mem_lo_i(mem_lo_o),
        .mem_whilo_i(mem_whilo_o),

		.hilo_temp_i(hilo_temp_i),
        .cnt_i(cnt_i),

		.div_result_i(div_result),
        .div_ready_i(div_ready),

        
        .link_address_i(ex_link_address_i),
		.is_in_delayslot_i(ex_is_in_delayslot_i),

        .excepttype_i(ex_excepttype_i),
        .current_inst_address_i(ex_current_inst_address_i),
        
    

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
        .signed_div_o(signed_div),

        .mem_cp0_reg_we(mem_cp0_reg_we_o),
        .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
        .mem_cp0_reg_data(mem_cp0_reg_data_o),

        .wb_cp0_reg_we(wb_cp0_reg_we_i),
        .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
        .wb_cp0_reg_data(wb_cp0_reg_data_i),

        .cp0_reg_data_i(cp0_data_o),
        .cp0_reg_read_addr_o(cp0_raddr_i),

        .cp0_reg_we_o(ex_cp0_reg_we_o),
        .cp0_reg_write_addr_o(ex_cp0_reg_write_addr_o),
        .cp0_reg_data_o(ex_cp0_reg_data_o),

        .excepttype_o(ex_excepttype_o),
        .is_in_delayslot_o(ex_is_in_delayslot_o),
        .current_inst_address_o(ex_current_inst_address_o)

        
        );
    //EX/MEM模块例化
    ex_mem ex_mem0(
        .clk(clk),  .rst(rst),
        
        .cnt_i(cnt_o),
        .hilo_i(hilo_temp_o),
        .stall(stall),
        .flush(flush),
        
        
        //来自执行阶段EX模块的信息 
        .ex_aluop(ex_aluop_o),
        .ex_mem_addr(ex_mem_addr_o),
        .ex_reg2(ex_reg2_o),

        .ex_wd(ex_wd_o),    .ex_wreg(ex_wreg_o),
        .ex_wdata(ex_wdata_o),
        .ex_hi(ex_hi_o),
        .ex_lo(ex_lo_o),
        .ex_whilo(ex_whilo_o),

        .ex_cp0_reg_we(ex_cp0_reg_we_o),
        .ex_cp0_reg_write_addr(ex_cp0_reg_write_addr_o),
        .ex_cp0_reg_data(ex_cp0_reg_data_o),

        .ex_excepttype(ex_excepttype_o),
        .ex_is_in_delayslot(ex_is_in_delayslot_o),
        .ex_current_inst_address(ex_current_inst_address_o),
        .tlb_typeE(tlb_typeE),
        
        .mem_aluop(mem_aluop_i),
        .mem_mem_addr(mem_mem_addr_i),
        .mem_reg2(mem_reg2_i),

        .cnt_o(cnt_i),
        .hilo_o(hilo_temp_i),

        .mem_cp0_reg_we(mem_cp0_reg_we_i),
        .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_i),
        .mem_cp0_reg_data(mem_cp0_reg_data_i),
        .inst_tlb_refillE(inst_tlb_refillE),
        .inst_tlb_invalidE(inst_tlb_invalidE),
        
        //送到访存阶段MEM模块的信息
        .mem_wd(mem_wd_i),.mem_wreg(mem_wreg_i),
        .mem_wdata(mem_wdata_i),
        .mem_hi(mem_hi_i),
        .mem_lo(mem_lo_i),
        .mem_whilo(mem_whilo_i),

        .mem_excepttype(mem_excepttype_i),
        .mem_is_in_delayslot(mem_is_in_delayslot_i),
        .mem_current_inst_address(mem_current_inst_address_i),
        .tlb_typeM(tlb_typeM),
        .inst_tlb_refillM(inst_tlb_refillM),
        .inst_tlb_invalidM(inst_tlb_invalidM)
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

        .LLbit_i(LLbit_o),

        .wb_LLbit_we_i(wb_LLbit_we_i),
        .wb_LLbit_value_i(wb_LLbit_value_i),

        .cp0_reg_we_i(mem_cp0_reg_we_i),
        .cp0_reg_write_addr_i(mem_cp0_reg_write_addr_i),
        .cp0_reg_data_i(mem_cp0_reg_data_i),

        .excepttype_i(mem_excepttype_i),
        .is_in_delayslot_i(mem_is_in_delayslot_i),
        .current_inst_address_i(mem_current_inst_address_i),

        .cp0_status_i(cp0_status),
        .cp0_cause_i(cp0_cause),
        .cp0_epc_i(cp0_epc),

        .wb_cp0_reg_we(wb_cp0_reg_we_i),
        .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
        .wb_cp0_reg_data(wb_cp0_reg_data_i),

        .LLbit_we_o(mem_LLbit_we_o),
        .LLbit_value_o(mem_LLbit_value_o),

        .cp0_reg_we_o(mem_cp0_reg_we_o),
        .cp0_reg_write_addr_o(mem_cp0_reg_write_addr_o),
        .cp0_reg_data_o(mem_cp0_reg_data_o),
        
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
        .mem_ce_o(ram_ce_o),

        .excepttype_o(mem_excepttype_o),
        .cp0_epc_o(latest_epc),
        .is_in_delayslot_o(mem_is_in_delayslot_o),
        .current_inst_address_o(mem_current_inst_address_o)
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
        .flush(flush),

        .mem_LLbit_we(mem_LLbit_we_o),
        .mem_LLbit_value(mem_LLbit_value_o),

        .mem_cp0_reg_we(mem_cp0_reg_we_o),
        .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
        .mem_cp0_reg_data(mem_cp0_reg_data_o),
        
        .wb_wd(wb_wd_i),.wb_wreg(wb_wreg_i),
        .wb_wdata(wb_wdata_i),
        .wb_hi(wb_hi_i),
		.wb_lo(wb_lo_i),
		.wb_whilo(wb_whilo_i),

        .wb_LLbit_we(wb_LLbit_we_i),
        .wb_LLbit_value(wb_LLbit_value_i),

        .wb_cp0_reg_we(wb_cp0_reg_we_i),
        .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
        .wb_cp0_reg_data(wb_cp0_reg_data_i)
        
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
        .stallreq_from_if(stallreq_from_if),
        .stallreq_from_id(stallreq_from_id),
        .stallreq_from_ex(stallreq_from_ex),
        .stallreq_from_mem(stallreq_from_mem),
        .excepttype_i(mem_excepttype_o),
        .cp0_epc_i(latest_epc),
        .new_pc(new_pc),
        .flush(flush)
        );
        
    div div0(
        .clk(clk),
        .rst(rst),
        
        .signed_div_i(signed_div),
        .opdata1_i(div_opdata1),
        .opdata2_i(div_opdata2),
        .start_i(div_start),
        .annul_i(flush),

        .result_o(div_result),
        .ready_o(div_ready)
    );

    LLbit_reg LLbit_reg0(
        .clk(clk),
        .rst(rst),
        .flush(flush),

        .LLbit_i(wb_LLbit_value_i),
        .we(wb_LLbit_we_i),

        .LLbit_o(LLbit_o)
    );

    assign {TLBWR,TLBWI,TLBR,TLBP}=tlb_typeM;

    cp0_reg cp0_reg0(
        .clk(clk),
        .rst(rst),

        .we_i(wb_cp0_reg_we_i),
        .waddr_i(wb_cp0_reg_write_addr_i),
        .raddr_i(cp0_raddr_i),
        .data_i(wb_cp0_reg_data_i),

        .excepttype_i(mem_excepttype_o),
        .int_i(int_i),
        .current_inst_addr_i(mem_current_inst_address_o),
        .is_in_delayslot_i(mem_is_in_delayslot_o),

        .tlb_typeM(tlb_typeM),
        .entry_lo0_in(tlb_entry_lo0),
        .entry_lo1_in(tlb_entry_lo1),
        .page_mask_in(tlb_page_mask),
        .entry_hi_in(tlb_entry_hi),
        .index_in(tlb_index),


        .data_o(cp0_data_o),
        .count_o(cp0_count),
        .compare_o(cp0_compare),
        .status_o(cp0_status),
        .cause_o(cp0_cause),
        .epc_o(cp0_epc),
        .config_o(cp0_config),
        .prid_o(cp0_prid),

        .random_o(cp0_random),
        .index_o(cp0_index),
        .EntryHi_o(cp0_EntryHi),
        .EntryLo0_o(cp0_EntryLo0),
        .EntryLo1_o(cp0_EntryLo1),
        .PageMask_o(cp0_PageMask),

        .timer_int_o(timer_int_o)
    );

    tlb tlb0(
    .rst(rst),
    .clk(clk),
    .stallM(stall[3]),
    .flushM(flush),
    .inst_vaddr(pc),
    .data_vaddr(ram_addr_o),
    .inst_en(rom_ce_o),
    .mem_read_enM(ram_ce_o),
    .mem_write_enM(ram_we_o),
    .inst_pfn(inst_pfn),
    .data_pfn(data_pfn),
    .no_cache_i(no_cache_i),
    .no_cache_d(no_cache_d),

    .inst_tlb_refill(inst_tlb_invalidF),
    .inst_tlb_invalid(inst_tlb_invalidF),
    .data_tlb_refill(data_tlb_refillM),
    .data_tlb_invalid(data_tlb_invalidM),
    .data_tlb_modify(data_tlb_modify),

    .TLBP(TLBP),
    .TLBR(TLBR),
    .TLBWI(TLBWI),
    .TLBWR(TLBWR),
    .EntryHi_in(cp0_EntryHi),
    .PageMask_in(cp0_PageMask),
    .EntryLo0_in(cp0_EntryLo0),
    .EntryLo1_in(cp0_EntryLo1),
    .Index_in(cp0_index),
    .Random_in(cp0_random),

    .EntryHi_out(tlb_EntryHi),
    .PageMask_out(tlb_page_mask),
    .EntryLo0_out(tlb_entry_lo0),
    .EntryLo1_out(tlb_entry_lo1),
    .Index_out(tlb_index)
);

    wishbone_bus_if dwishbone_bus_if(       //data总线接口
        .clk(clk),
        .rst(rst),

        //来自控制模块ctrl
        .stall_i(stall),
        .flush_i(flush),

        //CPU侧读写操作信息
        .cpu_ce_i(ram_ce_o),
        .cpu_data_i(ram_data_o),
        .cpu_addr_i(ram_addr_o),
        .cpu_we_i(ram_we_o),
        .cpu_sel_i(ram_sel_o),
        .cpu_data_o(ram_data_i),

        //Wishbone总线侧接口
        .wishbone_data_i(dwishbone_data_i),
        .wishbone_ack_i(dwishbone_ack_i),
        .wishbone_addr_o(dwishbone_addr_o),
        .wishbone_data_o(dwishbone_data_o),
        .wishbone_we_o(dwishbone_we_o),
        .wishbone_sel_o(dwishbone_sel_o),
        .wishbone_stb_o(dwishbone_stb_o),
        .wishbone_cyc_o(dwishbone_cyc_o),

        .stallreq(stallreq_from_mem)
    );

    wishbone_bus_if iwishbone_bus_if(           //inst总线接口
        .clk(clk),
        .rst(rst),

        //来自控制模块ctrl
        .stall_i(stall),
        .flush_i(flush),

        //CPU侧读写操作信息
        .cpu_ce_i(rom_ce),
        .cpu_data_i(32'h00000000),
        .cpu_addr_i(pc),
        .cpu_we_i(1'b0),
        .cpu_sel_i(4'b1111),
        .cpu_data_o(inst_i),

        //Wishbone总线侧接口
        //Wishbone总线侧接口
        .wishbone_data_i(iwishbone_data_i),
        .wishbone_ack_i(iwishbone_ack_i),
        .wishbone_addr_o(iwishbone_addr_o),
        .wishbone_data_o(iwishbone_data_o),
        .wishbone_we_o(iwishbone_we_o),
        .wishbone_sel_o(iwishbone_sel_o),
        .wishbone_stb_o(iwishbone_stb_o),
        .wishbone_cyc_o(iwishbone_cyc_o),

        .stallreq(stallreq_from_if)

    );
endmodule
