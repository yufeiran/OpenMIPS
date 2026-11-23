`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/11/22 23:47:21
// Design Name: 
// Module Name: tb_tlb
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


module tb_tlb(

    );
    
    reg clk = 1'b0;
    reg reset = 1'b1;

    reg inst_en = 1'b0;
    reg mem_read_enM = 1'b0;
    reg mem_write_enM = 1'b0;

    reg [31:0] Random_in = 32'd0;

    reg [31:0] Index_in = 32'd0;
    reg [31:0] entry_lo0_out = 32'd0;
    reg [31:0] EntryHi_in = 32'd0;
    reg [31:0] EntryLo0_in = 32'd0;
    reg [31:0] EntryLo1_in = 32'd0;
    reg [31:0] PageMask_in = 32'd0;
    reg [31:0] data_vaddr = 32'd0;


    reg TLBP  = 1'b0;
    reg TLBR  = 1'b0;
    reg TLBWI = 1'b0;
    reg TLBWR = 1'b0;

    
    always #5 clk = ~clk;
    always #5 Random_in = Random_in + 32'd1;
    
    tlb dut(
        .clk,
        .rst(reset),
        .stallM(1'b0),
        .flushM(1'b0),
        .inst_en,
        .mem_read_enM,
        .mem_write_enM,

        .data_vaddr,

        .Index_in(Index_in),
        .Random_in,
        .EntryLo0_out(entry_lo0_out),
        .inst_vaddr('0),
        .EntryHi_in,
        .EntryLo0_in,
        .EntryLo1_in,
        .PageMask_in,
        
        .TLBWI,
        .TLBWR,
        .TLBP,
        .TLBR
    );
    
    initial begin
        reset = 1'b1;
        
        #10 reset = 1'b0;
        
        #10 
        Index_in = 32'd3;
        PageMask_in = 32'd0;
        EntryHi_in = 32'h0040_0042;
        EntryLo0_in = 32'h0000_0486;
        EntryLo1_in = 32'h0000_0D06;
        TLBWI = 1'b1;



        #10 TLBWI = 1'b0;
        EntryHi_in = 32'd0;
        EntryLo0_in = 32'd0;
        EntryLo1_in = 32'd0;

        #10
        TLBR = 1'b1;

        @(posedge clk);
        #1;
        if (dut.PageMask_out !== 32'h0000_0000)
            $fatal(1, "PageMask: expected 00000000, got %08h", dut.PageMask_out);

        if(dut.EntryHi_out !== 32'h0040_0042)
            $fatal(1,"EntryHi: expected 00400042, got %08h", dut.EntryHi_out);
        
        if(dut.EntryLo0_out !== 32'h0000_0486)
            $fatal(1,"EntryLo0: expected 00000486, got %08h", dut.EntryLo0_out);

        if(dut.EntryLo1_out !== 32'h0000_0D06)
            $fatal(1,"EntryLo1: expected 00000D06, got %08h", dut.EntryLo1_out);

        $display("PASS! TLBWI/TLBR readback at index %0d", Index_in);
        $finish;
    end
    
    
endmodule
