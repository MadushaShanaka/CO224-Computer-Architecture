// Computer Architecture (CO224) - Lab 05
// Design: Integrated CPU of Simple Processor
// Author: Shanaka T.K.M.
// Reg_No: E/16/351

`include "data_memory.v"   //import data memory module
`include "cache_memory.v"
`include "instruction_memory.v"   //import instruction memory module
`include "instruction_cache.v"
`timescale 1ns/100ps

module cpu_tb;

    reg CLK, RESET;
    wire [31:0] PC;
    //reg [31:0] INSTRUCTION = 32'd0; //Define 32 bit instruction and assign it to zero.
    integer i,j,k;
    //Initialize an array of registers (8x1024) to be used as instruction memory
    reg [7:0] ins_memory [1023:0]; 

    //wires for instruction memory and instruction cache memory
    wire ins_read,ins_busywait;
    wire [31:0] ins_readdata;
    wire ins_read_mem,ins_busywait_mem;
    wire [5:0] ins_address_mem;
    wire [127:0] ins_readdata_mem;

    //Instruction cache memory
    instruction_cache my_ins_cache(CLK, RESET,ins_read,PC [9:0],ins_readdata,ins_busywait,
                    ins_read_mem,ins_address_mem,ins_readdata_mem,ins_busywait_mem);
    //Instruction memory
    instruction_memory my_ins_mem(CLK,ins_read_mem,ins_address_mem,ins_readdata_mem,ins_busywait_mem);
    
    //CPU
    wire read, write, busywait;
    wire [7:0] readdata,address,writedata;
    cpu mycpu(PC, ins_readdata, CLK, RESET,read,write,address,writedata,readdata,busywait,ins_read,ins_busywait);

    wire read_mem,write_mem,busywait_mem;
    wire [5:0] address_mem;
    wire [31:0] writedata_mem,readdata_mem;
    //Cache memory
    cache_memory my_cache(CLK,RESET,read,write,address,writedata,readdata,busywait,
                    read_mem,write_mem,address_mem,writedata_mem,readdata_mem,busywait_mem);

    //Data memory
    
    data_memory my_data_mem(CLK,RESET,read_mem,write_mem,address_mem,writedata_mem,readdata_mem,busywait_mem);

    // Initial block
    initial
    begin
        
        // generate files needed to plot the waveform using GTKWave
        $dumpfile("cpu_wavedata.vcd");
        $dumpvars(0, cpu_tb);
        //dump register array
        for (j = 0; j < 8; j = j + 1) $dumpvars(0, mycpu.myreg.register_array[j]);
        for (j = 0; j < 8; j = j + 1) $dumpvars(0, my_cache.cache[j]);
        for (j = 0; j < 8; j = j + 1) $dumpvars(0, my_cache.valid[j]);
        for (j = 0; j < 8; j = j + 1) $dumpvars(0, my_cache.dirty[j]);
        for (k = 0; k < 256; k = k + 1) $dumpvars(0, my_data_mem.memory_array[k]);

        for (j = 0; j < 8; j = j + 1) $dumpvars(0, my_ins_cache.valid_array[j]);
        for (j = 0; j < 8; j = j + 1) $dumpvars(0, my_ins_cache.tag_array[j]);
        for (j = 0; j < 8; j = j + 1) $dumpvars(0, my_ins_cache.instruction[j]);
        
        CLK = 1'b0;
        RESET = 1'b0;
        #1
        RESET = 1'b1;// Reset the program counter
        #1
        RESET = 1'b0;
       
        // finish simulation after 100 time 
        #2000
        $finish;
        
    end
    
    // clock signal generation
    always
        #4 CLK = ~CLK;

endmodule
