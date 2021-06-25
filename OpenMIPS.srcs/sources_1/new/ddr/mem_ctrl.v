`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2015 07:20:54 PM
// Design Name: 
// Module Name: mem_ctrl
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


module mem_ctrl(

    input clk_100MHz,
    input rst,
    
    
    input  playing,
    
    input recording,
    
    
    output reg delete_clear,
    
    output reg RamCEn,
    output reg RamOEn,
    output reg RamWEn,
    output reg write_zero,
    output reg get_data,
    output reg data_ready,
    output reg mix_data
    

);    
    
    initial delete_clear = 0;
    initial write_zero = 0;    
    initial get_data = 0;  
    initial data_ready = 0;
    initial mix_data=0;
    
    //State machine states
    parameter BANK = 4'b0000;
    parameter FLAG = 4'b0010;
    parameter BANK_ACK = 4'b0001;
    parameter INC_BLOCK = 4'b0011;
    parameter WAIT = 4'b0111;
    parameter DELETE = 4'b0100;
    parameter DELETE_ACK = 4'b0101;
    parameter DELETE_INC = 4'b0110;
    parameter ONECYCLE = 4'b1000;
    parameter ENTERDELETE = 4'b1010;
    parameter LEAVEDELETE = 4'b1001;
    
    parameter MHz44cnt = 2268;
//parameter MHz44cnt = 200;
    wire address_enable;
    assign address_enable = playing || recording;
    reg [12:0] count=0;
    
    (* Mark_debug = "TRUE" *) reg [4:0]pstate = WAIT;
    reg [3:0] nstate = BANK;
    reg delay_done = 0;
    reg counterEnable=0;
    reg increment=0;
    reg pulse=0;
    integer counter = 0;
    reg [22:0] max_delete_block=0;
    reg [22:0] delete_address=0;
    reg WEn_d1=1;
       //Generates a 44.1Khz pulse
always @ (posedge(clk_100MHz))begin
    if(rst == 1)begin
        count <= 0;
        pulse <= 0;
    end
    else if( count < MHz44cnt)begin
        count <= count + 1;
        pulse <= 0;
    end
    else begin //count is at max, triggers every 44.1KHz
        pulse <= 1; //trigger pulse
        count <= 0;//reset count
    end      
end
    
    
always @(posedge(clk_100MHz))begin
    RamWEn<=WEn_d1;
end
    
    
always @ (posedge clk_100MHz)
begin
    if (rst == 1)begin
        pstate <= WAIT;
        counterEnable <= 0;
        write_zero <= 0;
        get_data<=0;
        data_ready<=0;
        end
    else begin
    if (pulse==1)nstate<=LEAVEDELETE;
    case (pstate)
    /////////////////////////BANK 0
        BANK : begin
            nstate <= BANK;  
            if(recording == 1)begin
                get_data <= 1;
                counterEnable <= 1;
                RamCEn<=0;
                RamOEn<=1;
                WEn_d1<=0;
                pstate<=BANK_ACK;
            end
            else if(playing == 1)begin
                get_data<=0;
                RamCEn <= 0;
                RamOEn <= 0;
                WEn_d1 <= 1;
                counterEnable <= 1;
                pstate<=BANK_ACK;
            end
            else begin
                get_data<=0;
                RamCEn <= 1;
                RamOEn <= 1;
                WEn_d1 <= 1;
                data_ready <= 1;
                pstate <= FLAG;
            end            
        end
        
        FLAG : begin
            data_ready <= 0;
            pstate <= nstate;
        end
        
        BANK_ACK : begin
            get_data<=0;//Turn off get_data pulse
            if (counter==55)begin //At 55 clock cycles, send data_ready pulse, turn off memory signals
                data_ready<=1;
                RamCEn<=1;
                RamOEn<=1;
                WEn_d1<=1;
            end
            else data_ready<=0;//data_ready pulse stays low
            if(delay_done == 1)begin//Delay is done, go to next bank
                pstate <= nstate;
                counterEnable <= 0;
             end
        end
        
        INC_BLOCK: begin
            increment <= 1;
            mix_data<=1;
            nstate <= WAIT;
            pstate <= WAIT;
        end
        
    /////////////////////////Wait
        WAIT: begin
            mix_data <= 0;
            increment <= 0;//Stop incrementing addrblock44khz
            if(pulse == 1)begin
                pstate <= BANK;
            end
            else 
                pstate <= WAIT;
            end
    /////////////////////////Delete Loop
        ENTERDELETE: begin

            nstate<=DELETE;
            write_zero <= 1;    //Write a 0 to erase data from memory
            pstate<=DELETE;
        end
        DELETE : begin
            RamCEn <= 0;
            RamOEn <= 1;
            WEn_d1 <= 0; 
            counterEnable <= 1;
            pstate <= DELETE_ACK;
        end
             
        DELETE_ACK : begin
            if(delay_done == 1)begin
                pstate <= DELETE_INC;
                RamCEn <= 1;
                RamOEn <= 1;
                WEn_d1 <= 1;
                counterEnable <= 0;
            end
        end 
         
        DELETE_INC : begin
            if(delete_address < max_delete_block)begin//Not done erasing
                delete_address<=delete_address+1;
                pstate <= nstate;//Will either go to DELETE, or will go to LEAVEDELETE if a pulse was triggered during erasing
            end
            else begin//Done erasing! 
                delete_clear <= 1; //Flag to clear the delete signal
                delete_address<=0;
                write_zero<=0;
                max_delete_block<=0; 
                pstate <= ONECYCLE;  
            end  
        end 
                     
        ONECYCLE: begin //To kill the delete_clear pulse
           delete_clear<=0;
           pstate <=WAIT;
        end
        
        LEAVEDELETE: begin
            write_zero<=0;
            counterEnable<=1;
            if(delay_done==1)begin
                counterEnable<=0;
                pstate<=BANK;
            end
        end
    endcase 
     
   end //end resetn
end         
 
 
 
 //delay
 

 

 
 always @(posedge clk_100MHz)begin
    if(counterEnable==0)begin
        counter <= 0;
        delay_done <= 0;
    end
    
    else if(counter < 60) begin
        counter <= counter + 1;
        delay_done <= 0;
    end
    
    else begin
        counter <= 0;
        delay_done <= 1;
    end
   end     
   
    
endmodule
