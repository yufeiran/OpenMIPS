`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/10 10:49:41
// Design Name: 
// Module Name: id
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

module id(
    input wire rst,
    input wire [`InstAddrBus]   pc_i,
    input wire [`InstBus]       inst_i,
    
    // 读取的Regfile的值
    input wire [`RegBus]        reg1_data_i,
    input wire [`RegBus]        reg2_data_i,
    
    //处于执行阶段的指令运算结果
	input wire         ex_wreg_i,
	input wire [`RegBus] ex_wdata_i,
	input wire [`RegAddrBus] ex_wd_i,
	
	//处于访存阶段的指令运算结果
	input wire         mem_wreg_i,
	input wire [`RegBus] mem_wdata_i,
	input wire [`RegAddrBus] mem_wd_i,

    input wire is_in_delayslot_i,

    input wire [`AluOpBus]  ex_aluop_i,

    output wire[`RegBus]    inst_o,
	
	output wire        stallreq,

    output reg          next_inst_in_delayslot_o,

    output reg          branch_flag_o,
    output reg[`RegBus] branch_target_address_o,
    output reg[`RegBus] link_addr_o,
    output reg          is_in_delayslot_o,
    
    // 输出到Regfile的信息
    output reg                  reg1_read_o,
    output reg                  reg2_read_o,
    output reg [`RegAddrBus]    reg1_addr_o,
    output reg [`RegAddrBus]    reg2_addr_o,
    
    //送到执行阶段的信息
    output reg[`AluOpBus]       aluop_o,
    output reg[`AluSelBus]      alusel_o,
    output reg[`RegBus]         reg1_o,
    output reg[`RegBus]         reg2_o,
    output reg[`RegAddrBus]     wd_o,
    output reg                  wreg_o,

    output wire [31:0]          excepttype_o,
    output wire [`RegBus]       current_inst_address_o,

    output wire [3:0] tlb_typeD
    );

    reg excepttype_is_syscall;      //是否为系统调用异常
    reg excepttype_is_eret;         //是否为异常返回指令eret
    wire TLBWR, TLBWI, TLBP, TLBR;

  
    
    // 取得指令的指令码，功能码
    // 对于ori指令只需通过判断第26-31bit的值，即可判断是否是ori指令
    wire[5:0] op=inst_i[31:26];
    wire[4:0] op2=inst_i[10:6];
    wire[5:0] op3=inst_i[5:0];
    wire[4:0] op4=inst_i[20:16];
    
    //保存指令执行需要的立即数
    reg[`RegBus] imm;
    
    //指示指令是否有效
    reg instvalid;

    assign excepttype_o={19'b0,excepttype_is_eret,2'b0,instvalid,excepttype_is_syscall,8'b0};
    assign current_inst_address_o=pc_i;

    wire [`RegBus] pc_plus_8;
    wire [`RegBus] pc_plus_4;

    wire [`RegBus] imm_sll2_signedext;

    assign pc_plus_8=pc_i+8;    //当前PC值后第二条指令
    assign pc_plus_4=pc_i+4;    //当前PC值后第一条指令

    //imm_sll2_signedext 对应分支指令中的offset左移两位，再符号扩展至32位的值
    assign imm_sll2_signedext={{14{inst_i[15]}},inst_i[15:0],2'b00};

    assign inst_o=inst_i;

    reg stallreq_for_reg1_loadrelate;
    reg stallreq_for_reg2_loadrelate;
    wire pre_inst_is_load;

    //根据输入信号ex_aluop_i的值，判断上一条指令是否是加载指令，
    //如果是加载指令，那么置pre_inst_is_load为1，反之置为0
    assign pre_inst_is_load=((ex_aluop_i==`EXE_LB_OP)||
                            (ex_aluop_i==`EXE_LBU_OP)||
                            (ex_aluop_i==`EXE_LH_OP)||
                            (ex_aluop_i==`EXE_LHU_OP)||
                            (ex_aluop_i==`EXE_LW_OP)||
                            (ex_aluop_i==`EXE_LWR_OP)||
                            (ex_aluop_i==`EXE_LWL_OP)||
                            (ex_aluop_i==`EXE_LL_OP)||
                            (ex_aluop_i==`EXE_SC_OP))?1'b1:1'b0;


    
    /************************************************
     ************** 第一阶段：对指令进行译码 *********
     ************************************************/
    always@(*)begin
        if(rst==`RstEnable) begin
            aluop_o<=`EXE_NOP_OP;
            alusel_o<=`EXE_RES_NOP;
            wd_o<=`NOPRegAddr;
            wreg_o<=`WriteDisable;
            instvalid<=`InstValid;
            reg1_read_o<=1'b0;
            reg2_read_o<=1'b0;
            reg1_addr_o<=`NOPRegAddr;
            reg2_addr_o<=`NOPRegAddr;
            imm<=32'h0;
            link_addr_o<=`ZeroWord;
            branch_target_address_o<=`ZeroWord;
            branch_flag_o<=`NotBranch;
            next_inst_in_delayslot_o<=`NotInDelaySlot;
            excepttype_is_syscall<=`False_v;
            excepttype_is_eret<=`False_v;
            
        end else begin
            aluop_o<=`EXE_NOP_OP;
            alusel_o<=`EXE_RES_NOP;
            wd_o<=inst_i[15:11];
            wreg_o<=`WriteDisable;
            instvalid<=`InstInvalid;
            reg1_read_o<=1'b0;
            reg2_read_o<=1'b0;
            reg1_addr_o<=inst_i[25:21];     //默认通过Regfile读端口1读取的寄存器地址
            reg2_addr_o<=inst_i[20:16];     //默认通过Regfile读端口1读取的寄存器地址
            imm<=`ZeroWord;
            link_addr_o<=`ZeroWord;
            branch_target_address_o<=`ZeroWord;
            branch_flag_o<=`NotBranch;
            next_inst_in_delayslot_o<=`NotInDelaySlot;
            excepttype_is_syscall<=`False_v;
            excepttype_is_eret<=`False_v;

            if(inst_i[31:21]==11'b01000000000&&
                inst_i[10:0]==11'b00000000000)
            begin
                aluop_o<=`EXE_MFC0_OP;
                alusel_o<=`EXE_RES_MOVE;
                wd_o<=inst_i[20:16];
                wreg_o<=`WriteEnable;
                instvalid<=`InstValid;
                reg1_read_o<=1'b0;
                reg2_read_o<=1'b0;
            end else if(inst_i[31:21]==11'b01000000100 &&
                        inst_i[10:0]==11'b00000000000)
            begin
                aluop_o<=`EXE_MTC0_OP;
                alusel_o<=`EXE_RES_NOP;
                wreg_o<=`WriteDisable;
                instvalid<=`InstValid;
                reg1_read_o<=1'b1;
                reg1_addr_o<=inst_i[20:16];
                reg2_read_o<=1'b0;
            end
            case(op)
                `EXE_LL:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_LL_OP;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                end
                `EXE_SC:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_SC_OP;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b1;
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                end
                `EXE_LB:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_LB_OP;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                end
                `EXE_LBU:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_LBU_OP;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                end
                `EXE_LH:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_LH_OP;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                end
                `EXE_LHU:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_LHU_OP;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                end
                `EXE_LW:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_LW_OP;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                end
                `EXE_LWL:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_LWL_OP;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b1;
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                end
                `EXE_LWR:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_LWR_OP;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b1;
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                end
                `EXE_SB:begin
                    wreg_o<=`WriteDisable;
                    aluop_o<=`EXE_SB_OP;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b1;
                    instvalid<=`InstValid;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                end
                `EXE_SH:begin
                    wreg_o<=`WriteDisable;
                    aluop_o<=`EXE_SH_OP;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b1;
                    instvalid<=`InstValid;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                end
                `EXE_SW:begin
                    wreg_o<=`WriteDisable;
                    aluop_o<=`EXE_SW_OP;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b1;
                    instvalid<=`InstValid;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                end
                `EXE_SWL:begin
                    wreg_o<=`WriteDisable;
                    aluop_o<=`EXE_SWL_OP;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b1;
                    instvalid<=`InstValid;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                end
                `EXE_SWR:begin
                    wreg_o<=`WriteDisable;
                    aluop_o<=`EXE_SWR_OP;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b1;
                    instvalid<=`InstValid;
                    alusel_o<=`EXE_RES_LOAD_STORE;
                end

                `EXE_SPECIAL_INST:  begin
                    case(op3)
                        `EXE_TEQ:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_TEQ_OP;
                            alusel_o<=`EXE_RES_NOP;
                            reg1_read_o<=1'b0;
                            reg2_read_o<=1'b0;
                            instvalid<=`InstValid;
                        end
                        `EXE_TGE:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_TGE_OP;
                            alusel_o<=`EXE_RES_NOP;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b1;
                            instvalid<=`InstValid;
                        end
                        `EXE_TGEU:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_TGEU_OP;
                            alusel_o<=`EXE_RES_NOP;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b1;
                            instvalid<=`InstValid;
                        end
                        `EXE_TLT:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_TLT_OP;
                            alusel_o<=`EXE_RES_NOP;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b1;
                            instvalid<=`InstValid;
                        end
                        `EXE_TLTU:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_TLTU_OP;
                            alusel_o<=`EXE_RES_NOP;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b1;
                            instvalid<=`InstValid;
                        end
                        `EXE_TNE:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_TNE_OP;
                            alusel_o<=`EXE_RES_NOP;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b1;
                            instvalid<=`InstValid;
                        end
                        `EXE_SYSCALL:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_SYSCALL_OP;
                            alusel_o<=`EXE_RES_NOP;
                            reg1_read_o<=1'b0;
                            reg2_read_o<=1'b0;
                            instvalid<=`InstValid;
                            excepttype_is_syscall<=`True_v;
                        end

                    endcase
                    case(op2)
                        5'b00000:   begin
                            case(op3)   
                                `EXE_JR:begin
                                    wreg_o<=`WriteDisable;
                                    aluop_o<=`EXE_JR_OP;
                                    alusel_o<=`EXE_RES_JUMP_BRANCH;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b0;
                                    link_addr_o<=`ZeroWord;
                                    branch_target_address_o<=reg1_o;
                                    branch_flag_o<=`Branch;
                                    next_inst_in_delayslot_o<=`InDelaySlot;
                                    instvalid<=`InstValid;
                                end
                                `EXE_JALR:begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_JALR_OP;
                                    alusel_o<=`EXE_RES_JUMP_BRANCH;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b0;
                                    wd_o<=inst_i[15:11];
                                    link_addr_o<=pc_plus_8;
                                    branch_target_address_o<=reg1_o;
                                    branch_flag_o<=`Branch;
                                    next_inst_in_delayslot_o<=`InDelaySlot;
                                    instvalid<=`InstValid;
                                end
                                


                                `EXE_DIV:begin
                                    wreg_o<=`WriteDisable;
                                    aluop_o<=`EXE_DIV_OP;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                end
                                `EXE_DIVU:begin
                                    wreg_o<=`WriteDisable;
                                    aluop_o<=`EXE_DIVU_OP;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                end
                                `EXE_OR:begin   
                                    wreg_o  <=`WriteEnable;
                                    aluop_o <=`EXE_OR_OP;
                                    alusel_o<=`EXE_RES_LOGIC;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                end
                                `EXE_AND:begin
                                    wreg_o  <=`WriteEnable;
                                    aluop_o <=`EXE_AND_OP;
                                    alusel_o<=`EXE_RES_LOGIC;
                                    reg1_read_o <=1'b1;
                                    reg2_read_o <=1'b1;
                                    instvalid<=`InstValid;
                                 end
                                `EXE_XOR:begin
                                    wreg_o  <=`WriteEnable;
                                    aluop_o <=`EXE_XOR_OP;
                                    alusel_o<=`EXE_RES_LOGIC;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                end
                                `EXE_NOR:begin
                                    wreg_o <=`WriteEnable;
                                    aluop_o<=`EXE_NOR_OP;
                                    alusel_o<=`EXE_RES_LOGIC;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                end
                                `EXE_SLLV:begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_SLL_OP;
                                    alusel_o<=`EXE_RES_SHIFT;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                end
                                `EXE_SRLV:begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_SRL_OP;
                                    alusel_o<=`EXE_RES_SHIFT;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                end
                                `EXE_SRAV:begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_SRA_OP;
                                    alusel_o<=`EXE_RES_SHIFT;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                end
                                `EXE_SYNC:begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_NOP_OP;
                                    alusel_o<=`EXE_RES_SHIFT;
                                    reg1_read_o<=1'b0;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                end
                                `EXE_MFHI: begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_MFHI_OP;
                                    alusel_o<=`EXE_RES_MOVE;
                                    reg1_read_o<=1'b0;
                                    reg2_read_o<=1'b0;
                                    instvalid<=`InstValid;
                                end
                                `EXE_MFLO: begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_MFLO_OP;
                                    alusel_o<=`EXE_RES_MOVE;
                                    reg1_read_o<=1'b0;
                                    reg2_read_o<=1'b0;
                                    instvalid<=`InstValid;
                                end
                                `EXE_MTHI: begin
                                    wreg_o<=`WriteDisable;
                                    aluop_o<=`EXE_MTHI_OP;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b0;
                                    instvalid<=`InstValid;
                                end
                                `EXE_MTLO: begin
                                    wreg_o<=`WriteDisable;
                                    aluop_o<=`EXE_MTLO_OP;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b0;
                                    instvalid<=`InstValid;
                                end
                                `EXE_MOVN: begin
                                    aluop_o<=`EXE_MOVN_OP;
                                    alusel_o<=`EXE_RES_MOVE;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                    //reg2_o的值就是地址为rt的通用寄存器的值
                                    if(reg2_o!=`ZeroWord)begin
                                        wreg_o<=`WriteEnable;
                                    end else begin
                                        wreg_o<=`WriteDisable;
                                    end
                                end
                                `EXE_MOVZ:begin
                                    aluop_o<=`EXE_MOVZ_OP;
                                    alusel_o<=`EXE_RES_MOVE;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                    //reg2_o的值就是地址为rt的通用寄存器的值
                                    if(reg2_o==`ZeroWord)begin
                                        wreg_o<=`WriteEnable;
                                    end else begin
                                        wreg_o<=`WriteDisable;
                                    end
                                 end
                                 `EXE_SLT:begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_SLT_OP;
                                    alusel_o<=`EXE_RES_ARITHMETIC;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                 end
                                 `EXE_SLTU:begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_SLTU_OP;
                                    alusel_o<=`EXE_RES_ARITHMETIC;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                 end
                                 `EXE_ADD:begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_ADD_OP;
                                    alusel_o<=`EXE_RES_ARITHMETIC;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                 end
                                 `EXE_ADDU:begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_ADDU_OP;
                                    alusel_o<=`EXE_RES_ARITHMETIC;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                 end
                                 `EXE_SUB:begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_SUB_OP;
                                    alusel_o<=`EXE_RES_ARITHMETIC;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                 end
                                 `EXE_SUBU:begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_SUBU_OP;
                                    alusel_o<=`EXE_RES_ARITHMETIC;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                 end
                                 `EXE_MULT:begin
                                    wreg_o<=`WriteDisable;
                                    aluop_o<=`EXE_MULT_OP;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                 end
                                 `EXE_MULTU:begin
                                    wreg_o<=`WriteEnable;
                                    aluop_o<=`EXE_MULTU_OP;
                                    reg1_read_o<=1'b1;
                                    reg2_read_o<=1'b1;
                                    instvalid<=`InstValid;
                                 end
                              default: begin
                              end
                           endcase  // end case op3
                         end
                         default:begin
                         end
                      endcase
                   end
                
                `EXE_J:begin
                    wreg_o<=`WriteDisable;
                    aluop_o<=`EXE_J_OP;
                    alusel_o<=`EXE_RES_JUMP_BRANCH;
                    reg1_read_o<=1'b0;
                    reg2_read_o<=1'b0;
                    link_addr_o<=`ZeroWord;
                    branch_flag_o<=`Branch;
                    next_inst_in_delayslot_o<=`InDelaySlot;
                    instvalid<=`InstValid;
                    branch_target_address_o<=
                    {pc_plus_4[31:28],inst_i[25:0],2'b00};
                end

                `EXE_JAL:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_JAL_OP;
                    alusel_o<=`EXE_RES_JUMP_BRANCH;
                    reg1_read_o<=1'b0;
                    reg2_read_o<=1'b0;
                    wd_o<=5'b11111;
                    link_addr_o<=pc_plus_8;
                    branch_flag_o<=`Branch;
                    next_inst_in_delayslot_o<=`InDelaySlot;
                    instvalid<=`InstValid;
                    branch_target_address_o<=
                    {pc_plus_4[31:28],inst_i[25:0],2'b00};
                end
                `EXE_BEQ:begin
                    wreg_o<=`WriteDisable;
                    aluop_o<=`EXE_BEQ_OP;
                    alusel_o<=`EXE_RES_JUMP_BRANCH;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b1;
                    instvalid<=`InstValid;
                    if(reg1_o==reg2_o)begin
                        branch_target_address_o<=pc_plus_4+imm_sll2_signedext;
                        branch_flag_o<=`Branch;
                        next_inst_in_delayslot_o<=`InDelaySlot;
                    end
                end
                `EXE_BGTZ:begin
                    wreg_o<=`WriteDisable;
                    aluop_o<=`EXE_BGTZ_OP;
                    alusel_o<=`EXE_RES_JUMP_BRANCH;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    instvalid<=`InstValid;
                    if((reg1_o[31]==1'b0)&&(reg1_o!=`ZeroWord))begin
                        branch_target_address_o<=pc_plus_4+imm_sll2_signedext;
                        branch_flag_o<=`Branch;
                        next_inst_in_delayslot_o<=`InDelaySlot;
                    end
                end

                `EXE_BLEZ:begin
                    wreg_o<=`WriteDisable;
                    aluop_o<=`EXE_BLEZ_OP;
                    alusel_o<=`EXE_RES_JUMP_BRANCH;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    instvalid<=`InstValid;
                    if((reg1_o[31]==1'b1)&&(reg1_o!=`ZeroWord))begin
                        branch_target_address_o<=pc_plus_4+imm_sll2_signedext;
                        branch_flag_o<=`Branch;
                        next_inst_in_delayslot_o<=`InDelaySlot;
                    end
                end

                `EXE_BNE:begin
                    wreg_o<=`WriteDisable;
                    aluop_o<=`EXE_BLEZ_OP;
                    alusel_o<=`EXE_RES_JUMP_BRANCH;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b1;
                    instvalid<=`InstValid;
                    if(reg1_o!=reg2_o)begin
                        branch_target_address_o<=pc_plus_4+imm_sll2_signedext;
                        branch_flag_o<=`Branch;
                        next_inst_in_delayslot_o<=`InDelaySlot;
                    end
                end
                                    
                `EXE_ORI: begin //依据op的价值判断是否是ori指令
                    //ori指令需要将结果写入到目的寄存器，所以wreg_o为WriteEnable
                    wreg_o<=`WriteEnable;
                    //运算的子类型是逻辑"或"运算
                    aluop_o<=`EXE_OR_OP;
                    //运算类型是逻辑运算
                    alusel_o<=`EXE_RES_LOGIC;
                    //需要通过Regfile的读端口1读取寄存器
                    reg1_read_o<=1'b1;
                    //不需要通过Regfile的读端口2读取寄存器
                    reg2_read_o<=1'b0;
                    //指令执行需要的立即数
                    imm<={16'h0,inst_i[15:0]};
                    //指令执行要写的目的寄存器地址
                    wd_o<=inst_i[20:16];
                    //ori指令是有效指令
                    instvalid<=`InstValid;
                    
                  end
                  `EXE_ANDI:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_AND_OP;
                    alusel_o<=`EXE_RES_LOGIC;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    imm<={16'h0,inst_i[15:0]};
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                  end
                  `EXE_XORI:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_XOR_OP;
                    alusel_o<=`EXE_RES_LOGIC;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    imm<={16'h0,inst_i[15:0]};
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                  end
                  `EXE_LUI:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_OR_OP;
                    alusel_o<=`EXE_RES_LOGIC;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    imm<={inst_i[15:0],16'h0};
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                  end
                  `EXE_PREF:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_NOP_OP;
                    alusel_o<=`EXE_RES_NOP;
                    reg1_read_o<=1'b0;
                    reg2_read_o<=1'b0;
                    instvalid<=`InstValid;
                  end
                  `EXE_SLTI:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_SLT_OP;
                    alusel_o<=`EXE_RES_ARITHMETIC;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    imm<={{16{inst_i[15]}}, inst_i[15:0]};
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                  end
                  `EXE_SLTIU:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_SLTU_OP;
                    alusel_o<=`EXE_RES_ARITHMETIC;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    imm<={{16{inst_i[15]}}, inst_i[15:0]};
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                  end
                  `EXE_ADDI:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_ADDI_OP;
                    alusel_o<=`EXE_RES_ARITHMETIC;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    imm<={{16{inst_i[15]}}, inst_i[15:0]};
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                  end
                  `EXE_ADDIU:begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_ADDIU_OP;
                    alusel_o<=`EXE_RES_ARITHMETIC;
                    reg1_read_o<=1'b1;
                    reg2_read_o<=1'b0;
                    imm<={{16{inst_i[15]}}, inst_i[15:0]};
                    wd_o<=inst_i[20:16];
                    instvalid<=`InstValid;
                  end
                  `EXE_REGIMM_INST:begin
                    case(op4)
                        `EXE_TEQI:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_TEQI_OP;
                            alusel_o<=`EXE_RES_NOP;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b0;
                            imm<={{16{inst_i[15]}},inst_i[15:0]};
                            instvalid<=`InstValid;
                        end
                        `EXE_TGEI:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_TGEI_OP;
                            alusel_o<=`EXE_RES_NOP;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b0;
                            imm<={{16{inst_i[15]}},inst_i[15:0]};
                            instvalid<=`InstValid;
                        end
                        `EXE_TGEIU:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_TGEIU_OP;
                            alusel_o<=`EXE_RES_NOP;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b0;
                            imm<={{16{inst_i[15]}},inst_i[15:0]};
                            instvalid<=`InstValid;
                        end
                        `EXE_TLTI:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_TLTI_OP;
                            alusel_o<=`EXE_RES_NOP;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b0;
                            imm<={{16{inst_i[15]}},inst_i[15:0]};
                            instvalid<=`InstValid;
                        end
                        `EXE_TLTIU:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_TLTIU_OP;
                            alusel_o<=`EXE_RES_NOP;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b0;
                            imm<={{16{inst_i[15]}},inst_i[15:0]};
                            instvalid<=`InstValid;
                        end
                        `EXE_TNEI:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_TNEI_OP;
                            alusel_o<=`EXE_RES_NOP;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b0;
                            imm<={{16{inst_i[15]}},inst_i[15:0]};
                            instvalid<=`InstValid;
                        end

                        `EXE_BGEZ:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_BGEZ_OP;
                            alusel_o<=`EXE_RES_JUMP_BRANCH;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b0;
                            instvalid<=`InstValid;
                            if(reg1_o[31]==1'b0)begin
                                branch_target_address_o<=
                                            pc_plus_4+imm_sll2_signedext;
                                branch_flag_o<=`Branch;
                                next_inst_in_delayslot_o<=`InDelaySlot;
                            end
                        end
                        `EXE_BGEZAL:begin
                            wreg_o<=`WriteEnable;
                            aluop_o<=`EXE_BGEZAL_OP;
                            alusel_o<=`EXE_RES_JUMP_BRANCH;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b0;
                            link_addr_o<=pc_plus_8;
                            wd_o<=5'b11111;
                            instvalid<=`InstValid;
                            if(reg1_o[31]==1'b0)begin
                                branch_target_address_o<=
                                            pc_plus_4+imm_sll2_signedext;
                                branch_flag_o<=`Branch;
                                next_inst_in_delayslot_o<=`InDelaySlot;
                            end
                        end
                        `EXE_BLTZ:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_BLTZ_OP;
                            alusel_o<=`EXE_RES_JUMP_BRANCH;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b0;
                            link_addr_o<=pc_plus_8;
                            wd_o<=5'b11111;
                            instvalid<=`InstValid;
                            if(reg1_o[31]==1'b0)begin
                                branch_target_address_o<=
                                            pc_plus_4+imm_sll2_signedext;
                                branch_flag_o<=`Branch;
                                next_inst_in_delayslot_o<=`InDelaySlot;
                            end
                        end
                        `EXE_BLTZAL:begin
                            wreg_o<=`WriteEnable;
                            aluop_o<=`EXE_BLTZAL_OP;
                            alusel_o<=`EXE_RES_JUMP_BRANCH;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b0;
                            link_addr_o<=pc_plus_8;
                            wd_o<=5'b11111;
                            instvalid<=`InstValid;
                            if(reg1_o[31]==1'b1)begin
                                branch_target_address_o<=
                                            pc_plus_4+imm_sll2_signedext;
                                branch_flag_o<=`Branch;
                                next_inst_in_delayslot_o<=`InDelaySlot;
                            end
                        end
                        default:begin
                        end
                    endcase
                  end
                  `EXE_SPECIAL2_INST:begin
                    case(op3)

                        `EXE_MADD:  begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_MADD_OP;
                            alusel_o<=`EXE_RES_MUL;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b1;
                            instvalid<=`InstValid;
                        end
                        `EXE_MADDU:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_MADDU_OP;
                            alusel_o<=`EXE_RES_MUL;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b1;
                            instvalid<=`InstValid;
                        end
                        `EXE_MSUB:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_MSUB_OP;
                            alusel_o<=`EXE_RES_MUL;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b1;
                            instvalid<=`InstValid;
                        end
                        `EXE_MSUBU:begin
                            wreg_o<=`WriteDisable;
                            aluop_o<=`EXE_MSUBU_OP;
                            alusel_o<=`EXE_RES_MUL;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b1;
                            instvalid<=`InstValid;
                        end
                        `EXE_CLZ:begin
                            wreg_o<=`WriteEnable;
                            aluop_o<=`EXE_CLZ_OP;
                            alusel_o<=`EXE_RES_ARITHMETIC;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b0;
                            instvalid<=`InstValid;
                        end
                        `EXE_CLO:begin
                            wreg_o<=`WriteEnable;
                            aluop_o<=`EXE_CLO_OP;
                            alusel_o<=`EXE_RES_ARITHMETIC;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b0;
                            instvalid<=`InstValid;
                        end
                        `EXE_MUL:begin
                            wreg_o<=`WriteEnable;
                            aluop_o<=`EXE_MUL_OP;
                            alusel_o<=`EXE_RES_MUL;
                            reg1_read_o<=1'b1;
                            reg2_read_o<=1'b1;
                            instvalid<=`InstValid;
                        end
                        default:begin
                        end
                     endcase    //EXE_SPECIAL_INST2 case
                  end
                  default:begin
                  end
               endcase      //case op

               if(inst_i==`EXE_ERET)begin
                    wreg_o<=`WriteDisable;
                    aluop_o<=`EXE_ERET_OP;
                    alusel_o<=`EXE_RES_NOP;
                    reg1_read_o<=1'b0;
                    reg2_read_o<=1'b0;
                    instvalid<=`InstValid;
                    excepttype_is_eret<=`True_v;
               end
               
               if(inst_i[31:21]==11'b00000000000)begin
                if(op3==`EXE_SLL)begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_SLL_OP;
                    alusel_o<=`EXE_RES_SHIFT;
                    reg1_read_o<=1'b0;
                    reg2_read_o<=1'b1;
                    imm[4:0]<=inst_i[10:6];
                    wd_o<=inst_i[15:11];
                    instvalid<=`InstValid;
                end else if(op3==`EXE_SRL)begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_SRL_OP;
                    alusel_o<=`EXE_RES_SHIFT;
                    reg1_read_o<=1'b0;
                    reg2_read_o<=1'b1;
                    imm[4:0]<=inst_i[10:6];
                    wd_o<=inst_i[15:11];
                    instvalid<=`InstValid;
                end else if(op3==`EXE_SRA)begin
                    wreg_o<=`WriteEnable;
                    aluop_o<=`EXE_SRA_OP;
                    alusel_o<=`EXE_RES_SHIFT;
                    reg1_read_o<=1'b0;
                    reg2_read_o<=1'b1;
                    imm[4:0]<=inst_i[10:6];
                    wd_o<=inst_i[15:11];
                    instvalid<=`InstValid;
                end
              end
            end
         end
         
   //给reg1_0赋值时增加两种情况
    //  1.reg1_o 要读取的寄存器是执行阶段要写的寄存器时 reg1_o=ex_wdata_i
    //  2.reg1_o 要读取的寄存器是访存阶段要写的寄存器时 reg1_o=mem_wdata_i
	always @ (*) begin
        stallreq_for_reg1_loadrelate<=`NoStop;
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
        end else if(pre_inst_is_load==1'b1&&ex_wd_i==reg1_addr_o&&reg1_read_o==1'b1)begin
            stallreq_for_reg1_loadrelate<=`Stop;
	   end else if((reg1_read_o==1'b1)&&(ex_wreg_i==1'b1)&&(ex_wd_i==reg1_addr_o))begin
	       reg1_o<=ex_wdata_i;
	   end else if((reg1_read_o==1'b1)&&(mem_wreg_i==1'b1)&&(mem_wd_i==reg1_addr_o))begin
	       reg1_o<=mem_wdata_i;
	  end else if(reg1_read_o == 1'b1) begin
	  	reg1_o <= reg1_data_i;
	  end else if(reg1_read_o == 1'b0) begin
	  	reg1_o <= imm;
	  end else begin
	    reg1_o <= `ZeroWord;
	  end
	end
	
	// reg2_o与reg1_o类似
	always @ (*) begin
        stallreq_for_reg2_loadrelate<=`NoStop;
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
        end else if(pre_inst_is_load==1'b1 && ex_wd_i==reg2_addr_o&&reg2_read_o==1'b1)begin
            stallreq_for_reg2_loadrelate<=`Stop;    
	    end else if((reg2_read_o==1'b1)&&(ex_wreg_i==1'b1)&&(ex_wd_i==reg2_addr_o))begin
	       reg2_o<=ex_wdata_i;
	    end else if((reg2_read_o==1'b1)&&(mem_wreg_i==1'b1)&&(mem_wd_i==reg2_addr_o))begin
	       reg2_o<=mem_wdata_i;
	    end else if(reg2_read_o == 1'b1) begin
	  	    reg2_o <= reg2_data_i;
	    end else if(reg2_read_o == 1'b0) begin
	  	    reg2_o <= imm;
        end else begin
            reg2_o <= `ZeroWord;
        end
	end

    always@(*)begin
        if(rst==`RstEnable)begin
            is_in_delayslot_o<=`NotInDelaySlot;
        end else begin
            is_in_delayslot_o<=is_in_delayslot_i;
        end
    end

    assign stallreq=stallreq_for_reg1_loadrelate|
                    stallreq_for_reg2_loadrelate;

    assign TLBWI 	= !(inst_i[31:26] ^ `EXE_COP0) & !(inst_i[5:0] ^ `EXE_TLBWI	);
	assign TLBP 	= !(inst_i[31:26] ^ `EXE_COP0) & !(inst_i[5:0] ^ `EXE_TLBP	);
	assign TLBR 	= !(inst_i[31:26] ^ `EXE_COP0) & !(inst_i[5:0] ^ `EXE_TLBR	);
	assign TLBWR 	= !(inst_i[31:26] ^ `EXE_COP0) & !(inst_i[5:0] ^ `EXE_TLBWR	);
	assign tlb_typeD = {TLBWR, TLBWI, TLBR, TLBP};
endmodule
