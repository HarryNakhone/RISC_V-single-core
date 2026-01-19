`timescale 1ns / 1ps

//reader look at f3 to know if it is byte, halfwaord or word
// only useful for load/return values back to the regfile
module risc_load_data_extractor(
    input logic [31:0] mem_data,
    input logic [3:0] be_mask,
    input logic [2:0] f3,
    
    output logic [31:0] wb_data,
    output logic valid

    );
    
    
    logic sign_extend;
    assign sign_extend = ~f3[2];
    
    
    logic [31:0] masked_data;
    logic [31:0] raw_data;
        
    always_comb begin : mask_apply   //DDCC1144  be_mask =  0010
        for (int i = 0; i < 4; i ++) begin
            if (be_mask[i]) begin
            
                masked_data[(i*8)+:8] = mem_data[(i*8)+:8];  /// 00001100
            end else begin
                masked_data[(i*8)+:8] = 8'b00000000;
                
            end 
        end
    end
    
    always_comb begin : shift_data
        case (f3)   // 000
          //Word
            3'b010: raw_data = masked_data;
            
          //Halfword / HW unsigned
            3'b001, 3'b101: begin
                case(be_mask) 
                    4'b0011: raw_data = masked_data;
                    4'b1100: raw_data = masked_data >> 16;
                    default: raw_data = 32'b0;
                    
                endcase
            end
            
          // Byte / Byte-unsigned
            3'b000, 3'b100: begin
                case(be_mask)
                    4'b0001: raw_data = masked_data;
                    4'b0010: raw_data = masked_data >>8;  ///00000011
                    4'b0100: raw_data = masked_data >> 16;
                    4'b1000: raw_data = masked_data >> 24;
                    
                    default: raw_data = 32'b0;
                endcase
            end
            
            default: raw_data = 32'b0;
        
        endcase
    end
    
    always_comb begin: sign_extend_logic   // unsigned doesnt need to extend onyl for signed
    
        case (f3)
            3'b010: wb_data = raw_data;
            
             3'b001, 3'b101: wb_data = sign_extend ? {{16{raw_data[15]}}, raw_data[15:0]} : raw_data;
             
             3'b000, 3'b100: wb_data = sign_extend ? {{24{raw_data[7]}}, raw_data[7:0]} : raw_data;
             
             default: wb_data = 32'd0;
        endcase
        
        
        valid = |be_mask; // if it is masked then 1
    end
endmodule;
