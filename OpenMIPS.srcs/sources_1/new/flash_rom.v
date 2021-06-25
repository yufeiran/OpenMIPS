`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/03/05 16:49:58
// Design Name: 
// Module Name: flash_rom
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

// main two part: 1.spi flash control 2. wb main bus
module flash_rom(
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wb_cyc_i,
    input wire wb_stb_i,
    input wire wb_we_i,
    input wire [3:0] wb_sel_i,
    input wire [23:0] wb_adr_i,
    input wire [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    output reg        wb_ack_o,
    
    input wire flash_continue,
    
    output reg cs_n,
    input  sdi,
    output reg sdo,
    output reg wp_n,
    output reg hld_n
    );



parameter IDLE       = 5'b00000;
parameter START      = 5'b00010;
parameter INST_OUT   = 5'b00011;
parameter ADDR1_OUT  = 5'b00100;
parameter ADDR2_OUT  = 5'b00101;
parameter ADDR3_OUT  = 5'b00110;
parameter WRITE_DATA = 5'b00111;
parameter READ_DATA  = 5'b01000;
parameter READ_DATA1=5'b01001;
parameter READ_DATA2=5'b01010;
parameter READ_DATA3=5'b01011;
parameter READ_DATA4=5'b01100;
parameter READ_DATA5=5'b01101;
parameter WAITING   =5'b10000;
parameter ENDING   = 5'b10001;

(* dont_touch = "true" *)reg[4:0] init_count;

(* dont_touch = "true" *)reg         sck;
(* dont_touch = "true" *)reg  [4:0]  state;
reg  [4:0]  next_state;

(* dont_touch = "true" *)reg  [7:0]   instruction;
(* dont_touch = "true" *)reg  [7:0]   datain_shift;
(* dont_touch = "true" *)reg  [7:0]   datain;
(* dont_touch = "true" *)reg  [7:0]  dataout;
(* dont_touch = "true" *)reg         sck_en;
(* dont_touch = "true" *)reg  [2:0]  sck_en_d;
(* dont_touch = "true" *)reg [10:0] read_count;
reg  [2:0]  cs_n_d;

reg         temp;
(* dont_touch = "true" *)reg  [3:0]  sdo_count;
reg  [15:0] page_count;
reg  [7:0]  wait_count;
(* dont_touch = "true" *)reg  [23:0] addr;
reg         wrh_rdl;  // High indicates write, low indicates read
reg         addr_req;  // Address writing requested
reg  [15:0] wr_cnt;  // Number of bytes to be written
reg  [15:0] rd_cnt;  // Number of bytes to be read
(* dont_touch = "true" *)reg [31:0] read_data;



// State machine
always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if(wb_rst_i) begin
		state <= IDLE;
		read_count<=11'd0;
		wb_ack_o<=1'b0;
	    init_count<=5'd2;
	end
	else if(wb_cyc_i&wb_stb_i) begin
		state <= next_state;
		if(state==ENDING&&!wb_ack_o)
		begin
		  if(init_count>5'd0)
		  begin
		      init_count<=init_count-5'd1;
		      state<=IDLE;
		  end
		  else 
		  begin
		      wb_ack_o<=1'b1;
		  end
		end
	end
	else begin
	   state<=IDLE;
	   wb_ack_o<=1'b0;
	end
end

always@(posedge wb_clk_i)
begin
    //wb_dat_o<=read_data;
    wp_n<= 1'b1;
    hld_n <= 1'b1;
end

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if(wb_rst_i) begin
		next_state  <= IDLE;
		sck_en      <= 1'b0;
		cs_n_d[0]   <= 1'b1;
		dataout     <= 8'd0;
		sdo_count   <= 4'd0;
		sdo         <= 1'b0;
		datain      <= 8'd0;
		addr        <=24'd0;
		datain_shift<=8'd0;
       
        temp        <= 1'b0;
        page_count  <= 16'd0;
        wait_count  <= 8'd0;
        read_data   <=32'd0;
        
	end
	else begin
		case(state)
		IDLE: 
		begin	// IDLE state
            wait_count <= 8'd0;
            if(flash_continue==1'd1)
            begin
              // for real board debug
		      next_state<=START;
		    end
		    // for sim or final
		    //next_state<=START;  
		   
		end
		
		START:
		begin	// enable SCK and CS
		    addr<=wb_adr_i;
		    //addr<=24'd0;
			sck_en <= 1'b1;
			cs_n_d[0]  <= 1'b0;
			next_state <= INST_OUT;
			read_count<=read_count+11'd1;
		end
		INST_OUT:
		begin	// send out instruction
			if(sdo_count == 4'd1) begin
				{sdo, dataout[6:0]} <= instruction;
			end
			else if(sdo_count[0]) begin
				{sdo, dataout[6:0]} <= {dataout[6:0],1'b0};
			end
			
			if(sdo_count != 4'd15) begin
				sdo_count <= sdo_count + 4'd1;
			end
			else begin
				sdo_count  <= 4'd0;
				next_state <= (addr_req) ?  ADDR1_OUT : ((wrh_rdl) ? ((wr_cnt==16'd0) ? ENDING : WRITE_DATA) : ((rd_cnt==16'd0) ? ENDING : READ_DATA1));
			end
		end
		ADDR1_OUT:
		begin	// send out address[23:16]
			if(sdo_count == 4'd1) begin
				{sdo, dataout[6:0]} <= addr[23:16];
			end
			else if(sdo_count[0]) begin
				{sdo, dataout[6:0]} <= {dataout[6:0],1'b0};
			end
			
			if(sdo_count != 4'd15) begin
				sdo_count <= sdo_count + 4'd1;
			end
			else begin
				sdo_count  <= 4'd0;
				next_state <= ADDR2_OUT;
			end
		end
		ADDR2_OUT:
		begin	// send out address[15:8]
			if(sdo_count == 4'd1) begin
				{sdo, dataout[6:0]} <= addr[15:8];
			end
			else if(sdo_count[0]) begin
				{sdo, dataout[6:0]} <= {dataout[6:0],1'b0};
			end
			
			if(sdo_count != 4'd15) begin
				sdo_count <= sdo_count + 4'd1;
			end
			else begin
				sdo_count  <= 4'd0;
				next_state <= ADDR3_OUT;
			end
		end
		ADDR3_OUT:
		begin	// send out address[7:0]
			if(sdo_count == 4'd1) begin
				{sdo, dataout[6:0]} <= addr[7:0];
			end
			else if(sdo_count[0]) begin
				{sdo, dataout[6:0]} <= {dataout[6:0],1'b0};
			end
			
			if(sdo_count != 4'd15) begin
				sdo_count <= sdo_count + 4'd1;
			end
			else begin
				sdo_count  <= 4'd0;
				next_state <= (wrh_rdl) ? ((wr_cnt==16'd0) ? ENDING : WRITE_DATA) : ((rd_cnt==16'd0) ? ENDING : READ_DATA1);
                page_count <= 16'd0;
			end
		end
		WRITE_DATA:
		begin	// send testing data out to flash
			if(sdo_count == 4'd1) begin
				{sdo, dataout[6:0]} <= 8'h5A;
			end
			else if(sdo_count[0]) begin
				{sdo, dataout[6:0]} <= {dataout[6:0],1'b0};
			end
			
			if(sdo_count != 4'd15) begin
				sdo_count <= sdo_count + 4'd1;
			end
			else begin
                page_count <= page_count + 16'd1;
				sdo_count  <= 4'd0;
				next_state <= (page_count < (wr_cnt-16'd1)) ? WRITE_DATA : ENDING;
			end
		end
		READ_DATA1:
		begin	// get the first data from flash
            if(~sdo_count[0]) begin
                datain_shift <= {datain_shift[6:0],sdi};
            end
            
            if(sdo_count == 4'd1) begin
                 datain<= {datain_shift, sdi};
            end
            
			if(sdo_count != 4'd15) begin
				sdo_count <= sdo_count + 4'd1;
			end
			else begin
                page_count <= page_count + 16'd1;
				sdo_count  <= 4'd0;
				next_state <=READ_DATA2;
			end
		end
		READ_DATA2:
		begin	// get the first data from flash
            if(~sdo_count[0]) begin
                datain_shift <= {datain_shift[6:0],sdi};
            end
            
            if(sdo_count == 4'd1) begin
                read_data[31:24] <= {datain_shift, sdi};
                datain<= {datain_shift, sdi};
            end
            
			if(sdo_count != 4'd15) begin
				sdo_count <= sdo_count + 4'd1;
			end
			else begin
                page_count <= page_count + 16'd1;
				sdo_count  <= 4'd0;
				next_state <=READ_DATA3;
			end
		end
		READ_DATA3:
		begin	// get the first data from flash
            if(~sdo_count[0]) begin
                datain_shift <= {datain_shift[6:0],sdi};
            end
            
            if(sdo_count == 4'd1) begin
                read_data[23:16] <= {datain_shift, sdi};
                 datain<= {datain_shift, sdi};
            end
            
			if(sdo_count != 4'd15) begin
				sdo_count <= sdo_count + 4'd1;
			end
			else begin
                page_count <= page_count + 16'd1;
				sdo_count  <= 4'd0;
				next_state <=READ_DATA4;
			end
		end
		READ_DATA4:
		begin	// get the first data from flash
            if(~sdo_count[0]) begin
                datain_shift <= {datain_shift[6:0],sdi};
            end
            
            if(sdo_count == 4'd1) begin
                read_data[15:8] <= {datain_shift, sdi};
                 datain<= {datain_shift, sdi};
            end
            
			if(sdo_count != 4'd15) begin
				sdo_count <= sdo_count + 4'd1;
			end
			else begin
                page_count <= page_count + 16'd1;
				sdo_count  <= 4'd0;
				next_state <=READ_DATA5;
			end
		end
		READ_DATA5:
		begin	// get the first data from flash
            if(~sdo_count[0]) begin
                datain_shift <= {datain_shift[6:0],sdi};
            end
            
            if(sdo_count == 4'd1) begin
                read_data[7:0] <= {datain_shift, sdi};
                 datain<= {datain_shift, sdi};
            end
            
			if(sdo_count != 4'd15) begin
				sdo_count <= sdo_count + 4'd1;
			end
			else begin
                page_count <= page_count + 16'd1;
				sdo_count  <= 4'd0;

				next_state <=WAITING;
			end
		end
		WAITING:
		begin  //disable SCK and CS, wait for 32 clock cycles
		    sck_en <= 1'b0;
            cs_n_d[0] <= 1'b1;
            sdo_count <= 4'd0;

		    next_state<=ENDING;

		end
		ENDING:
		begin	
            
		end
		endcase
	end
end
// SCK generator, 50MHz output
always @(posedge wb_clk_i) begin
    sck_en_d <= {sck_en_d[1:0],sck_en};
end

always @(posedge wb_clk_i or posedge wb_rst_i) begin
	if(wb_rst_i) begin
		sck <= 1'b0;
	end
	else if(sck_en_d[2] & sck_en) begin
		sck <= ~sck;
	end
    else begin
        sck <= 1'b0;
    end
end

always @(posedge wb_clk_i or posedge wb_rst_i) begin
    if(wb_rst_i) begin
        {cs_n,cs_n_d[2:1]} <= 3'h7;
    end
    else begin
        {cs_n,cs_n_d[2:1]} <= cs_n_d;
    end
end

STARTUPE2
#(
.PROG_USR("FALSE"),
.SIM_CCLK_FREQ(10.0)
)
STARTUPE2_inst
(
  .CFGCLK     (),
  .CFGMCLK    (),
  .EOS        (),
  .PREQ       (),
  .CLK        (1'b0),
  .GSR        (1'b0),
  .GTS        (1'b0),
  .KEYCLEARB  (1'b0),
  .PACK       (1'b0),
  .USRCCLKO   (sck),      // First three cycles after config ignored, see AR# 52626
  .USRCCLKTS  (1'b0),     // 0 to enable CCLK output
  .USRDONEO   (1'b1),     // Shouldn't matter if tristate is high, but generates a warning if tied low.
  .USRDONETS  (1'b1)      // 1 to tristate DONE output
);
// ROM for instructions
always @(posedge wb_clk_i) begin
    instruction <= 8'h03; wrh_rdl <= 1'b0; addr_req <= 1'b1; 
     wr_cnt <= 16'd0; rd_cnt <= 16'd4;   // READ
    
end
 wire [31:0] wb_dat_o_w;
     always@(posedge wb_clk_i)
    begin
        // for real borad
        wb_dat_o<=read_data;
        // for simulate 
        //wb_dat_o<=wb_dat_o_w;
    end
 
  wire [14:0]addr_rom={2'b00,wb_adr_i[14:2]};
  rom0 rom0(.addra(addr_rom),.clka(wb_clk_i),.douta(wb_dat_o_w),.ena(1'b1));
    
endmodule
