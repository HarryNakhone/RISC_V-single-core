`timescale 1ns / 1ps



module rsc_ctrl(

    input logic [6:0] op,
    input logic [2:0] f3,
    input logic [6:0] f7,
    input logic alu_zero,
    input logic alu_last_bit,
    
    
    output logic [3:0] alu_ctrl, // tell the ALU which operation to operform on operA and operB
    output logic [2:0] imm_source,  // tell the imm generator which type of instruction I or S etc..
    output logic mem_write,
    output logic reg_write, 
    
    //newly added
    output logic alu_source, // selector for choosing immediate or read_reg2 to be OperB for ALU
    output logic [1:0] write_back_source, // which source to use for writing register next clk rise
    output logic pc_source,   //   pc +4 or pc + something
    output logic [1:0] second_add_source  // what to add to pc ex. imm or pc to be imm
    );
    
    logic [1:0] alu_op;
    logic branch;
    logic jump;
    
    /// what kind of instruction 
    always_comb begin
        case (op)
            7'b0000011 : begin   //I-type
                reg_write = 1'b1;
                imm_source = 3'b000;
                mem_write = 1'b0;
                alu_op = 2'b00;
                alu_source = 1'b1;
                write_back_source = 2'b01; 
                branch = 1'b0;
                jump = 1'b0;
            end
            
            7'b0010011 : begin  //ALU I-type
              
                imm_source = 3'b000;
                mem_write = 1'b0;
                alu_op = 2'b10;
                alu_source = 1'b1;
                write_back_source = 2'b00; 
                branch = 1'b0;
                jump = 1'b0;
                           //f3_sll
                if (f3 == 3'b001) begin
                    reg_write = 1'b1;
                end 
                                //f3_srl_sra
                else if (f3 == 3'b101) begin
                    reg_write = (f7 == 7'b0000000 | f7 == 7'b0100000) ? 1'b1 : 1'b0;
                end else begin        //f7_sll_srl         f7_sra
                
                    reg_write = 1'b1;
                end
            
            end
            
            7'b0100011 : begin  ///S-type
                reg_write = 1'b0;
                imm_source = 3'b001;
                mem_write = 1'b1;
                alu_op = 2'b00;
                alu_source = 1'b1;
                branch = 1'b0;
                jump = 1'b0;
            
            end
            
            7'b0110011 : begin   //R-type
                reg_write = 1'b1;
                mem_write = 1'b0;
                alu_op = 2'b10;
                alu_source = 1'b0;  //reg2
                write_back_source = 2'b00;
                branch = 1'b0;
                jump = 1'b0;
            
            end
            
            7'b1100011 : begin  /// B-type
                reg_write = 1'b0;
                mem_write = 1'b0;
                alu_op = 2'b01;
                alu_source = 1'b0;
                imm_source = 3'b010;
                branch = 1'b1;
                jump = 1'b0;
                second_add_source = 2'b00;
               
            end
            
            7'b0110111, 7'b0010111 : begin  ///U-type
                reg_write = 1'b1;
                mem_write = 1'b0;
        
                alu_source = 1'b0;
                imm_source = 3'b100;
                branch = 1'b0;
                jump = 1'b0;
                
                write_back_source = 2'b11;
                
                case (op[5]) 
                    1'b1: second_add_source = 2'b01; //lui
                    1'b0: second_add_source = 2'b00; //auipc
                
                endcase
                    
                
                end
            
            7'b1101111, 7'b1100111 : begin   ///J-type and JARL
                reg_write = 1'b1;
                mem_write = 1'b0;
       
                imm_source = 3'b011;
                branch = 1'b0;
                jump = 1'b1;
                
                write_back_source = 2'b10;
                
                if (op[3]) begin   //jal
                    second_add_source = 2'b00; // for next pc instruction\pc+immediate ex
                    imm_source = 3'b011; 
                end else if (~op[3]) begin // jalr
                    second_add_source = 2'b10;
                    imm_source = 3'b000;
                end
            
            end
            
            default: begin
                reg_write = 1'b0;
                mem_write = 1'b0;
                jump = 1'b0;
                branch = 1'b0;
                
                $display("weird ass op code");
                
                
            end
        
        endcase
    end
    
    
    //Alu decodeer
    always_comb begin
    
        case(alu_op)
        // LW, SW address calculation
            2'b00 : alu_ctrl = 4'b0000; //ADD
            //R and I type check f3 and f7
            2'b10 : begin
                case (f3) 
                
                    3'b000 : begin // ADD and SUB
                        if (op == 7'b0110011) begin //R type   
                                              //f7_sub      
                            alu_ctrl = (f7 == 7'b0100000)? 4'b0001 : 4'b0000;  // alu_sub and alu_add
                         end else begin                     
                            alu_ctrl =  4'b0000;//add
                         end
                    end
                    //and both
                    3'b111 : alu_ctrl = 4'b0000;
                    //or
                    3'b110 : alu_ctrl = 4'b0011;
                    //slt
                    3'b010 : alu_ctrl = 4'b0101;
                    //sltu
                    3'b011 : alu_ctrl = 4'b0111;
                    //xor
                    3'b100 : alu_ctrl = 4'b1000;
                    //sll
                    3'b001 : alu_ctrl = 4'b0100; 
                    //srl, sra
                    3'b101 : begin
                        if (f7 == 7'b0000000) begin
                            alu_ctrl = 4'b0110;
                        end else if (f7 == 7'b0100000) begin // f7_sra
                        
                            alu_ctrl = 4'b1001;
                        end
                    end
                
                
                   
                endcase
            
            end
            
            2'b01: begin  //ALU branch
                case(f3)
                    //beq   bne
                    3'b000, 3'b001 : alu_ctrl = 4'b0001;
                    //blt  bge
                    3'b100, 3'b101 : alu_ctrl = 4'b0101;
            
                    //bltu   bgeu
                    3'b110, 3'b111 : alu_ctrl = 4'b0111;
                    default : alu_ctrl = 4'b1111;
                endcase
            end
            
            default: alu_ctrl = 4'b1111;
        endcase
    end
    
    
    
    
    //// should PC take the branch target or jump
    logic assert_branch;
    
    always_comb begin: branch_logic_decode
        case (f3)
            //beq
            3'b000 : assert_branch = alu_zero & branch;  
            //blt and bltu
            3'b100, 3'b110 : assert_branch = alu_last_bit & branch;  
             //bne
            3'b001 : assert_branch = ~alu_zero & branch;  
             //bge and bgeu
            3'b101, 3'b111: assert_branch = ~alu_last_bit & branch;   
            
        
            default: assert_branch = 1'b0;
        endcase
        
    end
    
    
    assign pc_source = assert_branch | jump;
endmodule
