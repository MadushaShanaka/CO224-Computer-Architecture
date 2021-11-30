// Computer Architecture (CO224) - Lab 06
// Design: Integrated CPU of Simple Processor
// Author: Shanaka T.K.M.
// Reg_No: E/16/351

`timescale 1ns/100ps

module cache_memory(clock,
				    reset,
				    read,
				    write,
				    address,
				    writedata,
				    readdata,
				    busywait,
				    read_mem,write_mem,address_mem,writedata_mem,readdata_mem,busywait_mem);

	//inputs and outputs for cache memory
	input clock, reset, read, write;
	input [7:0] address, writedata;
	output reg [7:0] readdata;
	output reg busywait;
	// Input output for datamemory

	output read_mem,write_mem;
	input busywait_mem;
	input [31:0] readdata_mem;
	output reg [31:0] writedata_mem;
	output reg [5:0] address_mem;
	
	//Array defining
	reg [31:0] cache [7:0];
	reg [2:0] tag [7:0];
	reg valid [7:0];
	reg dirty [7:0];

	wire valid_bit, dirty_bit,tag_comparison;
	wire [31:0] block;
	wire [2:0] index,tag_bits,tag_in;
	wire [1:0] offset;
	wire [7:0] word1,word2,word3,word4;

	//extract tag, index and offset from address
	assign {tag_in,index,offset} = address;
	// get validity , dirty , tag ,and cache block for current inputs
	assign #1 {valid_bit, dirty_bit, tag_bits, block} = {valid[index], dirty[index], tag[index], cache[index]};
	// compare that given tag with tag in cache
	assign #0.9 tag_comparison = (tag_in == tag_bits)?1 : 0;
	//extract words from current block
	assign #1 {word4, word3, word2, word1} = block;

	wire hit;
	// check for hit
	assign hit = tag_comparison & valid_bit;

	reg read_mem,write_mem;
	wire [31:0] readdata_mem;
	wire busywait_mem;

	//assign busywait if cache memory or data memory on work
	always @(read, write)
	begin
		busywait = (read || write)? 1 : 0;
	end

	//rading values in cache
	always @(*)
	begin
	if(read && hit)begin
		case(offset)
			2'd0:	#1 readdata = word1;
			2'd1:	#1 readdata = word2;
			2'd2:	#1 readdata = word3;
			2'd3:	#1 readdata = word4;
		endcase
	end
	end


	always @(posedge clock) begin
		//zero the busywait if work is done
		if(hit) begin
			busywait = 1'b0;
		end
		//set states forward
		pre_state = state;
		state = next_state;
	end

	reg [31:0] tmp = 32'd0;
	reg write_word,write_block;
	integer l=0;
	//write onr word to cache
	always @(posedge clock) begin
		#0.9;
		if(write_word) begin
			l++;
			tmp = cache[index];
			case(offset)
			2'd0:	tmp [7:0] = writedata;
			2'd1:	tmp [15:8] = writedata;
			2'd2:	tmp [23:16] = writedata;
			2'd3:	tmp [31:24] = writedata;
			endcase
			cache[index] = tmp;
			dirty[index] = 1;

			//set values to inial state
			write_word = 1'b0;
			write_block = 1'b0;
			busywait =1'b0;
			state = INTIAL;
			read_mem = 0;
			//write_mem = 0;
		end
	end

	// write a block to cache
	always @(posedge clock) begin
		#1;
		if(write_block)begin
			if(!busywait_mem) begin
				
				tag[index] = tag_in;
				cache[index] = readdata_mem;
				dirty[index] = 0;
				valid[index] = 1;
				//set values to inial state if it is not a write
				if(!write)begin
					busywait = 0;
					state = INTIAL;
					read_mem = 0;
					write_mem = 0;
				end
				write_block = 1'b0;
			end
		end
	end

	//State machine//
	//assign parameters for states
	parameter INTIAL=4'd0,READ_CACHE = 4'd1,WRITE_MEMORY=4'd2,READ_MEMORY=4'd3,WRITE_CACHE=4'd4;
	reg [3:0] state,next_state,pre_state;

	always @(*)
	begin
	// handle next state with time
	case(state)
		//initial state
		INTIAL:begin
			if(read && !hit && !dirty_bit)
				next_state = READ_MEMORY;
			else if(read && !hit && dirty_bit)
				next_state = WRITE_MEMORY;
			else if(write && hit)
				next_state = WRITE_CACHE;
			else if(write && !hit && !dirty_bit)
				next_state = READ_MEMORY;
			else if(write && !hit && dirty_bit)
				next_state = WRITE_MEMORY;
			else
				next_state = INTIAL;
		end
		// write memory state
		WRITE_MEMORY:begin
			if(!busywait_mem)
				next_state = READ_MEMORY;
			else
				next_state = WRITE_MEMORY;
		end
		//read memory state
		READ_MEMORY:begin
			if(!busywait_mem)
				next_state = WRITE_CACHE;
			else
				next_state = READ_MEMORY;
		end
		//write cache state
		WRITE_CACHE:begin
			if(!busywait)
				next_state = INTIAL;
			else
				next_state = WRITE_CACHE;
		end
	endcase
	end

	//assign control signals according to states
	always @(*)
	begin
	case(state)
		//intial state
		INTIAL: write_word =1'b0;
		//cache read state
		READ_CACHE:begin
			read_mem = 0;
			write_mem = 0;
			address_mem = 8'dx;
			writedata_mem = 8'dx;
		end
		//write cache state
		WRITE_MEMORY:begin
			read_mem = 0;
			write_mem = 1;
			address_mem = {tag[index],index};
			writedata_mem = cache[index];
		end
		//read cache state
		READ_MEMORY:begin
			read_mem = 1;
			write_mem = 0;
			address_mem = {tag_in,index};
		end
		//write cache state
		WRITE_CACHE:begin
			if(pre_state == READ_MEMORY)
				write_block = 1'b1;
			else
				write_word = 1'b1;
		end
	endcase
	end

	//reset the cache memory
	integer i;
	always @(posedge reset)
	begin
	    if (reset)
	    begin
	        for (i=0;i<8; i=i+1)begin
	            cache[i] = 0;
	            valid[i] = 0;
	            dirty[i] = 0;
	            tag[i] = 0;
	        end
	    end
	    //set values to initial
	    busywait = 0;
		read_mem = 0;
		write_mem = 0;
		state = INTIAL;
		pre_state = INTIAL;
		write_word =1'b0;
		write_block = 1'b0;
	end
endmodule
