// Computer Architecture (CO224) - Lab 05
// Design: Integrated CPU of Simple Processor
// Author: Shanaka T.K.M.
// Reg_No: E/16/351

`include "alu.v"    //import alu module
`include "reg_file.v"   //import register file module
`timescale 1ns/100ps

/*
 module cpu for decode the instructions, handle the register files and handle the alu
 */
module cpu(PC, INSTRUCTION, CLK, RESET,read,write_mem,RESULT,OUT1_reg,readdata,busywait,ins_read,ins_busywait);
    // Define inputs and outputs
    input [31:0] INSTRUCTION; 
    input CLK, RESET,busywait,ins_busywait;
    output [7:0] readdata,RESULT,OUT1_reg;
    output read,write_mem;
    output reg ins_read;
    output reg [31:0] PC;
 
    // Registers to store decoded instructions bytes
    wire [7:0] op_code,destination,source1,source2;

    // Assigning multiplexer for decide to 2s complement or not
    reg IS_COMP;
    wire [7:0] OUT_MUX1;
    wire [2:0] READREG2;
    wire [7:0] OUT2_reg;
    wire [7:0] negative_val;
    assign #1 negative_val = -OUT2_reg;
    mux_8bit mux_2s_com(OUT2_reg,negative_val,IS_COMP,OUT_MUX1);

    //Assign multiplexer to decide for register value or immediate value
    reg IS_IMMEDIATE;
    wire [7:0] OUT_MUX2;
    wire [7:0] Imm_val;
    assign Imm_val = source2;
    mux_8bit mux_immediate(OUT_MUX1,Imm_val,IS_IMMEDIATE,OUT_MUX2);

    // Registers for ALU and register file modules
    wire [2:0] READREG1, INADDRESS;
    wire [7:0] IN;
    reg WRITE;
    wire [7:0] OUT1_reg,RESULT;
    reg_file myreg(IN, OUT1_reg, OUT2_reg, INADDRESS, READREG1, READREG2, WRITE, CLK, RESET);
    
    // Arithmatic and logic unit
    wire ZERO;
    wire [7:0] DATA1;
    reg [2:0] ALUOP;
    alu myalu(OUT1_reg, OUT_MUX2, RESULT, ALUOP,ZERO);

    // Register for store increased pc value temporary
    wire [31:0] PC_Holder; //To keep next pc temporary
    reg BNE,BEQ,JUMP;   // Flag for bne , beq , jump respectively
    
    mux_32bit mux_pc(PC+32'd4,PC+32'd4+{{22{destination[7]}},destination,2'b00},((BEQ&ZERO)|(BNE&(!ZERO))|JUMP),PC_Holder);

    //Multiplexer for registe input
    wire [7:0] readdata;
    wire busywait;
    reg read,write_mem;
    reg IS_MEM;
    mux_8bit mux_in_reg(RESULT,readdata,IS_MEM,IN);

    reg writing_flag = 1'b0;
    // Always block for reset the PC value
    always @(RESET)
    begin
        if(RESET==1'b1 ) begin
            #1
            PC = -32'd4;
            BEQ=0;
            BNE=0;
            JUMP=0;
        end
    end
    
    // Increase the PC by 4 with CLK edge
    always @(posedge CLK)
    begin
        #1 //Unit one latency for PC update
        if(busywait==0 && ins_busywait==0)begin    
            PC = PC_Holder;
            ins_read = 1'b1;
        end
    end

    always @ (negedge ins_busywait)
    begin
        ins_read = 1'b0;
    end

    always @ (negedge busywait)
    begin
        read = 0;
        write_mem = 0;
    end

    // assign value always
    assign {op_code,destination,source1,source2} = INSTRUCTION;
    assign INADDRESS = destination[2:0];
    assign READREG1 = source1[2:0];
    assign READREG2 = source2[2:0];
    //// Instruction decoding
    always @(INSTRUCTION)
    begin
        #1  // Latency of one for instruction decoding
        case(op_code)
            // Case for add
            8'b00000010:begin
                WRITE = 1'b1;
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b0;
                IS_IMMEDIATE = 1'b0;
                ALUOP = 3'b001;
                write_mem = 1'b0;
                read = 1'b0;
                IS_MEM = 1'b0;
            end
            // Case for subtract
            8'b00000011:begin
                WRITE = 1'b1;
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b1;
                IS_IMMEDIATE = 1'b0;
                ALUOP = 3'b001;
                write_mem = 1'b0;
                read = 1'b0;
                IS_MEM = 1'b0;
            end
            // Case for bitwise AND
            8'b00000100:begin
                WRITE = 1'b1;
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b0;
                IS_IMMEDIATE = 1'b0;
                ALUOP = 3'b010;
                write_mem = 1'b0;
                read = 1'b0;
                IS_MEM = 1'b0;
            end
            //Case for bitwise OR
            8'b00000101:begin
                WRITE = 1'b1;
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b0;
                IS_IMMEDIATE = 1'b0;
                ALUOP = 3'b011;
                write_mem = 1'b0;
                read = 1'b0;
                IS_MEM = 1'b0;
            end
            // Case for load immediate value
            8'b00000000:begin
                WRITE = 1'b1;
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b0;
                IS_IMMEDIATE = 1'b1;
                ALUOP = 3'b000;
                write_mem = 1'b0;
                read = 1'b0;
                IS_MEM = 1'b0;
            end
            // Case for move register value
            8'b00000001:begin
                WRITE = 1'b1;
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b0;
                IS_IMMEDIATE = 1'b0;
                ALUOP = 3'b000;
                write_mem = 1'b0;
                read = 1'b0;
                IS_MEM = 1'b0;
            end
            // Case for branch equal
            8'b00000111:begin
                WRITE = 1'b0;
                BEQ = 1'b1;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b1;
                IS_IMMEDIATE = 1'b0;
                ALUOP = 3'b001;
                write_mem = 1'b0;
                read = 1'b0;
                IS_MEM = 1'b0;
            end
            // case for jump
            8'b00000110:begin
                WRITE = 1'b0;
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b1;
                IS_COMP = 1'b1;
                IS_IMMEDIATE = 1'b0;
                ALUOP = 3'b001;
                write_mem = 1'b0;
                read = 1'b0;
                IS_MEM = 1'b0;
            end
            // Case for branch not equal
            8'b00001001:begin
                WRITE = 1'b0;
                BEQ = 1'b0;
                BNE = 1'b1;
                JUMP = 1'b0;
                IS_COMP = 1'b1;
                IS_IMMEDIATE = 1'b0;
                ALUOP = 3'b001;
                write_mem = 1'b0;
                read = 1'b0;
                IS_MEM = 1'b0;
            end
            // Case for left shift
            8'b00001011:begin
                WRITE = 1'b1;
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b0;
                IS_IMMEDIATE = 1'b1;
                ALUOP = 3'b100;
                write_mem = 1'b0;
                read = 1'b0;
                IS_MEM = 1'b0;
            end
            // Case for right shift
            8'b00001100:begin
                WRITE = 1'b1;
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b0;
                IS_IMMEDIATE = 1'b1;
                ALUOP = 3'b101;
                write_mem = 1'b0;
                read = 1'b0;
                IS_MEM = 1'b0;
            end
            // Case for arithmatic right shift
            8'b00001101:begin
                WRITE = 1'b1;
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b0;
                IS_IMMEDIATE = 1'b1;
                ALUOP = 3'b110;
                write_mem = 1'b0;
                read = 1'b0;
                IS_MEM = 1'b0;
            end
            //Case for rotate right shift
            8'b00001110:begin
                WRITE = 1'b1;
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b0;
                IS_IMMEDIATE = 1'b1;
                ALUOP = 3'b111;
                write_mem = 1'b0;
                read = 1'b0;
                IS_MEM = 1'b0;
            end
            //Case for lwd
            8'b00001111:begin
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b0;
                IS_IMMEDIATE = 1'b0;
                ALUOP = 3'b000;
                write_mem = 1'b0;
                read = 1'b1;
                IS_MEM = 1'b1;
                WRITE = 1'b1;
                writing_flag = 1'b1;
            end
            //Case for lwi
            8'b00010000:begin
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b0;
                IS_IMMEDIATE = 1'b1;
                ALUOP = 3'b000;
                write_mem = 1'b0;
                read = 1'b1;
                IS_MEM = 1'b1;
                WRITE = 1'b1;
                writing_flag = 1'b1;
            end
            //Case for swd
            8'b00010001:begin
            	WRITE = 1'b0;
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b0;
                IS_IMMEDIATE = 1'b0;
                ALUOP = 3'b000;
                write_mem = 1'b1;
                read = 1'b0;
                IS_MEM = 1'b1;
            end
            //Case for swi
            8'b00010010:begin
            	WRITE = 1'b0;
                BEQ = 1'b0;
                BNE = 1'b0;
                JUMP = 1'b0;
                IS_COMP = 1'b0;
                IS_IMMEDIATE = 1'b1;
                ALUOP = 3'b000;
                write_mem = 1'b1;
                read = 1'b0;
                IS_MEM = 1'b1;
            end
        endcase
    end
endmodule

//Multiplexer with 8 bits
module mux_8bit(IN1,IN2,SELECT,OUT);
    //Define inputs and outputs
    input [7:0] IN1,IN2;
    input SELECT;
    output reg [7:0] OUT; 

    always @ (IN1, IN2, SELECT)
    begin
        if (SELECT == 1'b0)
            OUT = IN1;
        else
            OUT = IN2;
    end
endmodule

//Multiplexer with 32 bits
module mux_32bit(IN1,IN2,SELECT,OUT);
    //Define inputs and outputs
    input [31:0] IN1,IN2;
    input SELECT;
    output reg [31:0] OUT; 

    always @ (IN1, IN2,SELECT)
    begin
        #1
        if (SELECT == 1'b0)
            OUT = IN1;
        else
            OUT = IN2;
    end
endmodule