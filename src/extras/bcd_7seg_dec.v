module seg7 (bcd, leds);
	input [3:0] bcd;
	output [6:0] leds;
	reg [6:0] led;
	
	assign leds = ~led;

	always @(bcd)
		case (bcd)       //abcdefg
			0:  led = 7'b0111111;
	   		1:  led = 7'b0000110;
			2:  led = 7'b1011011;
			3:  led = 7'b1001111;
			4:  led = 7'b1100110;
			5:  led = 7'b1101101;
			6:  led = 7'b1111101;
			7:  led = 7'b0000111;
			8:  led = 7'b1111111;
			9:  led = 7'b1101111;
			10: led = 7'b1110111;	//A
			11: led = 7'b1111100;	//B 
			12: led = 7'b0111001;	//C 
			13: led = 7'b1011110;	//D
			14: led = 7'b1111001;	//E
			15: led = 7'b1110001;	//F
			default: led = 7'bx;
		endcase

		
endmodule
