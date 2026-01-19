`timescale 1ns / 1ps

module risc_mem_access_aligner(

    input logic [31:0] alu_result_address,
    input logic [2:0] f3,
    input logic [31:0] reg_read,
    
    //out
    output logic [3:0] byte_enable,
    output logic [31:0] data

    );
    
    logic [1:0] offset;
    
    // before cutting off the last two, we stored them to determine the lanes ex. if half, cut off 10 = first 4 upper bit of hex
    assign offset = alu_result_address[1:0]; // last two because we stored in word so /4
    
    
    // get the lowest byte and shift them based on input AABBCCDD -> 0000DD00 if f3 = byte and offset 01
    always_comb begin
        case (f3)
        //word
            3'b010 : begin
                byte_enable = (offset == 2'b00) ? 4'b1111 : 4'b0000;
                data = reg_read;
            end
          //Halfword
            3'b001, 3'b101: begin
                case (offset) // check for byte lane or offset. valid only for even numbers
                    2'b00: begin
                        byte_enable = 4'b0011;
                        data = (reg_read & 32'h0000FFFF);
                        
                    end
                    
                    2'b10: begin
                        byte_enable = 4'b1100;
                        data = (reg_read & 32'h0000FFFF) << 16;
                        
                    end
                
                    default : byte_enable = 4'b0000;
                endcase

            end
             
          //byte
            3'b000, 3'b100: begin
            
                case (offset)
                    2'b00: begin
                        byte_enable = 4'b0001;
                        data = (reg_read & 32'h000000FF);
                    end
                    
                    2'b01: begin
                        byte_enable = 4'b0010;
                        data = (reg_read & 32'h000000FF) << 8;
                    end
                    
                    2'b10: begin
                        byte_enable = 4'b0100;
                        data = (reg_read & 32'h000000FF) << 16;
                    end
                    
                    2'b11: begin
                        byte_enable = 4'b1000;
                        data = (reg_read & 32'h000000FF) << 24;
                    end
                    default: byte_enable = 4'b0000;
                endcase
              
            end
            
            default: byte_enable =4'b0000;
        
        endcase
   
    end
    
    
endmodule;
