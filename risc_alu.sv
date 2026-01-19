`timescale 1ns / 1ps


module risc_alu(

input logic [31:0]OperA,
input logic [31:0]OperB,
input logic [3:0] Alu_ctrl,

output logic [31:0] alu_out,
output logic zero,
output logic last_bit
);
    
wire [4:0] shift_amount = OperB[4:0]; // RV32 uses only 5lower bit for shifting

    always_comb begin
    
       case(Alu_ctrl) 
            4'b0000: alu_out = OperA + OperB;  //ADD
            
            4'b0010: alu_out = OperA & OperB;  //AND
            
            4'b0011: alu_out = OperA | OperB;  //OR
            
            4'b0001: alu_out = OperA + (~OperB + 1'b1); //SUB
            
           4'b0101: alu_out = {31'b0, $signed(OperA) < $signed(OperB)};  //less than
            
           4'b0111: alu_out = {31'b0, OperA < OperB};   //less than unsigned
            
            4'b1000:alu_out = OperA ^ OperB;  //XOR
            
            4'b0100: alu_out = OperA << shift_amount;   //SLL ex. 0010 << 2 = 1000
            
            4'b0110: alu_out = OperA >> shift_amount;  //SRL
             
            4'b1001: alu_out = $signed(OperA) >>> shift_amount;  //SRA
             
            // here
            default: alu_out = 32'b0;
       endcase
    end
    
assign zero = alu_out == 32'b0;
assign last_bit = alu_out[0];
endmodule
