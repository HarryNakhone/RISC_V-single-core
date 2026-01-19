`timescale 1ns / 1ps

module risc_cpu(
    input logic clk,
    input logic rset_lg
   
    );
    
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] pc_plus_second_add;
    
    logic [31:0] pc_plus_four;
    
    assign pc_plus_four = pc + 4;
    
     always_comb begin
        case (second_add_source)
            2'b00: pc_plus_second_add = pc + immediate;  // branches
            2'b01: pc_plus_second_add = immediate; //use absolute immediate lui for example
            2'b10: pc_plus_second_add = read_reg1 + immediate;  // jalr  / rs1 + immediate
            default: pc_plus_second_add = 32'd0;
        endcase
    
    end
    
    
    always_comb begin  // pick next pc 
        case (pc_source)
            1'b0: pc_next =  pc_plus_four;   // normal pc + 4
            1'b1: pc_next = pc_plus_second_add;  // or branch/jumo
        endcase
    end
    
   
    always @(posedge clk) begin  /// if no reset then get new pc+4
        if(rset_lg == 0) begin
            pc <= 32'b0;
        end else begin
            pc <= pc_next;
        end
    end

  
    
  
/*****
 /// Instruction memory
 *****/
    
    wire [31:0] instruction;
    
    risc_memory #(
        .mem_init("instr_mem.mem")
    ) instruction_memory (
    .clk(clk),
    .rset_lg(1'b1),  
    .WE(1'b0),   /// no write enable or write data, only read pc and load the read data stores them in "instruction"
    .BE(4'b0000),
    .addr(pc),   
    .WD(32'b0),
    .RD(instruction)  // instruction = mem[pc]
    );

// control section    
  logic [6:0] op;  
  logic [2:0] f3;
  logic [6:0] f7;
  
  assign op = instruction[6:0];
  assign f3 = instruction[14:12];
  assign f7 = instruction[31:25];

  wire alu_zero;
  wire alu_last_bit;
  wire [3:0] alu_ctrl;
  wire [2:0] immediate_sr;
  
  wire mem_write;
  wire reg_write;
  wire alu_source;
  wire [1:0] write_back_source;
  wire pc_source;
  wire [1:0] second_add_source;
  
  
 
                          
    risc_alu_ctrl ctrl_unit(
        //in
        .op(op),
        .f3(f3),
        .f7(f7),
        .alu_zero(alu_zero),
        .alu_last_bit(alu_last_bit),
        
        //out
        
        .alu_ctrl(alu_ctrl),
        .imm_source(immediate_sr),
        .mem_write(mem_write),
        .reg_write(reg_write),
        
        .alu_source(alu_source),
        .write_back_source(write_back_source),
        .pc_source(pc_source),
        .second_add_source(second_add_source)
        
    );
    
    

/*****
 /// REG FILE
 *****/
 
// source 1 and 2
 logic [4:0] sr1;
 assign sr1 = instruction[19:15];
 logic [4:0] sr2;
 assign sr2 = instruction[24:20];
 
 
 logic [4:0] dst_reg;
 assign dst_reg = instruction[11:7];
 
 wire [31:0] read_reg1;
 wire [31:0] read_reg2;
 
 logic wb_valid;
 
 logic [31:0] write_back_data;
 
 // from data mem to the reg file
always_comb begin
    case(write_back_source)
        2'b00: begin  
            write_back_data = alu_result;
            wb_valid = 1'b1;
        
        end
        
         2'b01: begin // load
            write_back_data = mem_rwback_data;
            wb_valid = mem_rwback_valid;
        
        end
        
         2'b10: begin  // Jump
            write_back_data = pc_plus_four;
            wb_valid = 1'b1;
        
        end
        
         2'b11: begin
            write_back_data = pc_plus_second_add;
            wb_valid = 1'b1;
        
        end
    endcase
end
 
 
 risc_register_file regfile(
    .clk(clk),
    //from CTRL
    .WE(reg_write & wb_valid),
    .WD(write_back_data),
    
     //input from instruction
    .addr3(dst_reg),    
    
   
    .addr1(sr1),
    .addr2(sr2),
    
    //out to ALU
    .RD1(read_reg1),     /// value register addr sr1
    .RD2(read_reg2),      /// value register addr sr2
    .rset_lg(rset_lg)
);

 
 
/*****
 ///  SIGN EXTENDER
 *****/ 
 
 
 
 logic [24:0] raw_immediate;
 assign  raw_immediate = instruction[31:7];
 // to ALU
 wire [31:0] immediate;
 
 risc_imm_generator sign_extder(
    .raw_src(raw_immediate),
    .imm_source(immediate_sr), // from ctrl unit to construct immediate for each type
    .immediate(immediate)
    
 );
 

/*****
 /// ALU 
 *****/
 
 
 
 wire [31:0] alu_result;
 logic [31:0] alu_src2;
 
 // perform with r2 or immediate
 always_comb begin: srcBSelect
    case (alu_source)
        1'b1: alu_src2 = immediate;
        default: alu_src2 = read_reg2;
    endcase
end

risc_alu alu_func(
    .OperA(read_reg1),  // here
    .OperB(alu_src2),
    .Alu_ctrl(alu_ctrl),
    .alu_out(alu_result),
    .zero(alu_zero),
    .last_bit(alu_last_bit)
);


/*****
 ///   LOAD STORE DECODER
 *****/

wire [3:0] mem_byte_enable;
wire [31:0] mem_write_data;

mem_access_aligner decoder(
    .alu_result_address(alu_result),
    .reg_read(read_reg2),
    .f3(f3),
    
    .byte_enable(mem_byte_enable),
    .data(mem_write_data)
);



/*****
 /// DATA MEMORY
 *****/


wire [31:0] mem_read;

risc_memory #(
    .mem_init("data_mem.mem")
)data_memory(

    .clk(clk),
    .rset_lg(rset_lg), // 
    .WE(mem_write),  /// 
    .BE(mem_byte_enable),
    .addr({alu_result[31:2], 2'b00}),
    .WD(mem_write_data), // 0'b0
    
    //out to reader 
    .RD(mem_read)
);




/*****
 /// READER
 *****/



wire [31:0] mem_rwback_data;
wire mem_rwback_valid;

load_data_extractor reader_func(
    .mem_data(mem_read),
    .be_mask(mem_byte_enable),
    .f3(f3),
    .wb_data(mem_rwback_data),
    .valid(mem_rwback_valid)
);
 
endmodule
