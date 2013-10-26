module blinker (clk, led1);

input clk;
output led1;
reg [29:0] count;


  initial
    begin
	count <= 0;
    end
always@(posedge clk)
	count <= count + 1;

assign led1 = (count < 30'd500000000) ? 1 : 0 ;

endmodule
