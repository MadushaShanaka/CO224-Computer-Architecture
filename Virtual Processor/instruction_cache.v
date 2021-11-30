`timescale 1ns/100ps

module instruction_cache(clock,reset,read,address,readdata,busywait,
				    read_mem,address_mem,readdata_mem,busywait_mem);
	//declare inputs and outputs
	input clock,reset,read,busywait_mem;
	input [9:0] address;
	output reg [31:0] readdata;
	output reg busywait,read_mem;
	output reg [5:0] address_mem;
	input [127:0] readdata_mem;

	//declare arrays
	reg [127:0] instruction [7:0];
	reg [2:0] tag_array [7:0];
	reg valid_array [7:0];

	wire valid,tag_comparison;
	wire [127:0] ins_block;
	wire [2:0] index,tag,tag_in;
	wire [1:0] offset;
	wire [31:0] instruction4, instruction3, instruction2, instruction1;
	//extract tag, index and offset from address
	assign {tag_in,index,offset} = address [9:2];
	// get validity , dirty , tag ,and cache block for current inputs
	assign #1 {valid, tag, ins_block} = {valid_array[index], tag_array[index],instruction[index]};
	// compare that given tag with tag in cache
	assign #0.9 tag_comparison = (tag_in == tag)?1 : 0;
	//extract instructions from current block
	assign #1 {instruction4, instruction3, instruction2, instruction1} = ins_block;

	wire hit;
	// check for hit
	assign hit = tag_comparison & valid;

	wire [127:0] readdata_mem;
	wire busywait_mem;

	//assign busywait if cache memory or data memory on work
	always @(read)
	begin
		busywait = (read)? 1 : 0;
	end
	//reading values in cache
	always @(*)
	begin
		#1.1
		if(read && hit)begin
			case(offset)
				2'd0:	 readdata = instruction1;
				2'd1:	 readdata = instruction2;
				2'd2:	 readdata = instruction3;
				2'd3:	 readdata = instruction4;
			endcase
			busywait = 0;
		end
	end


	always @(posedge clock) begin
		//zero the busywait if work id done
		if(hit) begin
			busywait = 1'b0;
		end
		//set states forward
		state = next_state;
	end

	reg write_block;
	// write a block to cache
	always @(posedge clock) begin
		if(write_block)begin
			if(!busywait_mem) begin
				#1;
				tag_array[index] = tag_in;
				instruction[index] = readdata_mem;
				valid_array[index] = 1;
				//set values to intial state if it is not a write
				state = INTIAL;
				read_mem = 0;
				write_block = 1'b0;
			end
		end
	end


	//State machine//
	//assign parameters for states
	parameter INTIAL=0,READ_CACHE=1,READ_MEMORY=2,WRITE_CACHE=3;
	reg [1:0] state,next_state;

	always @(*)
	begin
	
	// handle next state with time
	case(state)
		//initial state
		INTIAL:begin
			if(read && !hit)
				next_state = READ_MEMORY;
			else
				next_state = INTIAL;
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
		READ_CACHE:begin
			read_mem = 0;
			address_mem = 6'dx;
		end
		//read cache state
		READ_MEMORY:begin
			read_mem = 1;
			address_mem = {tag_in,index};
			readdata = 32'dx;
		end
		//write cache state
		WRITE_CACHE:begin
			write_block = 1'b1;
		end
	endcase
	end
	integer i;
	always @(posedge reset)
	begin
	    if (reset)
	    begin
	        for (i=0;i<8; i=i+1)begin
	            instruction[i] = 0;
	            valid_array[i] = 0;
	            tag_array[i] = 0;
	        end
	    end
	    //set values to initial
	    busywait = 0;
		read_mem = 0;
		state = INTIAL;
		write_block = 1'b0;
	end

endmodule