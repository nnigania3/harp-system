module mshr_dummy
( 
    input clk, enable, reset, 
     
    input add, 
    input [31:0] add_addr, 
	 input [31:0] add_data,
	 input add_rw, add_dirty, 
	 input [2:0] add_cpu_id, 
     
    input del, 
    input [31:0] del_addr, /* This can be MSHR id as well. I would prefer that*/ 
     
    input read_next, 
    output reg rn_valid, 
	 output reg [31:0] rn_addr, rn_data, 
	 output reg rn_rw, rn_dirty, 
	 output reg [2:0] rn_mshr_id, 
     
    input get, 
    input [31:0] get_addr, /* This can be MSHR id as well. I would prefer that*/ 
    output reg get_valid, get_rw, 
	 output reg [31:0] get_data,
	 output reg [2:0] get_cpu_id,
     
    output full, 
    output empty 
);

	always @ (posedge clk or negedge reset)
	begin
		if (!reset) begin
			rn_valid <= 1'b0;
			rn_addr <= 0;
			rn_data <= 0;
			rn_dirty <= 1'b0;
			rn_mshr_id <= 0;
		end
		else begin
			if (read_next) begin
				rn_valid <= 1'b1;
				rn_addr <= 100;
				rn_data <= 456;
				rn_dirty <= 1'b0;
				rn_mshr_id <= 0;
			end
		end
	end
	
endmodule
