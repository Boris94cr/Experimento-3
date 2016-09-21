`timescale 1ns / 1ps

module testbench;
 
	reg Clock;
	reg Reset;
	wire oLCD_Enabled;
	wire oLCD_RegisterSelect;
	wire oLCD_StrataFlashControl;
	wire oLCD_ReadWrite;
	wire [3:0]oLCD_Data;
	
	always
	#10 Clock = ~Clock;
	
	initial
		begin
			Clock = 0;
			Reset = 1;
			#50 Reset = 0;
		end
		
	Module_LCD_Control LCD (
		.Clock(Clock),
		.Reset(Reset),
		.oLCD_Enabled(oLCD_Enabled),
		.oLCD_RegisterSelect(oLCD_RegisterSelect), //0=Command, 1=Data
		.oLCD_StrataFlashControl(oLCD_StrataFlashControl),
		.oLCD_ReadWrite(oLCD_ReadWrite),
		.oLCD_Data(oLCD_Data)
	);
	
endmodule