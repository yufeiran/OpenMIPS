`include "OpenMIPS.vh"

module tlb(
    input wire rst,
    input wire clk,
    input wire stallM,
    input wire flushM,
    input wire [31:0] inst_vaddr,
    input wire [31:0] data_vaddr,
    input wire inst_en,
    input wire mem_read_enM,
    input wire mem_write_enM,
    output wire [`TAG_WIDTH-1:0] inst_pfn,
    output wire [`TAG_WIDTH-1:0] data_pfn,
    output wire [31:0] inst_paddr,
    output wire [31:0] data_paddr,
    output wire no_cache_i,
    output wire no_cache_d,

    output wire inst_tlb_refill,
    output wire inst_tlb_invalid,
    output wire data_tlb_refill,
    output wire data_tlb_invalid,
    output wire data_tlb_modify,

    input wire TLBP,
    input wire TLBR,
    input wire TLBWI,
    input wire TLBWR,
    input wire [31:0] EntryHi_in,
    input wire [31:0] PageMask_in,
    input wire [31:0] EntryLo0_in,
    input wire [31:0] EntryLo1_in,
    input wire [31:0] Index_in,
    input wire [31:0] Random_in,

    output wire [31:0] EntryHi_out,
    output wire [31:0] PageMask_out,
    output wire [31:0] EntryLo0_out,
    output wire [31:0] EntryLo1_out,
    output wire [31:0] Index_out
);


/**
    查找TLB�?
        把输入的地址和TLB每一项对比，生成MASK(只有1位为1)，然后用编码器生成一个索引index
        1. 如果是访存指令，由于输入的地�?是E阶段的，因此将index经过�?级流水线（为M阶段），得到index_r
            通过index_r访问特定项，获得tlb_entrylo,获取pfn,flag等信�?
        2. 如果是TLBP指令，则index是根据M阶段的EntryHi_in产生的，直接将其赋�?�给EntryHi_out
    读TLB逻辑:
        根据index直接访问TLB中对应的项，index可以来自地址查找生成的index，也可以来TLBR的Index_in
    写TLB逻辑�?
        TLBWI，TLBWR

*/


// TLB layout
// |     EntryHi           |        PageMask         |             EntryLo0          |             EntryLo1          |
// | VPN2 | 0   |    ASID  | 0   |  PageMask |  0    |   0   | PFN0     |  C,D,V,G   |   0   |  PFN1    |   C,D,V,G  |
// | 19bit| 5bit|    8bit  | 7bit|    12bit  |  13bit|  7bit | 20bit    |   5bit     |   7bit|  20bit   |    5bit    |

reg [31:0] TLB_EntryHi[0:`TLB_SUM-1];
reg [31:0] TLB_PageMask[0:`TLB_SUM-1];
reg [31:0] TLB_EntryLo0[0:`TLB_SUM-1];
reg [31:0] TLB_EntryLo1[0:`TLB_SUM-1];


//----------------------------------查找TLB---------------------------------------------
wire [31:0] vaddr1,vaddr2;

assign vaddr1=inst_vaddr;

assign vaddr2=TLBP?EntryHi_in:data_vaddr;

wire [`TLB_SUM-1:0]  find_mask1,find_mask2;
wire [`TLB_SUM_log2-1:0] find_index1,find_index2;
reg [`TLB_SUM_log2-1:0] find_index1_r,find_index2_r;
wire find1,find2;
reg find1_r,find2_r;
assign find1=|find_mask1;
assign find2=|find_mask2;

genvar i;
generate
    for(i=0;i<`TLB_SUM;i=i+1)
    begin:find
        assign find_mask1[i]=((vaddr1[`VPN2_BITS]&~TLB_PageMask[i][`VPN2_BITS])==(TLB_EntryHi[i][`VPN2_BITS]&~TLB_PageMask[i][`VPN2_BITS]))&&(TLB_EntryHi[i][`G_BIT]||TLB_EntryHi[i][`ASID_BITS]==EntryHi_in[`ASID_BITS]);
        assign find_mask2[i]=((vaddr1[`VPN2_BITS]&~TLB_PageMask[i][`VPN2_BITS])==(TLB_EntryHi[i][`VPN2_BITS]&~TLB_PageMask[i][`VPN2_BITS]))&&(TLB_EntryHi[i][`G_BIT]||TLB_EntryHi[i][`ASID_BITS]==EntryHi_in[`ASID_BITS]);
    end
endgenerate

//编码器，通过mask生成index
assign find_index2=
({5{find_mask2[0 ]}} &5'd0  ) |
({5{find_mask2[1 ]}} &5'd1  ) |
({5{find_mask2[2 ]}} & 5'd2 ) |
({5{find_mask2[3 ]}} & 5'd3 ) |
({5{find_mask2[4 ]}} & 5'd4 ) |
({5{find_mask2[5 ]}} & 5'd5 ) |
({5{find_mask2[6 ]}} & 5'd6 ) |
({5{find_mask2[7 ]}} & 5'd7 ) |
({5{find_mask2[8 ]}} & 5'd8 ) |
({5{find_mask2[9 ]}} & 5'd9 ) |
({5{find_mask2[10]}} & 5'd10) |
({5{find_mask2[11]}} & 5'd11) |
({5{find_mask2[12]}} & 5'd12) |
({5{find_mask2[13]}} & 5'd13) |
({5{find_mask2[14]}} & 5'd14) |
({5{find_mask2[15]}} & 5'd15) |
({5{find_mask2[16]}} & 5'd16) |
({5{find_mask2[17]}} & 5'd17) |
({5{find_mask2[18]}} & 5'd18) |
({5{find_mask2[19]}} & 5'd19) |
({5{find_mask2[20]}} & 5'd20) |
({5{find_mask2[21]}} & 5'd21) |
({5{find_mask2[22]}} & 5'd22) |
({5{find_mask2[23]}} & 5'd23) |
({5{find_mask2[24]}} & 5'd24) |
({5{find_mask2[25]}} & 5'd25) |
({5{find_mask2[26]}} & 5'd26) |
({5{find_mask2[27]}} & 5'd27) |
({5{find_mask2[28]}} & 5'd28) |
({5{find_mask2[29]}} & 5'd29) |
({5{find_mask2[30]}} & 5'd30) |
({5{find_mask2[31]}} & 5'd31);


assign find_index1=
({5{find_mask1[0 ]}} & 5'd0 ) |
({5{find_mask1[1 ]}} & 5'd1 ) |
({5{find_mask1[2 ]}} & 5'd2 ) |
({5{find_mask1[3 ]}} & 5'd3 ) |
({5{find_mask1[4 ]}} & 5'd4 ) |
({5{find_mask1[5 ]}} & 5'd5 ) |
({5{find_mask1[6 ]}} & 5'd6 ) |
({5{find_mask1[7 ]}} & 5'd7 ) |
({5{find_mask1[8 ]}} & 5'd8 ) |
({5{find_mask1[9 ]}} & 5'd9 ) |
({5{find_mask1[10]}} & 5'd10) |
({5{find_mask1[11]}} & 5'd11) |
({5{find_mask1[12]}} & 5'd12) |
({5{find_mask1[13]}} & 5'd13) |
({5{find_mask1[14]}} & 5'd14) |
({5{find_mask1[15]}} & 5'd15) |
({5{find_mask1[16]}} & 5'd16) |
({5{find_mask1[17]}} & 5'd17) |
({5{find_mask1[18]}} & 5'd18) |
({5{find_mask1[19]}} & 5'd19) |
({5{find_mask1[20]}} & 5'd20) |
({5{find_mask1[21]}} & 5'd21) |
({5{find_mask1[22]}} & 5'd22) |
({5{find_mask1[23]}} & 5'd23) |
({5{find_mask1[24]}} & 5'd24) |
({5{find_mask1[25]}} & 5'd25) |
({5{find_mask1[26]}} & 5'd26) |
({5{find_mask1[27]}} & 5'd27) |
({5{find_mask1[28]}} & 5'd28) |
({5{find_mask1[29]}} & 5'd29) |
({5{find_mask1[30]}} & 5'd30) |
({5{find_mask1[31]}} & 5'd31);

//----------------------------------查找TLB---------------------------------------------



//----------------------------------读取TLB---------------------------------------------
wire [`TLB_SUM_log2-1:0] index1,index2;
assign index1=find_index1_r;

assign index2=TLBR?Index_in[`INDEX_BITS]:find_index2;

wire [31:0] EntryLo0_read1;
wire [31:0] EntryLo1_read1;

reg [31:0] EntryHi_read2;
reg [31:0] PageMask_read2;
reg [31:0] EntryLo0_read2;
reg [31:0] EntryLo1_read2;

wire [31:0] EntryHi_read2_r;
wire [31:0] PageMask_read2_r;
wire [31:0] EntryLo0_read2_r;
wire [31:0] EntryLo1_read2_r;

assign EntryLo0_read1=TLB_EntryLo0[index1];
assign EntryLo1_read1=TLB_EntryLo1[index1];

assign EntryHi_read2_r=TLB_EntryHi[index2];
assign PageMask_read2_r=TLB_PageMask[index2];
assign EntryLo0_read2_r=TLB_EntryLo0[index2];
assign EntryLo1_read2_r=TLB_EntryLo1[index2];

always@(posedge clk)begin
    if(rst|flushM)begin
        EntryHi_read2  <=0;
        PageMask_read2 <=0;
        EntryLo0_read2 <=0;
        EntryLo1_read2 <=0;    
    end
    else if(~stallM)begin
        EntryHi_read2 <=EntryHi_read2_r;                                                  
        PageMask_read2 <= PageMask_read2_r;
        EntryLo0_read2 <= EntryLo0_read2_r;
        EntryLo1_read2 <= EntryLo1_read2_r;
    end
end
//----------------------------------读取TLB---------------------------------------------




//--------------------------------写TLB---------------------------------------------
wire [`TLB_SUM_log2-1:0] write_index;
assign write_index = TLBWI?Index_in[`INDEX_BITS]:Random_in[`INDEX_BITS];

integer tt;
always@(posedge clk)
begin
    if(rst)begin
        for(tt=0;tt<`TLB_SUM;tt=tt+1)begin
            TLB_EntryHi[tt]<=0;
            TLB_PageMask[tt]<=0;
            TLB_EntryLo0[tt]<=0;
            TLB_EntryLo1[tt]<=0;
        end
    end
    else if(TLBWI|TLBWR)
    begin
        TLB_EntryHi[write_index][`VPN2_BITS]<=EntryHi_in[`VPN2_BITS]&~PageMask_in[`VPN2_BITS];
        TLB_EntryHi[write_index][`G_BIT]    <=EntryLo0_in[0]&EntryLo1_in[0];
        TLB_EntryHi[write_index][`ASID_BITS]<=EntryHi_in[`ASID_BITS];
        TLB_PageMask[write_index]           <=PageMask_in;
        TLB_EntryLo0[write_index][`PFN_BITS]<=EntryLo0_in[`PFN_BITS]&~PageMask_in[`MASK_BITS];
        TLB_EntryLo0[write_index][`C_BITS]  <=EntryLo0_in[`C_BITS];
        TLB_EntryLo0[write_index][`D_BIT]   <=EntryLo0_in[`D_BIT];
        TLB_EntryLo0[write_index][`V_BIT]   <=EntryLo0_in[`V_BIT];
        TLB_EntryLo1[write_index][`PFN_BITS]<=EntryLo1_in[`PFN_BITS]&~PageMask_in[`MASK_BITS];
        TLB_EntryLo1[write_index][`C_BITS]  <=EntryLo1_in[`C_BITS];
        TLB_EntryLo1[write_index][`D_BIT]   <=EntryLo1_in[`D_BIT];
        TLB_EntryLo1[write_index][`V_BIT]   <=EntryLo1_in[`V_BIT];
    end

end

//--------------------------------写TLB---------------------------------------------

//--------------------------------output-------------------------------------------
//data地址映射
wire data_oddE;
reg data_oddM;
assign data_oddE=data_vaddr[`OFFSET_WIDTH];

wire data_kseg01E;
reg data_kseg01M;
wire data_kseg1E;
reg data_kseg1M;
assign data_kseg01E=data_vaddr[31:30]==2'b10 ?1'b1:1'b0;
assign data_kseg1E=data_vaddr[31:29]==3'b101 ? 1'b1:1'b0;

wire [`TAG_WIDTH-1:0] data_vpnE;
reg [`TAG_WIDTH-1:0] data_vpnM;
assign data_vpnE=data_vaddr[31:`OFFSET_WIDTH];

//M阶段的data的物理页�?
assign data_pfn=data_kseg01M? {3'b0,data_vpnM[`TAG_WIDTH-4:0]}:
            ~data_oddM ? EntryLo0_read2[`PFN_BITS]:EntryLo1_read2[`PFN_BITS];


wire [5:0] data_flag;
assign data_flag=~data_oddM?EntryLo0_read2[`FLAG_BITS]:EntryLo1_read2[`FLAG_BITS];

assign no_cache_d=data_kseg01M?(data_kseg1M?1'b1:1'b0):
                data_flag[`C_BITS]==3'b010 ?1'b1:1'b0;
//inst地址映射
wire inst_oddE;
reg inst_oddM;
assign inst_oddE=inst_vaddr[`OFFSET_WIDTH];

wire isnt_kseg01E,inst_kseg1E;
reg inst_kseg01M,inst_kseg1M;
assign inst_kseg01E=inst_vaddr[31:30]==2'b10 ? 1'b1:1'b0;
assign inst_kseg1E=inst_vaddr[31:29]==3'b101 ? 1'b1:1'b0;


wire [`TAG_WIDTH-1:0] inst_vpnE;
reg [`TAG_WIDTH-1:0] inst_vpnM;
assign inst_vpnE=inst_vaddr[31:`OFFSET_WIDTH];

assign inst_pfn=inst_kseg01M?{3'b0,inst_vpnM[`TAG_WIDTH-4:0]}:
                ~inst_oddM ? EntryLo0_read1[`PFN_BITS]:EntryLo1_read1[`PFN_BITS];

wire [5:0] inst_flag;
assign inst_flag=~inst_oddM?EntryLo0_read1[`FLAG_BITS]:EntryLo1_read1[`FLAG_BITS];

assign no_cache_i=inst_kseg01M?(inst_kseg1M ? 1'b1:1'b0):
            inst_flag[`C_BITS]==3'b010 ? 1'b1:1'b0;


//tlb指令

//tlbr
assign EntryHi_out=EntryHi_read2;
assign PageMask_out=PageMask_read2;
assign EntryLo0_out={EntryLo0_read2[31:1],EntryHi_read2[`G_BIT]};
assign EntryLo1_out={EntryLo1_read2[31:1],EntryHi_read2[`G_BIT]};

//tlbp
assign Index_out=find2 ? find_index2:32'h8000_0000;

//异常
//取指TLB异常
assign inst_tlb_refill = inst_kseg01M ? 1'b0 : (inst_en & ~find1_r);
assign inst_tlb_invalid = inst_kseg01M?1'b0:(inst_en & find1_r &~inst_flag[`V_BIT]);

wire data_V,data_D;
assign data_V=data_flag[`V_BIT];
assign data_D=data_flag[`D_BIT];

assign data_tlb_refill = data_kseg01M ? 1'b0:(mem_read_enM | mem_write_enM)&~find2_r;
assign data_tlb_invalid = data_kseg01M ? 1'b0:(mem_read_enM | mem_write_enM)&find2_r&~data_V;
assign data_tlb_modify = data_kseg01M ? 1'b0: mem_write_enM & find2_r &data_V &~data_D;

//--------------------------------output---------------------------------

//-------------------------------pipeline--------------------------------
always@(posedge clk)begin
    if(rst|flushM)begin
        find1_r       <= 0;
        find2_r       <= 0;
        find_index1_r <= 0;
        find_index2_r <= 0;

        data_oddM     <= 0;
        data_kseg01M  <= 0;
        data_kseg1M   <= 0;
        data_vpnM     <= 0;

        inst_oddM     <= 0;
        inst_kseg01M  <= 0;
        inst_kseg1M   <= 0;
        inst_vpnM     <= 0;
    end
    else if(~stallM)begin
        find1_r       <= find1  ;
        find2_r       <= find2  ;
        find_index1_r <= find_index1;
        find_index2_r <= find_index2;

        data_oddM     <= data_oddE;
        data_kseg01M  <= data_kseg01E;
        data_kseg1M   <= data_kseg1E;
        data_vpnM     <= data_vpnE;

        inst_oddM     <= inst_oddE;
        inst_kseg01M  <= inst_kseg01E;
        inst_kseg1M   <= inst_kseg1E;
        inst_vpnM     <= inst_vpnE;
    end
end 



//-------------------------------pipeline--------------------------------


endmodule