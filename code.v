`timescale 1ns / 1ps
`default_nettype none
module code(
			input wire clk,
			input wire reset,
			input wire start,
			input wire [6:0] addr,
			input wire [31:0] data,
			output reg i2c_sda,
			output wire i2c_scl,
			output reg ready,
			output reg stop,
			output wire output1,
			output wire output2,
			output wire output3,
			output wire output4
    );
//////////////////////////////////------MASTER-------////////////////////////////////////////
//defining state_machines
parameter STATE_IDLE=0;
parameter STATE_START=1;
parameter STATE_ADDR=2;
parameter STATE_RW=3;
parameter STATE_WACK=4;
parameter STATE_DATA=5;
parameter STATE_WACK2=6;
parameter STATE_STOP=7;

reg [7:0] state=0;
reg [14:0] count;

reg [6:0] saved_addr;
reg [31:0] saved_data;
reg i2c_scl_enable=0;

wire wack1; // Acknowledge for address
wire wack2; //Acknowledge for data

reg wack11=0;
reg wack22=0;

assign wack1=wack11; //wack11 is used in slave design
assign wack2=wack22;  //wack22 is used in slave design

assign i2c_scl = (i2c_scl_enable == 0) ? 1 : ~clk;
		
always @(negedge clk) //neg  
	begin
		if(reset ==1)
			begin
				i2c_scl_enable<=0;
			end 
		else
			begin
				if(( state==STATE_IDLE)||(state==STATE_START)||(state==STATE_STOP))
				i2c_scl_enable<=0;
				else 
				i2c_scl_enable<=1;
	      end
end

always @(posedge clk) 
	begin  
			if(reset==1) begin
				state<=STATE_IDLE;
				i2c_sda<=1;
			end
   
			else 
				begin
		
				case(state)
						STATE_IDLE:  begin 
								i2c_sda<=1;
										if(start) begin
											state<=STATE_START;
											ready<=0;
											stop<=0;
										end
										else 
											state<=STATE_IDLE;
						end //end state idle
				
						STATE_START: begin //msb address bit
									i2c_sda<=0; 
									saved_addr<=addr;
									saved_data<=data;
									ready<=1'b1;
									stop<=0;
									state<= STATE_ADDR;
									count<=6;
						end // end state addr
				 
						STATE_ADDR: begin
								  i2c_sda<=saved_addr[count];
							     ready<=0; 
								  stop<=0;
										if(count==0) state<= STATE_RW;
										else count <= count-1;
						end //end state addr
			
						STATE_RW: begin
								 i2c_sda<=1;   //enable<=1	
								 ready<=0;
								 stop<=0;
								 state<= STATE_WACK;
              		end // end state rw
					
						STATE_WACK : begin
						
								if((address==addr1)||(address==addr2)||(address==addr3)||(address==addr4))
										i2c_sda<=1;
								else
										i2c_sda<=0;	
								ready<=0;
								stop<=0;
								state<=STATE_DATA;
								count<=31;
						end //end state wack
					
						STATE_DATA : begin
								i2c_sda<= saved_data[count];
								ready<=0; 
								stop<=0;
									if(count ==0) state <=STATE_WACK2;
									else count<= count-1;
						end //end state data
					
						STATE_WACK2 : begin
								i2c_sda<=wack2;
								ready<=0;
								stop<=0;
								state<=STATE_STOP;
						end //end wack2
			
						STATE_STOP: begin
								i2c_sda<=1;
								ready<=0;
								stop<=1;
								state<= STATE_IDLE;
					end//end stop
				endcase
			end //end else
		end //end always
		
//////////////////////////////////------SLAVES-------////////////////////////////////////////

wire [6:0] address; //address cum rd/wr enable
reg [7:0] counter=6;
reg [7:0] rx_state=8;

//defining parameters for SLAVES
parameter RX_IDLE=8;
parameter RX_ADDR=9;
parameter RX_RD_WR_ENABLE=10;
parameter RX_WACK1=11;
parameter RX_OUTPUT=12;
parameter RX_WACK2=13;
parameter RX_NON_OUTPUT=14;
parameter RX_STOP=15;

// pre-defined unique addresses for slaves of 7-bit 
reg [6:0] addr1=7'b1111000;
reg [6:0] addr2=7'b1100110;
reg [6:0] addr3=7'b1110001;
reg [6:0] addr4=7'b1010101;

reg [6:0] address1; //temporary address register for matching
wire reset1; // temporary storage for reset  
wire start1; // temporary storage for start

assign start1=start;
assign reset1=reset;

assign address=address1; //address register at receiever 

reg output11=0; //temporary reg output1
reg output22=0; //temporary reg output2
reg output33=0; //temporary reg output3
reg output44=0; //temporary reg output4

assign output1=output11; //output terminal for slave-1
assign output2=output22; //output terminal for slave-2
assign output3=output33; //output terminal for slave-3
assign output4=output44; //output terminal for slave-4

always @(posedge clk)
 begin  
		case(rx_state)
			
				RX_IDLE:  begin 
									if(ready) begin
									rx_state<=RX_ADDR;
										counter<=6;
											output11<=0;
												output22<=0;
													output33<=0;
														output44<=0;end
									else begin 
									rx_state<=RX_IDLE;
										output11<=0;
											output22<=0;
												output33<=0;
													output44<=0; end			
				end 
				 
			   RX_ADDR: begin
					 address1[counter]<=i2c_sda; 
					 output11<=0;output22<=0;output33<=0;output44<=0;
					
				   if(counter==0) begin
							rx_state<= RX_RD_WR_ENABLE;
					  end		
					else counter <= counter-1; 
			    end  
			
				RX_RD_WR_ENABLE: 	begin
             			rx_state<= RX_WACK1;	
							output11<=0;output22<=0;output33<=0;output44<=0;					
  				end 
					
				RX_WACK1:	begin
						if((address==addr1)||(address==addr2)||(address==addr3)||(address==addr4))
								begin wack11<=1;
								rx_state<=RX_OUTPUT; 
								counter<=31;
							   end
						else
								begin wack11<=0; 
								rx_state<=RX_NON_OUTPUT; 
								counter<=31;
								end
			   end
				 
			  RX_OUTPUT: 	begin
							        if(address==addr1)
						           	begin
							           output11<= i2c_sda; wack22<=1;
					                      if(counter ==0) rx_state <=RX_WACK2;
					                  else counter<= counter-1;
					              end 
						  
						           else if(address==addr2)
							         begin
							            output22<= i2c_sda; wack22<=1;
					                    if(counter ==0) rx_state <=RX_WACK2;
					                     else counter<= counter-1;
					              end 
  
	          					  else if(address==addr3)
				          			begin
							            output33<= i2c_sda;wack22<=1;
					                    if(counter ==0) rx_state <=RX_WACK2;
					                      else counter<= counter-1;
					               end 

						           else if(address==addr4)
							          begin
							            output44<= i2c_sda;wack22<=1;
					                     if(counter ==0) rx_state <=RX_WACK2;
					                      else counter<= counter-1;
					               end 
						  
						             else 
						                begin 
							                 output44<=0; 
												  output33<=0;
												  output22<=0;
												  output11<=0;
												  wack11<=0;
												  wack22<=0;
					                         if(counter ==0) rx_state <=RX_WACK2;
					                           else counter<= counter-1;
					                    end 
				end
							
				RX_NON_OUTPUT:	begin
							      output44<=0; output33<=0; output22<=0; output11<=0;
					                     
									if(counter ==0) rx_state<=RX_WACK2;
					            else counter<= counter-1;
			   end 
			
					
			   RX_WACK2:	 begin 
								wack22<=1; 
								rx_state<=RX_STOP;
								output11<=0;output22<=0;output33<=0;output44<=0;
				end
					
				RX_STOP: 	begin 
								output11<=0;output22<=0;output33<=0;output44<=0;
								wack11<=0;
								wack22<=0;
								rx_state<=RX_IDLE; 
   			end	
	
  	endcase //endcase
 end //end always

endmodule



