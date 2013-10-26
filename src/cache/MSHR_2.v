module MSHR_2
#(parameter addr_bits=20, parameter data_bits = 90, parameter mshr_tag_bits = 3, parameter cpu_id_bits = 2, parameter ASSOC_BITS=2, parameter LINE_BITS=5, parameter INDEX_BITS=9)
(
	clk, enable, reset,
	
	add, add_addr, add_data, add_rw, add_dirty, add_cpu_id, add_victim,
	
	del, del_tag,
	
	read_next,
	rn_valid, rn_addr, rn_data, rn_rw, rn_dirty, rn_cpu_id, rn_mshr_id, rn_victim,
	
	get, get_tag,
	get_valid, get_addr, get_data, get_rw, get_dirty, get_cpu_id, get_victim,
	
	comp_addr, comp_victim,
	comp_true, diff_line_true, same_line_true, comp_read, 
	
	empty, full
);

	input clk, enable, reset;                         //These inputs and outputs are hopefully mostly self-explanatory
	
	input add;
	input [addr_bits-1:0] add_addr;
	input [data_bits-1:0] add_data;
	input add_rw, add_dirty; 
	input [cpu_id_bits-1:0] add_cpu_id;
	input [ASSOC_BITS-1:0] add_victim;
	
	input del; 
	input [mshr_tag_bits-1:0] del_tag;
	
	input read_next;
	
	output rn_valid;
	output [addr_bits-1:0] rn_addr;
	output [data_bits-1:0] rn_data;
	output rn_rw;
	output rn_dirty;
	output [cpu_id_bits-1:0] rn_cpu_id;
	output [mshr_tag_bits-1:0] rn_mshr_id;
	output [ASSOC_BITS-1:0] rn_victim;
	
	input get;
	input [mshr_tag_bits-1:0] get_tag;
	
	output get_valid; 
	output [addr_bits-1:0] get_addr;
	output [data_bits-1:0] get_data; 
	output get_dirty, get_rw;
	output [cpu_id_bits-1:0] get_cpu_id;
	output [ASSOC_BITS-1:0] get_victim;

	input [addr_bits-1:0] comp_addr;
	input [ASSOC_BITS-1:0] comp_victim;
	output comp_true;
	output comp_read;
	output same_line_true;
	output diff_line_true;
	
	output empty, full;
	
	//Next we need to defien where the actual MSHR information is stored
	
	reg val [0:2**mshr_tag_bits-1];
	reg [addr_bits-1:0] addr [0:2**mshr_tag_bits-1];
	reg [data_bits-1:0] data [0:2**mshr_tag_bits-1];
	reg rw [0:2**mshr_tag_bits-1];	
	reg dirty [0:2**mshr_tag_bits-1];
	reg [cpu_id_bits-1:0] cpu_id [0:2**mshr_tag_bits-1];
	reg [ASSOC_BITS-1:0] victim [0:2**mshr_tag_bits-1];
	reg read [0:2**mshr_tag_bits-1];    //This signal is to see which entries have been read. I don't think we need this but I pout this in temporarilly 
		
	
	//Next we need to define the internal signals and wires
	reg [mshr_tag_bits:0] entries_read;    //This keeps track of the number of entries read 
	reg [mshr_tag_bits:0] occupied_spaces;   //This keeps track of the number of entries actually in the 	
	
	wire [mshr_tag_bits-1:0] next_free_reg_tag;  //This wire defines the next avaiable entry in the MSHR. Its a direct output from the free list.
	wire has_free_space; //This wire defines if there is atleast one free entry int eh MSHR (>=1 entry in the free_list_FIFO)
	
	//These are the signals I use to filter the input function signals (i.e. I don't want to read if all the entries have been read, etc.). Ideally these impossible adds, deletes, or reads should regulated in the scheduler but this is an extra layer of protection
	reg add_entry_signal;
	reg del_entry_signal;
	reg read_entry_signal;
	
	wire [mshr_tag_bits:0] One;
	assign One = {{mshr_tag_bits-1{1'b0}}, 1'b1};
	
	fill_list_shift_register #(.tag_bits(mshr_tag_bits)) Fill_List (.clk(clk), .enable(enable), .reset(reset), .add(add_entry_signal), .add_tag(next_free_reg_tag), .del(del_entry_signal), .del_tag(del_tag), .read(read_entry_signal), .valid_out(rn_valid), .tag_out(rn_mshr_id));
	
	free_list_FIFO #(.tag_bits(mshr_tag_bits)) Free_List (.clk(clk), .enable(enable), .reset(reset), .push(del_entry_signal), .push_tag(del_tag), .pop(add_entry_signal), .free_tag(next_free_reg_tag), .free_tag_valid(has_free_space));
	

	
	always @ * begin
		if ((add == 1'b1) && (occupied_spaces < 2**mshr_tag_bits) && (has_free_space))begin
			add_entry_signal = 1'b1;
		end else begin
			add_entry_signal = 1'b0;
		end
		
		if ((del == 1'b1) && (occupied_spaces > 0))begin
			del_entry_signal = 1'b1;
		end else begin
			del_entry_signal = 1'b0;
		end

		if ((read_next == 1'b1) && (occupied_spaces > entries_read))begin
			read_entry_signal = 1'b1;
		end else begin
			read_entry_signal = 1'b0;
		end	
	end
	
	
	
	
	integer xx;
	// Shift everything over, load the incoming bit
	always @ (posedge clk or negedge reset)
	begin
		if (!reset)
		begin
			entries_read <= 0;
			occupied_spaces <= 0;
			for(xx=0; xx<2**mshr_tag_bits; xx=xx+1) begin
				val[xx] <= 0;
				addr[xx] <= 0;
				data[xx] <= 0;
				rw[xx] <= 0;
				dirty[xx] <= 0;
				cpu_id[xx] <= 0;
				victim[xx] <= 0;
				read[xx] <= 0;
			end
		end
		else if (enable == 1'b1)
		begin
			if(add_entry_signal == 1)begin                         //This if statement adds all the input info to the MSHR memory
				val[next_free_reg_tag] <= 1;
				addr[next_free_reg_tag] <= add_addr;
				data[next_free_reg_tag] <= add_data;
				rw[next_free_reg_tag] <= add_rw;
				dirty[next_free_reg_tag] <= add_dirty;
				cpu_id[next_free_reg_tag] <= add_cpu_id;
				victim[next_free_reg_tag] <= add_victim;
				read[next_free_reg_tag] <= 0;
			end
			if(del_entry_signal == 1'b1)begin 							//This if statement deletes all the info from the MSHR memory
				val[del_tag] <= 0;
				addr[del_tag] <= 0;
				data[del_tag] <= 0;
				rw[del_tag] <= 0;
				dirty[del_tag] <= 0;
				cpu_id[del_tag] <= 0;
				victim[del_tag] <= 0;
				read[del_tag] <= 0;
			end
			if(rn_valid)begin										//This if statement makes that a particular MSHR entry has been read
				read[rn_mshr_id] <= 1;
			end
			
			
			if((add_entry_signal == 1'b1)&&(del_entry_signal == 1'b0))begin                      //We cal;culate the number fo occupied spaces based on the number of entries added/deleted
				occupied_spaces <= occupied_spaces+One;
			end 
			else if ((add_entry_signal == 1'b0)&&(del_entry_signal == 1'b1)) begin
				occupied_spaces <= occupied_spaces-One;
			end
			else begin
				occupied_spaces <= occupied_spaces;
			end
			
			if((read_entry_signal == 1'b1)&&(del_entry_signal == 1'b0))begin                      //Calulate the number fo entries read based on the enumber of entries read & deleted
				entries_read <= entries_read+One;                                                     //IMPORTANT: Calculations always assume an entry is read before it is deleted
			end 
			else if ((read_entry_signal == 1'b0)&&(del_entry_signal == 1'b1)) begin
				entries_read <= entries_read-One;
			end
			else begin
				entries_read <= entries_read;
			end
			
		end
	end

	//Next all we need to do is assign all the output values
	//add and del have no outputs

	//READ    
	assign rn_addr = addr[rn_mshr_id];
	assign rn_data = data[rn_mshr_id];
	assign rn_rw = rw[rn_mshr_id];
	assign rn_dirty = dirty[rn_mshr_id];
	assign rn_cpu_id = cpu_id[rn_mshr_id];
	assign rn_victim = victim[rn_mshr_id];
	//rememebr the mshr_tag and valid is outputted from the free_list_FIFO
	
	//GET
	assign get_addr = get ? addr[get_tag] : 0;
	assign get_data = get ? data[get_tag] : 0;
	assign get_rw = get ? rw[get_tag] : 1'b0;
	assign get_dirty = get ? dirty[get_tag] : 1'b0;
	assign get_cpu_id = get ? cpu_id[get_tag] : 0;
	assign get_valid = get ? val[get_tag] : 1'b0;
	assign get_victim = get ? victim[get_tag] : 0;
	
	integer i;
		
	reg [mshr_tag_bits-1:0] temp;
	reg [2**mshr_tag_bits-1:0] comp, comp2;
//	wire comp_temp, comp_temp2;
	always @* begin
		for (i=0; i<2**mshr_tag_bits; i=i+1) begin
	//		temp = addr[i];
			comp2[i] <= (val[i]) & (addr[i][LINE_BITS+INDEX_BITS:LINE_BITS] == comp_addr[LINE_BITS+INDEX_BITS:LINE_BITS]) & (victim[i] == comp_victim);
			if ((val[i]) & (addr[i][LINE_BITS+INDEX_BITS:LINE_BITS] == comp_addr[LINE_BITS+INDEX_BITS:LINE_BITS]) & (victim[i] == comp_victim))
				temp <= i;
			comp[i] <= (val[i]) & (addr[i][addr_bits-1:LINE_BITS] == comp_addr[addr_bits-1:LINE_BITS]);
			if ((val[i]) & (addr[i][addr_bits-1:LINE_BITS] == comp_addr[addr_bits-1:LINE_BITS]))
				temp <= i;
		end
	end
//	assign comp_temp2 = |comp2;
//	assign comp_temp = |comp;
	assign diff_line_true = |comp2;
	assign same_line_true = |comp;
	assign comp_true = same_line_true | diff_line_true;
	
	reg [mshr_tag_bits-1:0] comp_read_tag;
	always@ (posedge clk or negedge reset)
	begin
		if (!reset)
			comp_read_tag <= 0;
		else if (comp_true)
			comp_read_tag <= temp;
	end
	assign comp_read = read[comp_read_tag];
	
	//Finally we assing the empty and full signals. The occupied spaces variable is used to generate these signals  
	assign empty = (entries_read >= occupied_spaces)?1'b1:1'b0;
	assign full = (occupied_spaces == 2**mshr_tag_bits)?1'b1:1'b0;

endmodule
