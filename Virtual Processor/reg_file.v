/* Computer Architecture Lab 05 Part II
 * Design: Register File
 * Author: E/16/351 Shanaka T.K.M.
 * Date	: 03-May-2020
 */
`timescale 1ns/100ps

 module reg_file(IN, OUT1, OUT2, INADDRESS, OUT1ADDRESS, OUT2ADDRESS, WRITE, CLK, RESET);
 	//Defining ports
 	input [2:0] OUT2ADDRESS, OUT1ADDRESS, INADDRESS;
	input [7:0] IN;
	input CLK, WRITE, RESET;
	output [7:0] OUT1, OUT2;

	reg [7:0] OUT1, OUT2;
	reg [7:0] register_array [0:7];
	reg [3:0] i;//increment

	//Set output 1
	always @ (OUT1ADDRESS, register_array[OUT1ADDRESS])
	begin
		case(RESET)
			1'b1:
				//Delaying time = resetting time + reading time =4
				#4
				OUT1 = register_array[OUT1ADDRESS];
			1'b0:
				//Only reading time delaying
				#2
				OUT1 = register_array[OUT1ADDRESS];
		endcase
		
	end
	//Set output2
	always @ (OUT2ADDRESS, register_array[OUT2ADDRESS])
	begin
		case(RESET)
			1'b1:
				//Delaying time = resetting time + reading time =4
				#4
				OUT2 = register_array[OUT2ADDRESS];
			1'b0:
				//Only reading time delaying
				#2
				OUT2 = register_array[OUT2ADDRESS];
		endcase
	end

	//Resetting
	always @ (posedge RESET)
	begin
		//2 units time delaying
		#2
		//set all values to zero
		for(i=0;i<8;i=i+1)
		begin
			register_array[i] = 8'b00000000;
		end
	end

	//Writing values
	always @ (posedge CLK)
	begin
		if(WRITE && (~RESET )) 
		begin
			//Time delaying of 2 when writing
			#1
			//Writing in register file
			register_array[INADDRESS] = IN;
		end
	end
 endmodule