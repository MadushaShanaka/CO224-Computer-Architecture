//CO224 Computer Architecture
//Lab5 part1
//E/16/351
//Shanaka T.K.M

`timescale 1ns/100ps
//creating moduele for ALU
module alu(DATA1, DATA2, RESULT, SELECT, ZERO);
	//define inputs and outputs
	input [7:0] DATA1,DATA2;
	input [2:0] SELECT;
	output reg [7:0] RESULT;
	output ZERO;
	reg [7:0] shifted;
	reg temp;
	integer i,j;

	wire [7:0] result_forward , result_add, result_and, result_or;

	assign #1 result_forward = DATA2; // forward opearation
	assign #2 result_add = DATA1 + DATA2; // add opearation
	assign #1 result_and = DATA1 & DATA2;// bitwise AND opearation
	assign #1 result_or = DATA1 | DATA2; // bitwise OR opeartion

	assign ZERO = ~(RESULT[0]|RESULT[1]|RESULT[2]|RESULT[3]|RESULT[4]|RESULT[5]|RESULT[6]|RESULT[7]);
	//barrel_shifter_8bit myshift(DATA1, DATA2[2:0], shifted);
	
	//set variables for always checking
	always @(*)
	begin
		case(SELECT)
			//loadi or mov operation
			3'b000: RESULT=result_forward;
			//add or sub operation
			3'b001: RESULT=result_add;
			//bitwise and operation
			3'b010: RESULT=result_and;
			//bitwise or operation
			3'b011: RESULT=result_or;
			// left shift
			3'b100: begin
				#1
				shifted = DATA1; //copy data1
				for(i=0;i<DATA2;i=i+1)begin
					for(j=7;j>0;j=j-1)begin
						shifted[j]=shifted[j-1]; // one left shift bit
					end
					shifted[0]=1'b0;
				end
				RESULT = shifted;
			end
			//right shift
			3'b101: begin
				#1
				shifted = DATA1;  //copy data1
				for(i=0;i<DATA2;i=i+1)begin
					for(j=0;j<7;j=j+1)begin
						shifted[j]=shifted[j+1];   //one right shift bit
					end
					shifted[7]=1'b0;
				end
				RESULT = shifted;
			end
			//arithmatic right shift
			3'b110: begin
				#1
				shifted = DATA1;  //copy data1
				for(i=0;i<DATA2;i=i+1)begin
					for(j=0;j<7;j=j+1)begin
						shifted[j]=shifted[j+1]; //one right arithmatic shift bit
					end
					shifted[7]=shifted[6];
				end
				RESULT = shifted;
			end
			//rotate right shift
			3'b111: begin
				#1
				shifted = DATA1;  //copy data1
				for(i=0;i<DATA2;i=i+1)begin
					temp = shifted[0];  //memorize last bit
					for(j=0;j<7;j=j+1)begin
						shifted[j]=shifted[j+1]; //one right rotate shift bit
					end
					shifted[7]=temp;
				end
				RESULT = shifted;
			end
			default: RESULT = 8'b00000000;
		endcase
	end
endmodule 