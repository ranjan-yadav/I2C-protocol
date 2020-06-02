`timescale 1ns / 1ps
module test;
	// Inputs
	reg clk; reg reset; reg start;
	reg [6:0] addr; reg [31:0] data;
	// Outputs
	wire i2c_sda;	wire i2c_scl;
	wire ready;  	wire stop;
	wire output1;	wire output2;
	wire output3;	wire output4;

// Instantiate the Unit Under Test (UUT)
	code uut (
		.clk(clk), 
		.reset(reset), 
		.start(start), 
		.addr(addr), 
		.data(data), 
		.i2c_sda(i2c_sda), 
		.i2c_scl(i2c_scl), 
		.ready(ready), 
		.stop(stop), 
		.output1(output1), 
		.output2(output2), 
		.output3(output3), 
		.output4(output4)
	);
initial begin 
		clk=0;
	forever begin
		clk =#10 ~clk;
	end
end

initial
	begin
	reset=1;
	#100;
	reset=0;
	start=1;	
	addr =7'b0000000;
	data =32'b10101111101011111010111110101111;
	
	#920
	reset=1;
	start=0;
   
	#300
	reset=0;
	start=1;	
	addr =7'b1111000;
	data =32'b10101010000011111111000001010101;
	
	#920
	reset=1;
	start=0;
	
	#300
	reset=0;
	start=1;	
	addr =7'b1010101;
	data =32'b01010111001100110011010101110011;
	
	#920
	reset=1;
	start=0;
end
endmodule      


