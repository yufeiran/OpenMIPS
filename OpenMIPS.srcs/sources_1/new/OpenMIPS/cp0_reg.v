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

    input wire [31:0]   excepttype_i,
    input wire [`RegBus]    current_inst_addr_i,
    input wire              is_in_delayslot_i,
    input wire [31:0]   badvaddr,  

    input wire inst_tlb_refill,
    input wire inst_tlb_invalid,
    input wire data_tlb_refill,
    input wire data_tlb_invalid,
    input wire data_tlb_modify,

    //tlb in
    input wire [3:0] tlb_typeM,
    input wire [31:0] entry_lo0_in,
    input wire [31:0] entry_lo1_in,
    input wire [31:0] page_mask_in,
    input wire [31:0] entry_hi_in,
    input wire [31:0] index_in,


   
    output reg[`RegBus] data_o,
    output reg[`RegBus] count_o,
    output reg[`RegBus] compare_o,
    output reg[`RegBus] status_o,
    output reg[`RegBus] cause_o,
    output reg[`RegBus] epc_o,
    output reg[`RegBus] wired_o,
    output reg[`RegBus] config_o,
    output reg[`RegBus] prid_o,

    //tlb reg
    output reg[`RegBus] random_o,
    output reg[`RegBus] index_o,
    output reg[`RegBus] EntryHi_o,
    output reg[`RegBus] EntryLo0_o,
    output reg[`RegBus] EntryLo1_o,
    output reg[`RegBus] PageMask_o,
    output reg[`RegBus] badvaddr_o,

    output reg          timer_int_o
    );



    always@(posedge clk)begin
        
        if(rst==`RstEnable)begin
            //Count init
            count_o<=`ZeroWord;
            //Compare init
            compare_o<=`ZeroWord;
            status_o<=32'b00010000000000000000000000000000;
            cause_o<=`ZeroWord;
            epc_o<=`ZeroWord;
            config_o<=32'b00000000000000001000000000000000;
            prid_o<=32'b00000000010011000000000100000010;
            wired_o<=`ZeroWord;
            timer_int_o<=`InterruptNotAssert;
        end else begin
            count_o<=count_o+1;
            cause_o[15:10]<=int_i;       //Cause 10~15bit save int
            
            if(compare_o!=`ZeroWord && count_o>=compare_o)begin
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
                    `CP0_REG_WIRED:begin
                        wired_o[`WIRED_BITS]<=data_i[`WIRED_BITS];
                    end
                    `CP0_REG_CAUSE:begin    
                        //Cause can only write IP[1:0]\IV\WP
                        cause_o[9:8]<=data_i[9:8];
                        cause_o[23]<=data_i[23];
                        cause_o[22]<=data_i[22];
                    end

                endcase
            end
            case(excepttype_i)
                32'h00000001:begin
                    if(is_in_delayslot_i==`InDelaySlot)begin
                        epc_o<=current_inst_addr_i-4;
                        cause_o[31]<=1'b1;
                    end else begin
                        epc_o<=current_inst_addr_i;
                        cause_o[31]<=1'b0;
                    end
                    status_o[1]<=1'b1;
                    cause_o[6:2]<=5'b00000;
                end
                32'h00000008:begin
                    if(status_o[1]==1'b0)begin
                        if(is_in_delayslot_i==`InDelaySlot)begin
                            epc_o<=current_inst_addr_i-4;
                            cause_o[31]<=1'b1;
                        end else begin
                            epc_o<=current_inst_addr_i;
                            cause_o[31]<=1'b0;
                        end
                    end
                    status_o[1]<=1'b1;
                    cause_o[6:2]<=5'b01000;

                end
                32'h0000000a:begin
                    if(status_o[1]==1'b0)begin
                        if(is_in_delayslot_i==`InDelaySlot)begin
                            epc_o<=current_inst_addr_i-4;
                            cause_o[31]<=1'b1;
                        end else begin
                        epc_o<=current_inst_addr_i;
                        cause_o[31]<=1'b0;
                        end
                    end
                    status_o[1]<=1'b1;
                    cause_o[6:2]<=5'b01010;
                end
                32'h0000000d:begin
                    if(status_o[1]==1'b0)begin
                        if(is_in_delayslot_i==`InDelaySlot)begin
                            epc_o<=current_inst_addr_i-4;
                            cause_o[31]<=1'b1;
                        end else begin
                            epc_o<=current_inst_addr_i;
                            cause_o[31]<=1'b0;
                        end
                    end
                    status_o[1]<=1'b1;
                    cause_o[6:2]<=5'b01101;
                end

                32'h0000000c:begin
                    if(status_o[1]==1'b0)begin
                        if(is_in_delayslot_i==`InDelaySlot)begin
                            epc_o<=current_inst_addr_i-4;
                            cause_o[31]<=1'b1;
                        end else begin
                            epc_o<=current_inst_addr_i;
                            cause_o[31]<=1'b0;
                        end
                    end
                    status_o[1]<=1'b1;
                    cause_o[6:2]<=5'b01100;
                end

                32'h0000000e:begin
                    status_o[1]<=1'b0;
                end
                default:begin
                    if(inst_tlb_refill==1'b1||inst_tlb_invalid==1'b1)begin
                        if(status_o[1]==1'b0)begin
                            if(is_in_delayslot_i==`InDelaySlot)begin
                                epc_o<=current_inst_addr_i-4;
                                cause_o[31]<=1'b1;
                            end else begin
                                epc_o<=current_inst_addr_i;
                                cause_o[31]<=1'b0;
                            end
                        end
                        status_o[1]<=1'b1;
                        cause_o[6:2]<=5'b00010;
                    end
                    else if(data_tlb_refill==1'b1||data_tlb_invalid==1'b1)begin
                        if(status_o[1]==1'b0)begin
                            if(is_in_delayslot_i==`InDelaySlot)begin
                                epc_o<=current_inst_addr_i-4;
                                cause_o[31]<=1'b1;
                            end else begin
                                epc_o<=current_inst_addr_i;
                                cause_o[31]<=1'b0;
                            end
                        end
                        status_o[1]<=1'b1;
                        cause_o[6:2]<=5'b00011;
                    end
                    else if(data_tlb_modify==1'b1)begin
                        if(status_o[1]==1'b0)begin
                            if(is_in_delayslot_i==`InDelaySlot)begin
                                epc_o<=current_inst_addr_i-4;
                                cause_o[31]<=1'b1;
                            end else begin
                                epc_o<=current_inst_addr_i;
                                cause_o[31]<=1'b0;
                            end
                        end
                        status_o[1]<=1'b1;
                        cause_o[6:2]<=5'b00001;
                    end
                end
            endcase

            
        end
    end

    //badvaddr
    wire badvaddr_wen;
    //mod 0x01 TLBL 0x02 TLBS 0x03
    assign badvaddr_wen = (excepttype_i==1)||(excepttype_i==2)||(excepttype_i==3)?1'b1:1'b0;
    always@(posedge clk)begin
        if(badvaddr_wen)
            badvaddr_o<=badvaddr; 
    end
    //TLB
        //random
        wire wired_wen;
        assign wired_wen = we_i & (waddr_i == `CP0_REG_WIRED);
        always @(posedge clk)begin
            if(rst)begin
                random_o<=`TLB_SUM-1;
            end
            else if(random_o==wired_o|wired_wen)begin
                random_o<=`TLB_SUM-1;
            end
            else begin
                random_o<=random_o-1;
            end
        end

        //index,entry_hi/lo,page_mask
        wire mtc0_index,mtc0_entry_lo0,mtc0_entry_lo1,mtc0_entry_hi,mtc0_page_mask;

        //1. mtc0�?
        assign mtc0_index=we_i&(waddr_i==`CP0_REG_INDEX);
        assign mtc0_entry_hi=we_i&(waddr_i==`CP0_REG_EntryHi);
        assign mtc0_entry_lo0=we_i&(waddr_i==`CP0_REG_EntryLo0);
        assign mtc0_entry_lo1=we_i&(waddr_i==`CP0_REG_EntryLo1);
        assign mtc0_page_mask=we_i&(waddr_i==`CP0_REG_PageMask);
        //2. tlb指令�?
        wire tlbr,tlbp,tlbwi,tlbwr;
        assign {tlbwr,tlbwi,tlbr,tlbp}=tlb_typeM;
        //3.异常更新 entry_hi
        wire tlb_exception;
        assign tlb_exception=~|excepttype_i[4:2]&|excepttype_i[1:0]; //exe_code_mod , exe_code_tlbl,exe_code_tlbs

        always@(posedge clk or posedge rst)begin
            if(rst)begin
               index_o<=32'd0;
               EntryLo0_o<=32'd0; 
               EntryLo1_o<=32'd0;
               EntryHi_o<=32'd0;
               PageMask_o<=32'd0;

            end 
            else begin
                index_o[31]    <= tlbp ? index_in[31]:index_o[31];

                index_o[`INDEX_BITS]<=tlbp ? index_in[`INDEX_BITS]:
                                mtc0_index ? data_i[`INDEX_BITS]:index_o[`INDEX_BITS];

                EntryLo0_o[`PFN_BITS] <= tlbr ? entry_lo0_in[`PFN_BITS]&~page_mask_in[`MASK_BITS]:
                                mtc0_entry_lo0 ? data_i[`PFN_BITS]:EntryLo0_o[`PFN_BITS];
                EntryLo0_o[`FLAG_BITS] <=tlbr ? entry_lo0_in[`FLAG_BITS]:
                                mtc0_entry_lo0 ? data_i[`FLAG_BITS]:EntryLo0_o[`FLAG_BITS];

                EntryLo1_o[`PFN_BITS] <= tlbr ? entry_lo1_in[`PFN_BITS]&~page_mask_in[`MASK_BITS]:
                                mtc0_entry_lo1 ? data_i[`PFN_BITS]:EntryLo1_o[`PFN_BITS];
                EntryLo1_o[`FLAG_BITS] <=tlbr ? entry_lo1_in[`FLAG_BITS]:
                                mtc0_entry_lo1 ? data_i[`FLAG_BITS]:EntryLo1_o[`FLAG_BITS];
                
                EntryHi_o[`VPN2_BITS] <= tlbr ? entry_hi_in[`VPN2_BITS]&~page_mask_in[`MASK_BITS]:
                                mtc0_entry_hi ? data_i[`VPN2_BITS]:
                                tlb_exception ? badvaddr[`VPN2_BITS]:EntryHi_o[`VPN2_BITS];
                EntryHi_o[`ASID_BITS] <= tlbr ? entry_hi_in[`ASID_BITS]:
                                mtc0_entry_hi ? data_i[`ASID_BITS]:EntryHi_o[`ASID_BITS];
                PageMask_o[`MASK_BITS] <=tlbr ? page_mask_in[`MASK_BITS]:
                                mtc0_page_mask ? data_i[`MASK_BITS]:PageMask_o[`MASK_BITS];
                
            end         
        end

    //---------------------------read------------------------------------------
    always@(*)begin
        if(rst==`RstEnable)begin
            data_o<=`ZeroWord;
        end else begin
            case(raddr_i)
                `CP0_REG_WIRED:begin
                    data_o<=wired_o;
                end
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
                `CP0_REG_PrId:begin
                    data_o<=prid_o;
                end
                `CP0_REG_CONFIG:begin
                    data_o<=config_o;
                end
                `CP0_REG_INDEX:begin
                    data_o<=index_o;
                end
                `CP0_REG_EntryHi:begin
                    data_o<=EntryHi_o;
                end
                `CP0_REG_EntryLo0:begin
                    data_o<=EntryLo0_o;
                end
                `CP0_REG_EntryLo1:begin
                    data_o<=EntryLo1_o;
                end
                `CP0_REG_PageMask:begin
                    data_o<=PageMask_o;
                end
                default:begin
                end
            endcase
        end
    end
            
endmodule

