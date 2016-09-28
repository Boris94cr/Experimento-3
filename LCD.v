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
`define STATE_DISPLAY_INIT_0_A 14
`define STATE_DISPLAY_INIT_0 15
`define STATE_DISPLAY_INIT_1_A 16
`define STATE_DISPLAY_INIT_1_B 17
`define STATE_DISPLAY_INIT_1 18
`define STATE_DISPLAY_INIT_2_A 19
`define STATE_DISPLAY_INIT_2_B 20
`define STATE_DISPLAY_INIT_2 21
`define STATE_DISPLAY_INIT_3_A 22
`define STATE_DISPLAY_INIT_3_B 23
`define STATE_DISPLAY_INIT_3 24
`define STATE_DISPLAY_INIT_4_A 25
`define STATE_DISPLAY_INIT_4_B 26
`define STATE_DISPLAY_INIT_4 27
`define STATE_DISPLAY_INIT_5_A 28
`define STATE_DISPLAY_INIT_5_B 29
`define STATE_DISPLAY_INIT_5 30
`define STATE_DISPLAY_INIT_6_A 31
`define STATE_DISPLAY_INIT_6_B 32
`define STATE_DISPLAY_INIT_6 33
`define STATE_DISPLAY_INIT_7_A 34
`define STATE_DISPLAY_INIT_7_B 35
`define STATE_DISPLAY_INIT_7 36
`define STATE_DISPLAY_FIN 37
`define STATE_UPPER_NIBBLE_0_A 38
`define STATE_UPPER_NIBBLE_0 39
`define STATE_UPPER_NIBBLE_0_B 40
`define STATE_LOWER_NIBBLE_0_A 41
`define STATE_LOWER_NIBBLE_0 42
`define STATE_LOWER_NIBBLE_0_B 43

module Module_LCD_Control(
	input wire Clock,
	input wire Reset,
	output reg oLCD_Enabled,
	output reg oLCD_RegisterSelect, //0=Command, 1=Data
	output wire oLCD_StrataFlashControl,
	output wire oLCD_ReadWrite,
	output reg[3:0] oLCD_Data
);

assign oLCD_ReadWrite = 0; //I only Write to the LCD display, never Read from it
assign oLCD_StrataFlashControl = 1; //StrataFlash disabled. Full read/write access to LCD
reg [7:0] rCurrentState,rNextState;
reg [31:0] rTimeCount;
reg rTimeCountReset;

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
//Current state and output logic

always @ ( * )
	begin
		case (rCurrentState)
		
		//------------------------------------------
		
		`STATE_RESET:
		begin
			oLCD_Enabled = 1'b0;
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
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h3;
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
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h3;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b1; //Reset the counter here
			rNextState = `STATE_POWERON_INIT_1;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_POWERON_INIT_1:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'h3;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_POWERON_INIT_2_A;
				end
			else
				rNextState = `STATE_POWERON_INIT_1;
		end
		
		//------------------------------------------
		/*
		Wait 4.1 ms or longer, which is 205,000 clock cycles at 50 MHz
		*/

		`STATE_POWERON_INIT_2_A:
		begin
			oLCD_Enabled = 1'b0;
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
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h3;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b1;
			rNextState = `STATE_POWERON_INIT_3;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_POWERON_INIT_3:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'h3;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_POWERON_INIT_4_A;
				end
			else
				rNextState = `STATE_POWERON_INIT_3;
		end
		
		//------------------------------------------
		/*
		Wait 100 us or longer, which is 5000 clock cycles at 50 MHz
		*/

		`STATE_POWERON_INIT_4_A:
		begin
			oLCD_Enabled = 1'b0;
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
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h3;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b1;
			rNextState = `STATE_POWERON_INIT_5;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_POWERON_INIT_5:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'h3;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_POWERON_INIT_6_A;
				end
			else
				rNextState = `STATE_POWERON_INIT_5;
		end
		
		//------------------------------------------
		/*
		Wait 40 us or longer, which is 2000 clock cycles at 50 MHz
		*/

		`STATE_POWERON_INIT_6_A:
		begin
			oLCD_Enabled = 1'b0;
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
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h2;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd3010 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_POWERON_INIT_7;
				end
			else
				rNextState = `STATE_POWERON_INIT_6_B;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_POWERON_INIT_7:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'h2;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_POWERON_INIT_8_A;
				end
			else
				rNextState = `STATE_POWERON_INIT_7;
		end
		
		//------------------------------------------
		/*
		Wait 40 us or longer, which is 2000 clock cycles at 50 MHz
		*/

		`STATE_POWERON_INIT_8_A:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h2;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd3000 )
				rNextState = `STATE_DISPLAY_INIT_0_A;
			else
				rNextState = `STATE_POWERON_INIT_8_A;
		end
		
		//------------------------------------------
		
		`STATE_DISPLAY_INIT_0_A:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h2;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd3010 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_0;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_0_A;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_DISPLAY_INIT_0:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'h2;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_1_A;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_0;
		end
		
		//------------------------------------------
		
		`STATE_DISPLAY_INIT_1_A:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h2;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd60 )
				rNextState = `STATE_DISPLAY_INIT_1_B;
			else
				rNextState = `STATE_DISPLAY_INIT_1_A;
		end
		
		//------------------------------------------
		
		`STATE_DISPLAY_INIT_1_B:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h8;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd70 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_1;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_1_B;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_DISPLAY_INIT_1:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'h8;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_2_A;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_1;
		end
		
		//------------------------------------------
		/*
		Wait 40 us or longer, which is 2000 clock cycles at 50 MHz
		*/

		`STATE_DISPLAY_INIT_2_A:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h8;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd3000 )
				rNextState = `STATE_DISPLAY_INIT_2_B;
			else
				rNextState = `STATE_DISPLAY_INIT_2_A;
		end
		
		//------------------------------------------
		
		`STATE_DISPLAY_INIT_2_B:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h0;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd3010 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_2;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_2_B;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_DISPLAY_INIT_2:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'h0;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_3_A;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_2;
		end
		
		//------------------------------------------
		
		`STATE_DISPLAY_INIT_3_A:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h0;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd60 )
				rNextState = `STATE_DISPLAY_INIT_3_B;
			else
				rNextState = `STATE_DISPLAY_INIT_3_A;
		end
		
		//------------------------------------------
		
		`STATE_DISPLAY_INIT_3_B:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h6;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd70 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_3;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_3_B;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_DISPLAY_INIT_3:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'h6;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_4_A;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_3;
		end
		
		//------------------------------------------
		/*
		Wait 40 us or longer, which is 2000 clock cycles at 50 MHz
		*/

		`STATE_DISPLAY_INIT_4_A:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h6;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd3000 )
				rNextState = `STATE_DISPLAY_INIT_4_B;
			else
				rNextState = `STATE_DISPLAY_INIT_4_A;
		end
		
		//------------------------------------------
		
		`STATE_DISPLAY_INIT_4_B:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h0;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd3010 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_4;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_4_B;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_DISPLAY_INIT_4:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'h0;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_5_A;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_4;
		end
		
		//------------------------------------------
		
		`STATE_DISPLAY_INIT_5_A:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h0;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd60 )
				rNextState = `STATE_DISPLAY_INIT_5_B;
			else
				rNextState = `STATE_DISPLAY_INIT_5_A;
		end
		
		//------------------------------------------
		
		`STATE_DISPLAY_INIT_5_B:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'hc;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd70 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_5;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_5_B;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_DISPLAY_INIT_5:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'hc;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_6_A;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_5;
		end
		
		//------------------------------------------
		/*
		Wait 40 us or longer, which is 2000 clock cycles at 50 MHz
		*/

		`STATE_DISPLAY_INIT_6_A:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'hc;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd3000 )
				rNextState = `STATE_DISPLAY_INIT_6_B;
			else
				rNextState = `STATE_DISPLAY_INIT_6_A;
		end
		
		//------------------------------------------
		
		`STATE_DISPLAY_INIT_6_B:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h0;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd3010 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_6;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_6_B;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_DISPLAY_INIT_6:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'h0;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_7_A;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_6;
		end
		
		//------------------------------------------
		
		`STATE_DISPLAY_INIT_7_A:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h0;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd60 )
				rNextState = `STATE_DISPLAY_INIT_7_B;
			else
				rNextState = `STATE_DISPLAY_INIT_7_A;
		end
		
		//------------------------------------------
		
		`STATE_DISPLAY_INIT_7_B:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h1;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd70 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_INIT_7;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_7_B;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_DISPLAY_INIT_7:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'h1;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_DISPLAY_FIN;
				end
			else
				rNextState = `STATE_DISPLAY_INIT_7;
		end
		
		//------------------------------------------
		
		`STATE_DISPLAY_FIN:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h1;
			oLCD_RegisterSelect = 1'b0; //these are commands
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd83000 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_UPPER_NIBBLE_0_A;
				end
			else
				rNextState = `STATE_DISPLAY_FIN;
		end
		
		//------------------------------------------
		
		`STATE_UPPER_NIBBLE_0_A:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'b0110;
			oLCD_RegisterSelect = 1'b1; //these are data
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd10 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_UPPER_NIBBLE_0;
				end
			else
				rNextState = `STATE_UPPER_NIBBLE_0_A;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_UPPER_NIBBLE_0:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'b0110;
			oLCD_RegisterSelect = 1'b1; //these are data
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_UPPER_NIBBLE_0_B;
				end
			else
				rNextState = `STATE_UPPER_NIBBLE_0;
		end
		
		//------------------------------------------
		
		`STATE_UPPER_NIBBLE_0_B:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'b0110;
			oLCD_RegisterSelect = 1'b1; //these are data
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd60 )
				rNextState = `STATE_LOWER_NIBBLE_0_A;
			else
				rNextState = `STATE_UPPER_NIBBLE_0_B;
		end
		
		//------------------------------------------
		
		`STATE_LOWER_NIBBLE_0_A:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'b0100;
			oLCD_RegisterSelect = 1'b1; //these are data
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd10 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_LOWER_NIBBLE_0;
				end
			else
				rNextState = `STATE_LOWER_NIBBLE_0_A;
		end
		
		//------------------------------------------
		/*
		Write SF_D<11:8> = 0x3, pulse LCD_E High for 12 clock cycles
		*/

		`STATE_LOWER_NIBBLE_0:
		begin
			oLCD_Enabled = 1'b1;
			oLCD_Data = 4'b0100;
			oLCD_RegisterSelect = 1'b1; //these are data
			rTimeCountReset = 1'b0;

			if ( rTimeCount > 32'd20 )
				begin
					rTimeCountReset = 1'b1;
					rNextState = `STATE_LOWER_NIBBLE_0_B;
				end
			else
				rNextState = `STATE_LOWER_NIBBLE_0;
		end
		
		//------------------------------------------
		/*
		Wait 40 us or longer, which is 2000 clock cycles at 50 MHz
		*/
		
		`STATE_LOWER_NIBBLE_0_B:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'b0100;
			oLCD_RegisterSelect = 1'b1; //these are data
			rTimeCountReset = 1'b0;
			
			if (rTimeCount > 32'd3000 )
				rNextState = `STATE_LOWER_NIBBLE_0_B;
			else
				rNextState = `STATE_LOWER_NIBBLE_0_B;
		end
		
		//------------------------------------------
		
		default:
		begin
			oLCD_Enabled = 1'b0;
			oLCD_Data = 4'h0;
			oLCD_RegisterSelect = 1'b0;
			rTimeCountReset = 1'b0;
			rNextState = `STATE_RESET;
		end

		//------------------------------------------
		endcase
	
	end

endmodule

