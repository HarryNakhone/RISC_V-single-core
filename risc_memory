`timescale 1ns / 1ps


module risc_memory #(
    parameter WORDS = 128,
    parameter mem_init = ""
   )(
        input logic clk,
        input logic rset_lg,
        input logic WE,
        input logic [3:0] BE,
        input logic [31: 0] addr,
        input logic [31: 0] WD,
        output logic [31:0] RD
    
   );
   
   reg [31:0] mem [0:WORDS-1];  //  each element is reg 32 bit 
   
   initial begin
        if (mem_init != "" )  $readmemh(mem_init, mem);
   end
   
   always @(posedge clk) begin
   
        if (rset_lg == 1'b0) begin
            for (int i = 0; i < WORDS; i++) begin
                mem[i] <= 32'd0;
            end
           
        end
        
        else begin
        
            if (WE) begin
                if (addr[1:0] != 2'b00) begin  //check for word align
                
                    $display("Misaligned write at address %h", addr);
                end else begin
                
                    for (int i = 0; i < 4; i++) begin
                        if (BE[i]) begin
                        mem[addr[31:2]][(i*8)+:8] <= WD[(i*8)+:8];   // drop last 2 bit is the same as divide by 4
                        //because we are accessing the word in memory we have to addr[i]/4 
                        end
                    end
                end
            
            end
       
        end 
       
    end
    
    always_comb begin
        RD = mem[addr[31:2]];

    end
endmodule
