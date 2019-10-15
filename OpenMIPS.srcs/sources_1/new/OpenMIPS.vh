//**************************************    全局的宏定义          *****************************
`define RstEnable           1'b1                    //复位信号有效
`define RstDisable          1'b0                    //复位信号无效
`define ZeroWord            32'h00000000            //32位的数值0
`define WriteEnable         1'b1                    //写使能
`define WriteDisable        1'b0                    //禁止写
`define ReadEnable          1'b1                    //读使能
`define ReadDisable         1'b0                    //禁止读
`define AluOpBus            7:0                     //译码阶段的输出   aluop_o 的宽度
`define AluSelBus           2:0                     //译码阶段的输出   alusel_o的宽度
`define InstValid           1'b0                    //指令有效
`define InstInvalid         1'b1                    //指令无效
`define True_V              1'b1                    //逻辑“真”
`define False_V             1'b0                    //逻辑“假”
`define ChipEnable          1'b1                    //芯片使能
`define ChipDisable         1'b0                    //芯片禁止

`define Stop                1'b1                    //流水线暂停
`define NoStop              1'b0                    //流水线继续

//************************** 与具体指令有关的宏定义 *******************************
`define EXE_ORI         6'b001101           //指令ori的指令码
`define EXE_NOP         6'b000000
`define EXE_AND         6'b100100
`define EXE_OR          6'b100101
`define EXE_XOR         6'b100110
`define EXE_NOR         6'b100111
`define EXE_ANDI        6'b001100
`define EXE_XORI        6'b001110
`define EXE_LUI         6'b001111

`define EXE_SLL         6'b000000
`define EXE_SLLV        6'b000100
`define EXE_SRL         6'b000010
`define EXE_SRLV        6'b000110
`define EXE_SRA         6'b000011
`define EXE_SRAV        6'b000111

`define EXE_SYNC        6'b001111
`define EXE_PREF        6'b110011
`define EXE_SPECIAL_INST    6'b000000

`define EXE_MOVZ  6'b001010
`define EXE_MOVN  6'b001011
`define EXE_MFHI  6'b010000
`define EXE_MTHI  6'b010001
`define EXE_MFLO  6'b010010
`define EXE_MTLO  6'b010011

`define EXE_SLT     6'b101010
`define EXE_SLTU    6'b101011
`define EXE_SLTI    6'b001010
`define EXE_SLTIU   6'b001011
`define EXE_ADD     6'b100000
`define EXE_ADDU    6'b100001
`define EXE_SUB     6'b100010
`define EXE_SUBU    6'b100011
`define EXE_ADDI    6'b001000
`define EXE_ADDIU   6'b001001
`define EXE_CLZ     6'b100000
`define EXE_CLO     6'b100001

`define EXE_MULT    6'b011000
`define EXE_MULTU   6'b011001
`define EXE_MUL     6'b000010

`define EXE_SPECLIAL_INST 6'b000000
`define EXE_REGIMM_INST     6'b000001
`define EXE_SPECIAL2_INST   6'b011100

`define EXE_MADD    6'b000000
`define EXE_MADDU   6'b000001
`define EXE_MSUB    6'b000100
`define EXE_MSUBU   6'b000101

//AluOp
`define EXE_NOP_OP      8'b00000000

`define EXE_AND_OP   8'b00100100
`define EXE_OR_OP    8'b00100101
`define EXE_XOR_OP  8'b00100110
`define EXE_NOR_OP  8'b00100111
`define EXE_ANDI_OP  8'b01011001
`define EXE_ORI_OP  8'b01011010
`define EXE_XORI_OP  8'b01011011
`define EXE_LUI_OP  8'b01011100   

`define EXE_SLL_OP  8'b01111100
`define EXE_SLLV_OP  8'b00000100
`define EXE_SRL_OP  8'b00000010
`define EXE_SRLV_OP  8'b00000110
`define EXE_SRA_OP  8'b00000011
`define EXE_SRAV_OP  8'b00000111

`define EXE_MOVZ_OP  8'b00001010
`define EXE_MOVN_OP  8'b00001011
`define EXE_MFHI_OP  8'b00010000
`define EXE_MTHI_OP  8'b00010001
`define EXE_MFLO_OP  8'b00010010
`define EXE_MTLO_OP  8'b00010011


`define EXE_SLT_OP     8'b00101010
`define EXE_SLTU_OP    8'b00101011
`define EXE_SLTI_OP    8'b00001010
`define EXE_SLTIU_OP   8'b00001011
`define EXE_ADD_OP     8'b00100000
`define EXE_ADDU_OP    8'b00100001
`define EXE_SUB_OP     8'b00100010
`define EXE_SUBU_OP    8'b00100011
`define EXE_ADDI_OP    8'b00001000
`define EXE_ADDIU_OP   8'b00001001
`define EXE_CLZ_OP     8'b10110000
`define EXE_CLO_OP     8'b10110001

`define EXE_MULT_OP    8'b00011000
`define EXE_MULTU_OP   8'b00011001
`define EXE_MUL_OP     8'b00000010

`define EXE_MADD_OP    8'b00000000
`define EXE_MADDU_OP   8'b00000001
`define EXE_MSUB_OP    8'b00000100
`define EXE_MSUBU_OP   8'b00000101


//AluSel
`define EXE_RES_LOGIC   3'b001
`define EXE_RES_SHIFT   3'b010
`define EXE_RES_MOVE    3'b011
`define EXE_RES_ARITHMETIC 3'b100
`define EXE_RES_MUL     3'b101

`define EXE_RES_NOP     3'b000

//************************** 与指令存储器ROM有关的宏定义 **************************
`define InstAddrBus     31:0                //ROM的地址总线宽度
`define InstBus         31:0                //ROM的数据总线宽度
`define InstMemNum      131071              //ROM的实际大小为128KB
`define InstMemNumLog2  17                  //ROM的实际使用的地址线宽度

//*************************** 与通用寄存器Regfile有关的宏定义**********************
`define RegAddrBus      4:0                 //Regfile 模块的地址线宽度
`define RegBus          31:0                //Regfile 模块的数据线宽度
`define RegWidth        32                  //通用寄存器的宽度
`define DoubleRegWidth  64                  //两倍通用寄存器的宽度
`define DoubleRegBus    63:0                //两倍的通用寄存器的数据线宽度
`define RegNum          32                  //通用寄存器的数量
`define RegNumLog2      5                   //寻址通用寄存器使用的地址位数
`define NOPRegAddr      5'b00000
