`timescale 1ns / 1ps

module risc_register_file(

input logic clk,

input logic WE,
input logic [31:0] WD,
input logic [4:0] addr3,

//addresses
input logic [4:0] addr1,
input logic [4:0] addr2,


// out to alu (wire)
output logic [31:0] RD1,
output logic [31:0] RD2,


input logic rset_lg //reset

    );
    
    reg [31:0] registers [0:31];
    logic g;
    
    initial g = 1'b0;
    
    always @(posedge clk)begin
    
        if (rset_lg == 1'b0) begin
            
        
            for (int k= 0; k< 32; k++)begin
                registers[k] <= 32'b0;
            end
        end
        
        else if (WE & addr3 != 0) begin 
                g <= ~g;
                registers[addr3] <= WD;
        end
    end
    
    
    always_comb begin
        RD1 = registers[addr1];
        RD2 = registers[addr2];
        
    end
    
endmodule
