`timescale 1ns / 1ps	

`define STATE_RESET 0
`define STATE_POWERON_INIT_0_A 1
`define STATE_POWERON_INIT_0_B 2
`define STATE_POWERON_INIT_1 3
`define STATE_POWERON_INIT_2_A 4
`define STATE_POWERON_INIT_2_B 5
`define STATE_POWERON_INIT_3 6
`define STATE_POWERON_INIT_4_A 7
`define STATE_POWERON_INIT_4_B 8
`define STATE_POWERON_INIT_5 9
`define STATE_POWERON_INIT_6_A 10
`define STATE_POWERON_INIT_6_B 11
`define STATE_POWERON_INIT_7 12
`define STATE_POWERON_INIT_8_A 13
`define STATE_POWERON_INIT_8_B 14
`define STATE_DISP_CONF_FUNC_0 15
`define STATE_DISP_CONF_FUNC_0_A 16
`define STATE_DISP_CONF_FUNC_0_B 17
`define STATE_DISP_CONF_FUNC_1 18
`define STATE_DISP_CONF_FUNC_1_A 19
`define STATE_DISP_CONF_FUNC_1_B 20
`define STATE_DISP_CONF_FUNC_2 21
`define STATE_DISP_CONF_FUNC_2_A 22
`define STATE_DISP_CONF_FUNC_2_B 23
`define STATE_DISP_CONF_FUNC_3 24
`define STATE_DISP_CONF_FUNC_3_A 25
`define STATE_DISP_CONF_FUNC_3_B 26
`define STATE_DISP_CONF_FUNC_4 27
`define STATE_DISP_CONF_FUNC_4_A 28
`define STATE_DISP_CONF_FUNC_4_B 29
`define STATE_DISP_CONF_FUNC_5 30
`define STATE_DISP_CONF_FUNC_5_A 31
`define STATE_DISP_CONF_FUNC_5_B 32
`define STATE_DISP_CONF_FUNC_6 33
`define STATE_DISP_CONF_FUNC_6_A 34
`define STATE_DISP_CONF_FUNC_6_B 35
`define STATE_DISP_CONF_FUNC_7 36
`define STATE_DISP_CONF_FUNC_7_A 37
`define STATE_DISP_CONF_FUNC_7_B 38
`define STATE_DISP_CONF_FUNC_8 39
`define STATE_WRITE_UPPER_NIBBLE_SETUP 40
`define STATE_WRITE_UPPER_NIBBLE 41
`define STATE_WRITE_UPPER_NIBBLE_HOLD 42
`define STATE_WRITE_LOWER_NIBBLE_SETUP 43
`define STATE_WRITE_LOWER_NIBBLE 44
`define STATE_WRITE_LOWER_NIBBLE_HOLD 44


module Module_LCD_Control
	(
		input wire Clock,
		input wire Reset,
		output wire oLCD_Enabled,
		output reg oLCD_RegisterSelect, //0=Command, 1=Data
		output wire oLCD_StrataFlashControl,
		output wire oLCD_ReadWrite,
		output reg[3:0] oLCD_Data
	);

	assign oLCD_Enabled = 1;
	reg rWrite_Enabled;
	assign oLCD_ReadWrite = 0; //I only Write to the LCD display, never Read from it
	assign oLCD_StrataFlashControl = 1; //StrataFlash disabled. Full read/write access to LCD
	reg [7:0] rCurrentState,rNextState;
	reg [31:0] rTimeCount;
	reg rTimeCountReset;
	reg [4:0] rWriteDone;

	//----------------------------------------------

	//Next State and delay logic

	always @ ( posedge Clock )
		begin
			if (Reset)
				begin
					rCurrentState <= `STATE_RESET;
					rTimeCount <= 32'b0;
				end
			else
				begin
					if (rTimeCountReset)
						rTimeCount <= 32'b0;
					else
						rTimeCount <= rTimeCount + 32'b1;
			
					rCurrentState <= rNextState;
				end
		end
//----------------------------------------------

	always @ ( * )
		
		begin
			
			case (rCurrentState)
			
				//------------------------------------------
				`STATE_RESET:
				begin
					rWriteDone = 0;
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h0;
					oLCD_RegisterSelect = 1'b0;
					rTimeCountReset = 1'b0;
					rNextState = `STATE_POWERON_INIT_0_A;
				end
				//------------------------------------------
				/*
				Wait 15 ms or longer.
				The 15 ms interval is 750,000 clock cycles at 50 MHz.
				*/
				`STATE_POWERON_INIT_0_A:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h0;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
				
					if (rTimeCount > 32'd760000 )
						rNextState = `STATE_POWERON_INIT_0_B;
					else
						rNextState = `STATE_POWERON_INIT_0_A;
					end
				//------------------------------------------
				`STATE_POWERON_INIT_0_B:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h3;
					oLCD_RegisterSelect = 1'b0; //these are commands
					
					if (rTimeCount > 32'd760100)
						begin
							rTimeCountReset = 1'b1;
							rNextState = `STATE_POWERON_INIT_1;
						end
					else
						rNextState = `STATE_POWERON_INIT_0_B;
				end
				//------------------------------------------
				/*
				Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
				*/
				`STATE_POWERON_INIT_1:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'h3;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_POWERON_INIT_2_A;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_POWERON_INIT_1;
						end
				end
				//------------------------------------------
				/*
				Wait 4.1 ms or longer, which is 205,000 clock cycles at 50 MHz.
				*/
				`STATE_POWERON_INIT_2_A:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h3;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd206000 )
						rNextState = `STATE_POWERON_INIT_2_B;
					else
						rNextState = `STATE_POWERON_INIT_2_A;
				end
				//------------------------------------------
				`STATE_POWERON_INIT_2_B:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h3;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b1;
					rNextState = `STATE_POWERON_INIT_3;
				end
				//------------------------------------------
				`STATE_POWERON_INIT_3:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'h3;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_POWERON_INIT_4_A;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_POWERON_INIT_3;
						end
				end
				//------------------------------------------
				`STATE_POWERON_INIT_4_A:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h3;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd6000 )
						rNextState = `STATE_POWERON_INIT_4_B;
					else
						rNextState = `STATE_POWERON_INIT_4_A;
				end
				//------------------------------------------
				`STATE_POWERON_INIT_4_B:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h3;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b1;
					rNextState = `STATE_POWERON_INIT_5;
				end
				//------------------------------------------
				`STATE_POWERON_INIT_5:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'h3;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_POWERON_INIT_6_A;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_POWERON_INIT_5;
						end
				end
				//------------------------------------------
				`STATE_POWERON_INIT_6_A:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h3;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd3000 )
						rNextState = `STATE_POWERON_INIT_6_B;
					else
						rNextState = `STATE_POWERON_INIT_6_A;
				end
				//------------------------------------------
				`STATE_POWERON_INIT_6_B:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h2;
					oLCD_RegisterSelect = 1'b0; //these are commands
					
					if (rTimeCount > 32'd3020)
						begin
							rTimeCountReset = 1'b1;
							rNextState = `STATE_POWERON_INIT_7;
						end
					else
						rNextState = `STATE_POWERON_INIT_6_B;
				end
				//------------------------------------------
				`STATE_POWERON_INIT_7:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'h2;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_POWERON_INIT_8_A;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_POWERON_INIT_7;
						end
				end
				//------------------------------------------
				`STATE_POWERON_INIT_8_A:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h2;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd3000 )
						rNextState = `STATE_POWERON_INIT_8_B;
					else
						rNextState = `STATE_POWERON_INIT_8_A;
				end
				//------------------------------------------
				`STATE_POWERON_INIT_8_B:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h2;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISP_CONF_FUNC_0;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_0:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'h2;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_DISP_CONF_FUNC_0_A;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_DISP_CONF_FUNC_0;
						end
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_0_A:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h2;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd60 )
						rNextState = `STATE_DISP_CONF_FUNC_0_B;
					else
						rNextState = `STATE_DISP_CONF_FUNC_0_A;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_0_B:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h8;
					oLCD_RegisterSelect = 1'b0; //these are commands
					
					if (rTimeCount > 32'd72)
						begin
							rTimeCountReset = 1'b1;
							rNextState = `STATE_DISP_CONF_FUNC_1;
						end
					else
						rNextState = `STATE_DISP_CONF_FUNC_0_B;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_1:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'h8;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_DISP_CONF_FUNC_1_A;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_DISP_CONF_FUNC_1;
						end
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_1_A:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h8;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd3000 )
						rNextState = `STATE_DISP_CONF_FUNC_1_B;
					else
						rNextState = `STATE_DISP_CONF_FUNC_1_A;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_1_B:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h0;
					oLCD_RegisterSelect = 1'b0; //these are commands
					
					if (rTimeCount > 32'd3020)
						begin
							rTimeCountReset = 1'b1;
							rNextState = `STATE_DISP_CONF_FUNC_2;
						end
					else
						rNextState = `STATE_DISP_CONF_FUNC_1_B;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_2:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'h0;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_DISP_CONF_FUNC_2_A;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_DISP_CONF_FUNC_2;
						end
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_2_A:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h0;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd60 )
						rNextState = `STATE_DISP_CONF_FUNC_2_B;
					else
						rNextState = `STATE_DISP_CONF_FUNC_2_A;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_2_B:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h6;
					oLCD_RegisterSelect = 1'b0; //these are commands
					
					if (rTimeCount > 32'd72)
						begin
							rTimeCountReset = 1'b1;
							rNextState = `STATE_DISP_CONF_FUNC_3;
						end
					else
						rNextState = `STATE_DISP_CONF_FUNC_2_B;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_3:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'h6;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_DISP_CONF_FUNC_3_A;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_DISP_CONF_FUNC_3;
						end
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_3_A:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h6;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd3000 )
						rNextState = `STATE_DISP_CONF_FUNC_3_B;
					else
						rNextState = `STATE_DISP_CONF_FUNC_3_A;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_3_B:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h0;
					oLCD_RegisterSelect = 1'b0; //these are commands
					
					if (rTimeCount > 32'd3020)
						begin
							rTimeCountReset = 1'b1;
							rNextState = `STATE_DISP_CONF_FUNC_4;
						end
					else
						rNextState = `STATE_DISP_CONF_FUNC_3_B;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_4:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'h0;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_DISP_CONF_FUNC_4_A;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_DISP_CONF_FUNC_4;
						end
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_4_A:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h0;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd60 )
						rNextState = `STATE_DISP_CONF_FUNC_4_B;
					else
						rNextState = `STATE_DISP_CONF_FUNC_4_A;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_4_B:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'hC;
					oLCD_RegisterSelect = 1'b0; //these are commands
					
					if (rTimeCount > 32'd72)
						begin
							rTimeCountReset = 1'b1;
							rNextState = `STATE_DISP_CONF_FUNC_5;
						end
					else
						rNextState = `STATE_DISP_CONF_FUNC_4_B;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_5:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'hC;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_DISP_CONF_FUNC_5_A;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_DISP_CONF_FUNC_5;
						end
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_5_A:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'hC;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd3000 )
						rNextState = `STATE_DISP_CONF_FUNC_5_B;
					else
						rNextState = `STATE_DISP_CONF_FUNC_5_A;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_5_B:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h0;
					oLCD_RegisterSelect = 1'b0; //these are commands
					
					if (rTimeCount > 32'd3020)
						begin
							rTimeCountReset = 1'b1;
							rNextState = `STATE_DISP_CONF_FUNC_6;
						end
					else
						rNextState = `STATE_DISP_CONF_FUNC_5_B;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_6:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'h0;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_DISP_CONF_FUNC_6_A;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_DISP_CONF_FUNC_6;
						end
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_6_A:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h0;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd60 )
						rNextState = `STATE_DISP_CONF_FUNC_6_B;
					else
						rNextState = `STATE_DISP_CONF_FUNC_6_A;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_6_B:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h1;
					oLCD_RegisterSelect = 1'b0; //these are commands
					
					if (rTimeCount > 32'd72)
						begin
							rTimeCountReset = 1'b1;
							rNextState = `STATE_DISP_CONF_FUNC_7;
						end
					else
						rNextState = `STATE_DISP_CONF_FUNC_6_B;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_7:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'h1;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_DISP_CONF_FUNC_7_A;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_DISP_CONF_FUNC_8;
						end
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_7_A:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h1;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd94000 )
						rNextState = `STATE_DISP_CONF_FUNC_8;
					else
						rNextState = `STATE_DISP_CONF_FUNC_7_A;
				end
				//------------------------------------------
				`STATE_DISP_CONF_FUNC_8:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h1;
					oLCD_RegisterSelect = 1'b0; //these are commands
					rTimeCountReset = 1'b1;
					rNextState = `STATE_WRITE_UPPER_NIBBLE_SETUP;
				end
				//------------------------------------------
				`STATE_WRITE_UPPER_NIBBLE_SETUP:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'b1010;
					oLCD_RegisterSelect = 1'b1; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd10)
						begin
							rTimeCountReset = 1'b1;
							rNextState = `STATE_WRITE_UPPER_NIBBLE;
						end
					else
						rNextState = `STATE_WRITE_UPPER_NIBBLE_SETUP;
				end
				//------------------------------------------
				`STATE_WRITE_UPPER_NIBBLE:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'b1010;
					oLCD_RegisterSelect = 1'b1; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_WRITE_UPPER_NIBBLE_HOLD;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_WRITE_UPPER_NIBBLE;
						end
				end
				//------------------------------------------
				`STATE_WRITE_UPPER_NIBBLE_HOLD:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'b1010;
					oLCD_RegisterSelect = 1'b1; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd60 )
						rNextState = `STATE_WRITE_LOWER_NIBBLE_SETUP;
					else
						rNextState = `STATE_WRITE_UPPER_NIBBLE_HOLD;
				end
				//------------------------------------------
				`STATE_WRITE_LOWER_NIBBLE_SETUP:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'b0110;
					oLCD_RegisterSelect = 1'b1; //these are commands
					
					if (rTimeCount > 32'd72)
						begin
							rTimeCountReset = 1'b1;
							rNextState = `STATE_WRITE_LOWER_NIBBLE;
						end
					else
						rNextState = `STATE_WRITE_LOWER_NIBBLE_SETUP;
				end
				//------------------------------------------
				`STATE_WRITE_LOWER_NIBBLE:
				begin
					rWrite_Enabled = 1'b1;
					oLCD_Data = 4'b0110;
					oLCD_RegisterSelect = 1'b1; //these are commands
					rTimeCountReset = 1'b0;
					
					if ( rWriteDone > 5'd20 )
						begin
							rTimeCountReset = 1'b1;
							rWriteDone = 5'd0;
							rNextState = `STATE_WRITE_LOWER_NIBBLE_HOLD;	
						end
					else
						begin
							rWriteDone = rWriteDone + 1;
							rNextState = `STATE_WRITE_LOWER_NIBBLE;
						end
				end
				//------------------------------------------
				`STATE_WRITE_LOWER_NIBBLE_HOLD:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'b0110;
					oLCD_RegisterSelect = 1'b1; //these are commands
					rTimeCountReset = 1'b0;
					
					if (rTimeCount > 32'd10)
						rNextState = `STATE_WRITE_LOWER_NIBBLE_HOLD;
					else
						rNextState = `STATE_WRITE_LOWER_NIBBLE_HOLD;
				end
				//------------------------------------------
				default:
				begin
					rWrite_Enabled = 1'b0;
					oLCD_Data = 4'h0;
					oLCD_RegisterSelect = 1'b0;
					rTimeCountReset = 1'b0;
					rNextState = `STATE_RESET;
				end
				//------------------------------------------
				endcase
		end
		
endmodule