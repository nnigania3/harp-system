module de3_display_new (clk, char, char_valid, disp1, disp2, led1);

input clk;
input char_valid;
input [31:0]char;
output [6:0]disp1;
output [6:0]disp2;
output led1;
reg  [31:0]char_store;
reg [3:0]bcd1;
wire [3:0]bcd2;

always@(posedge clk) begin
		if( char_valid == 1'b1 )
			char_store <= char;
end

reg [2:0]hex_id;	//32/4 =8


`ifdef DUMMY_MEM	//When doing RLT simulations, count and display hex digits fast
reg [4:0] count;
`else
reg [26:0] count;
`endif

initial begin
  count  <= 0;
  hex_id <= 0;
end

always@(posedge clk)begin
  count <= count + 1;
  if((char_valid == 1'b1) && (count == 0))
     hex_id <= hex_id + 3'b1; 
end

always@(hex_id, char_store)begin
   case (hex_id)
      0: bcd1 =  char_store[3:0];
      1: bcd1 =  char_store[7:4];
      2: bcd1 =  char_store[11:8];
      3: bcd1 =  char_store[15:12];
      4: bcd1 =  char_store[19:16];
      5: bcd1 =  char_store[23:20];
      6: bcd1 =  char_store[27:24];
      7: bcd1 =  char_store[31:28];
      default: bcd1 = 4'bx;
   endcase
end

assign led1 = char_valid;
assign bcd2 = {1'b0,hex_id};

seg7 display1(
	.bcd(bcd1), 
	.leds(disp1));

seg7 display2(
	.bcd(bcd2), 
	.leds(disp2));

endmodule
