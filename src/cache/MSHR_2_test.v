`timescale 1ns/100ps

module MSHR_2_test;
	
	parameter addr_bits=20;
	parameter data_bits = 90; 
	parameter mshr_tag_bits = 3; 
	parameter cpu_id_bits = 2;
	
	
	reg clk, enable, reset;                         
	
	reg add;
	reg [addr_bits-1:0] add_addr;
	reg [data_bits-1:0] add_data;
	reg add_rw, add_dirty; 
	reg [cpu_id_bits-1:0] add_cpu_id;
	
	reg del; 
	reg [mshr_tag_bits-1:0] del_tag;
	
	reg read_next;
	
	wire rn_valid;
	wire [addr_bits-1:0] rn_addr;
	wire [data_bits-1:0] rn_data;
	wire rn_rw;
	wire rn_dirty;
	wire [cpu_id_bits-1:0] rn_cpu_id;
	wire [mshr_tag_bits-1:0] rn_mshr_id;
	
	reg get;
	reg [mshr_tag_bits-1:0] get_tag;
	
	wire get_valid; 
	wire [addr_bits-1:0] get_addr;
	wire [data_bits-1:0] get_data; 
	wire get_dirty, get_rw;
	wire [cpu_id_bits-1:0] get_cpu_id;

	wire empty, full;
	
	MSHR_2 Thinggy
	(
		clk, enable, reset,
		
		add, add_addr, add_data, add_rw, add_dirty, add_cpu_id,
	
		del, del_tag,
	
		read_next,
		rn_valid, rn_addr, rn_data, rn_rw, rn_dirty, rn_cpu_id, rn_mshr_id,
	
		get, get_tag,
		get_valid, get_addr, get_data, get_rw, get_dirty, get_cpu_id,
	
		empty, full
	);
	
	always #5 clk = ~clk;

	initial begin
		clk = 1;
		enable = 0;
		reset = 0;
		
		add = 0;
		add_addr = 0;
		add_data = 0; 
		add_rw = 0;
		add_dirty = 0;
		add_cpu_id = 0;
		
		del = 0;
		del_tag = 0;
		
		read_next = 0;
		
		get = 0;
		get_tag = 0;	
	
	#15
		enable = 0;
		reset = 1;
		
		add = 0;
		add_addr = 0;
		add_data = 0; 
		add_rw = 0;
		add_dirty = 0;
		add_cpu_id = 0;
		
		del = 0;
		del_tag = 0;
		
		read_next = 0;
		
		get = 0;
		get_tag = 0;	
	
	#10
	                         //1st add
		enable = 1;
		reset = 0;
		
		add = 1;
		add_addr = 90;
		add_data = 100; 
		add_rw = 1;
		add_dirty = 0;
		add_cpu_id = 0;
		
		del = 0;
		del_tag = 0;
		
		read_next = 0;
		
		get = 0;
		get_tag = 0;	
		
	#10
	                         //2nd add
		enable = 1;
		reset = 0;
		
		add = 1;
		add_addr = 91;
		add_data = 101; 
		add_rw = 0;
		add_dirty = 1;
		add_cpu_id = 1;
		
		del = 0;
		del_tag = 0;
		
		read_next = 0;
		
		get = 0;
		get_tag = 0;	
			
		#10
	                         //3rd add and read
		enable = 1;
		reset = 0;
		
		add = 1;
		add_addr = 92;
		add_data = 102; 
		add_rw = 1;
		add_dirty = 0;
		add_cpu_id = 2;
		
		del = 0;
		del_tag = 0;
		
		read_next = 1;
		
		get = 0;
		get_tag = 0;
	

		#10
	                         //4th add and read
		enable = 1;
		reset = 0;
		
		add = 1;
		add_addr = 93;
		add_data = 103; 
		add_rw = 0;
		add_dirty = 1;
		add_cpu_id = 3;
		
		del = 0;
		del_tag = 0;
		
		read_next = 1;
		
		get = 0;
		get_tag = 0;
		
		#10
	                         //5th add and del (2nd) and  read
		enable = 1;
		reset = 0;
		
		add = 1;
		add_addr = 94;
		add_data = 104; 
		add_rw = 1;
		add_dirty = 0;
		add_cpu_id = 0;
		
		del = 1;
		del_tag = 1;
		
		read_next = 1;
		
		get = 0;
		get_tag = 0;
		
		#10
	                         //6th add and read
		enable = 1;
		reset = 0;
		
		add = 1;
		add_addr = 95;
		add_data = 105; 
		add_rw = 0;
		add_dirty = 1;
		add_cpu_id = 1;
		
		del = 0;
		del_tag = 0;
		
		read_next = 1;
		
		get = 0;
		get_tag = 0;
		
		#10
	                         //7th add and read
		enable = 1;
		reset = 0;
		
		add = 1;
		add_addr = 96;
		add_data = 106; 
		add_rw = 1;
		add_dirty = 0;
		add_cpu_id = 2;
		
		del = 0;
		del_tag = 0;
		
		read_next = 1;
		
		get = 0;
		get_tag = 0;
		
		#10
	                         //8th add
		enable = 1;
		reset = 0;
		
		add = 1;
		add_addr = 97;
		add_data = 107; 
		add_rw = 0;
		add_dirty = 1;
		add_cpu_id = 3;
		
		del = 0;
		del_tag = 0;
		
		read_next = 0;
		
		get = 0;
		get_tag = 0;
		
		#10
	                         //9th add (MSHR should become full)
		enable = 1;
		reset = 0;
		
		add = 1;
		add_addr = 98;
		add_data = 108; 
		add_rw = 0;
		add_dirty = 1;
		add_cpu_id = 3;
		
		del = 0;
		del_tag = 0;
		
		read_next = 0;
		
		get = 0;
		get_tag = 0;
		

		#10
	                         //del 1st
		enable = 1;
		reset = 0;
		
		add = 0;
		add_addr = 0;
		add_data = 0; 
		add_rw = 0;
		add_dirty = 0;
		add_cpu_id = 0;
		
		del = 1;
		del_tag = 0;
		
		read_next = 1;
		
		get = 0;
		get_tag = 0;

		#10
	                         //del 3rd
		enable = 1;
		reset = 0;
		
		add = 0;
		add_addr = 0;
		add_data = 0; 
		add_rw = 0;
		add_dirty = 0;
		add_cpu_id = 0;
		
		del = 1;
		del_tag = 2;
		
		read_next = 1;
		
		get = 0;
		get_tag = 0;
		
		#10
	                         //del 4th
		enable = 1;
		reset = 0;
		
		add = 0;
		add_addr = 0;
		add_data = 0; 
		add_rw = 0;
		add_dirty = 0;
		add_cpu_id = 0;
		
		del = 1;
		del_tag = 3;
		
		read_next = 1;
		
		get = 0;
		get_tag = 0;
		
		#10
	                         //del 5th
		enable = 1;
		reset = 0;
		
		add = 0;
		add_addr = 0;
		add_data = 0; 
		add_rw = 0;
		add_dirty = 0;
		add_cpu_id = 0;
		
		del = 1;
		del_tag = 4;
		
		read_next = 1;
		
		get = 0;
		get_tag = 0;
	
		#10
	                         //del 6th
		enable = 1;
		reset = 0;
		
		add = 0;
		add_addr = 0;
		add_data = 0; 
		add_rw = 0;
		add_dirty = 0;
		add_cpu_id = 0;
		
		del = 1;
		del_tag = 5;
		
		read_next = 1;
		
		get = 0;
		get_tag = 0;
	
		#10
	                         //del 7th
		enable = 1;
		reset = 0;
		
		add = 0;
		add_addr = 0;
		add_data = 0; 
		add_rw = 0;
		add_dirty = 0;
		add_cpu_id = 0;
		
		del = 1;
		del_tag = 6;
		
		read_next = 0;
		
		get = 0;
		get_tag = 0;
		
		#10
	                         //del 8th
		enable = 1;
		reset = 0;
		
		add = 0;
		add_addr = 0;
		add_data = 0; 
		add_rw = 0;
		add_dirty = 0;
		add_cpu_id = 0;
		
		del = 1;
		del_tag = 7;
		
		read_next = 0;
		
		get = 0;
		get_tag = 0;
		
		#10
		
		$finish;
		
	end
	
	
endmodule
	
	
	