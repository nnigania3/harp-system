module de3_display (clk, char, char_valid, disp1, disp2, led1);

input clk;
input char_valid;
input [6:0]char;
output [6:0]disp1;
output [6:0]disp2;
output led1;
reg  [6:0]char_store;
wire [3:0]bcd1;
wire [3:0]bcd2;

always@(posedge char_valid)
	char_store <= char;

assign led1 = char_store[0];
assign bcd1 = char_store[3:0];
assign bcd2 = {1'b0,char_store[6:4]};

seg7 display1(
	.bcd(bcd1), 
	.leds(disp1));

seg7 display2(
	.bcd(bcd2), 
	.leds(disp2));


endmodule
