module data_array
#(parameter DATA_WIDTH=32, parameter INDEX_WIDTH=9, parameter WORD_BITS = 3)
(
	input [DATA_WIDTH-1:0] data_a, 
	input [DATA_WIDTH*(2**WORD_BITS)-1:0] data_b,
	input [INDEX_WIDTH-1:0] addr_a, 
	input [INDEX_WIDTH-1:0] addr_b,
	input [WORD_BITS-1:0] word_a, //word_b,
	input we_a, we_b, clk,
	output reg [DATA_WIDTH-1:0] q_a,
	output reg [DATA_WIDTH*(2**WORD_BITS)-1:0] q_b
);

	reg [DATA_WIDTH-1:0] data_reg_a;
	reg [DATA_WIDTH*(2**WORD_BITS)-1:0] data_reg_b;
	
//	wire [DATA_WIDTH*8-1:0] ram_a_out;
//	wire [DATA_WIDTH*8-1:0] ram_b_out;
//	wire [DATA_WIDTH*8-1:0] ram_a_in;
//	wire [DATA_WIDTH*8-1:0] ram_b_in;
	
	// Declare the RAM variable
	reg [(2**WORD_BITS)-1:0][DATA_WIDTH-1:0] ram [(2**INDEX_WIDTH-1):0];

//	GenericMux #(32,3) G1 (ram_a_out, word_a, q_a);
//	GenericMux #(32,3) G2 (ram_b_out, word_b, q_b);
		
	// Port A 
	always @ (posedge clk)
	begin
		if (we_a) 
		begin
			ram[word_a][addr_a] <= data_a;
			data_reg_a <= data_a;
		end
		else 
		begin
			data_reg_a <= ram[word_a][addr_a];
		end 
	end 
	assign q_a = data_reg_a;

	// Port B 
	always @ (posedge clk)
	begin
		if (we_b) 
		begin
			ram[addr_b] <= data_b;
			data_reg_b <= data_b;
		end
		else 
		begin
			data_reg_b <= ram[addr_b];
		end 
	end
	assign q_b = data_reg_b;
	
endmodule
/*
//module mixed_width_true_dual_port_ram_new_rw
	#(parameter int
		DATA_WIDTH1 = 8,
		ADDRESS_WIDTH1 = 10,
		ADDRESS_WIDTH2 = 8)
(
		input [ADDRESS_WIDTH1-1:0] addr_a,
		input [ADDRESS_WIDTH2-1:0] addr_b,
		input [DATA_WIDTH1      -1:0] data_a, 
		input [DATA_WIDTH1*(1<<(ADDRESS_WIDTH1 - ADDRESS_WIDTH2))-1:0] data_b, 
		input we_a, we_b, clk,
		output reg [DATA_WIDTH1-1      :0] q_a,
		output reg [DATA_WIDTH1*(1<<(ADDRESS_WIDTH1 - ADDRESS_WIDTH2))-1:0] q_b);
    
	localparam RATIO = 1 << (ADDRESS_WIDTH1 - ADDRESS_WIDTH2); // valid values are 2,4,8... family dependent
	localparam DATA_WIDTH2 = DATA_WIDTH1 * RATIO;
	localparam RAM_DEPTH = 1 << ADDRESS_WIDTH2;

	// Use a multi-dimensional packed array to model the different read/ram width
	reg [RATIO-1:0] [DATA_WIDTH1-1:0] ram[0:RAM_DEPTH-1];
    
	reg [DATA_WIDTH1-1:0] data_reg1;
	reg [DATA_WIDTH2-1:0] data_reg2;

	// Port A
	always@(posedge clk)
	begin
		if(we_a) 
		begin 
			ram[addr_a / RATIO][addr_a % RATIO] <= data_a;
	//		data_reg1 <= ram[addr_a / RATIO][addr_a % RATIO];
		end
		else
		begin 
			data_reg1 <= ram[addr_a / RATIO][addr_a % RATIO];
		end
	end
	assign q_a = data_reg1;

	// port B
	always@(posedge clk)
	begin
		if(we_b)
		begin
			ram[addr_b] <= data_b;
	//		data_reg2 <= ram[addr_b];
		end
		else
		begin
			data_reg2 <= ram[addr_b];
		end
	end
    
	assign q_b = data_reg2;
endmodule
*/