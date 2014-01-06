module nonblocking_fsm_L1
(
    input reset,
    input clock,
         
    input dirty,
    input rw_prev,
    input stall_l2,
    input done_l2,
    input mshr_empty,
    input block,
    input same_line,
    input prev_read,
       
    output reg rw_l2,
    output reg valid_l2,
    output reg we_b,
    output reg rd_valid_b,
    output reg l2_addr_en,
    output reg mshr_read_next,
    output reg mshr_get, 
    output reg mshr_del, 
    output reg stall_out,
    output reg stall_out_d,
    output reg block_stall
);
    localparam L2_CLK_DIV = 1;
    localparam MAX_COUNT = 2**(L2_CLK_DIV+1)-1;
	 
    reg reg_rw_l2;
    reg reg_valid_l2;
    reg reg_we_b;
    reg reg_rd_valid_b;
    reg reg_l2_addr_en;
    reg reg_stall_proc;
    reg reg_stall_proc_d;
    reg reg_block_stall;
    reg reg_mshr_read_next;
    reg reg_mshr_get; 
    reg reg_mshr_del;
	 
    reg [8:0] fstate;
    reg [8:0] reg_fstate;
    parameter IDLE=1, READ_NEXT=2, READ_L2=4, WB_L2=8, READ_WAIT=16, L2_COMPLETE=32, WB_L2_WAIT=64, BLOCK_STATE=128;
    reg [8:0] prev_state;
    reg [8:0] reg_prev_state;
	 
    reg [L2_CLK_DIV:0] count;
    reg count_start;
    reg flag, reg_flag;
    reg same_pending, reg_same_pending; //NN check, all same_pending signal!
    reg diff_line_done, reg_diff_line_done; //NN check, all same_pending signal!
    reg wb_pending, reg_wb_pending;
    wire valid_l2_nack;
    assign valid_l2_nack = stall_l2 & valid_l2 & (!rw_l2);//|!(done_l2 | flag)

    initial
    begin
        reg_rw_l2 <= 1'b0;
        reg_valid_l2 <= 1'b0;
        reg_we_b <= 1'b0;
        reg_rd_valid_b <= 1'b0;
        reg_l2_addr_en <= 1'b0;
        reg_stall_proc <= 1'b0;
        reg_stall_proc_d <= 1'b0;
        reg_block_stall <= 1'b0;
        reg_mshr_read_next <= 1'b0;
        reg_mshr_get <= 1'b0; 
        reg_mshr_del <= 1'b0;
        reg_wb_pending <= 1'b0;
    end
	 
    always @(posedge clock or negedge reset)
    begin
        if (~reset) begin
            flag <= 1'b0;
            fstate <= IDLE;
            prev_state <= IDLE;
            rw_l2 <= 1'b0;
            valid_l2 <= 1'b0;
            we_b <= 1'b0;
            rd_valid_b <= 1'b0;
            l2_addr_en <= 1'b0;
            stall_out <= 1'b0;
            stall_out_d <= 1'b0;
            block_stall <= 1'b0;
            mshr_read_next <= 1'b0;
            mshr_get <= 1'b0; 
            mshr_del <= 1'b0;
            wb_pending <= 1'b0;
            same_pending <= 1'b0;
            diff_line_done <= 1'b0;
        end
        else begin
            flag <= reg_flag;
            fstate <= reg_fstate;
            prev_state <= reg_prev_state;
            rw_l2 <= reg_rw_l2;
            valid_l2 <= reg_valid_l2 | valid_l2_nack;
            we_b <= reg_we_b;
            rd_valid_b <= reg_rd_valid_b;
            l2_addr_en <= reg_l2_addr_en;
            stall_out <= reg_stall_proc;
            stall_out_d <= reg_stall_proc_d;
            block_stall <= reg_block_stall;
            mshr_read_next <= reg_mshr_read_next;
            mshr_get <= reg_mshr_get; 
            mshr_del <= reg_mshr_del; 
            same_pending <= reg_same_pending; 
            diff_line_done <= reg_diff_line_done; 
            wb_pending <= reg_wb_pending;
        end
    end
	 
    always @(posedge clock or negedge reset)
    begin
        if (~reset) begin
            count <= 0;
        end
        else if (count_start)
            count <= 1;
        else if (count == 2*L2_CLK_DIV && stall_l2)
            count <= count;
        else if (count<MAX_COUNT)
            count <= count+1;
    end

    always @ *
    begin
        reg_rw_l2 <= 1'b0;
        reg_valid_l2 <= 1'b0;
        reg_we_b <= 1'b0;
        reg_rd_valid_b <= 1'b0;
        reg_l2_addr_en <= 1'b0;
        reg_stall_proc <= 1'b0;
        reg_stall_proc_d <= 1'b0;
        reg_block_stall <= 1'b0;
        reg_mshr_read_next <= 1'b0;
        reg_mshr_get <= 1'b0; 
        reg_mshr_del <= 1'b0; 
        count_start <= 1'b0;
        reg_prev_state <= IDLE;
        reg_flag <= 1'b0;
        reg_same_pending <= 1'b0;
        reg_diff_line_done <= 1'b0;
        reg_fstate <= IDLE;
        reg_wb_pending   <= 1'b0;

        case (fstate)
				IDLE: begin
					if (done_l2 | flag) begin
						reg_flag <= 1'b0;
						reg_fstate <= L2_COMPLETE;
						//reg_prev_state <= IDLE;
						reg_prev_state <= (block & prev_read) ? BLOCK_STATE : IDLE;
						reg_block_stall <= (block & prev_read)? 1'b1:1'b0;
						reg_stall_proc <= 1'b1;
						reg_we_b <= 1'b1;
						reg_valid_l2 <= 1'b0;
						reg_mshr_get <= 1'b1;
					end
					else if (block & prev_read) begin
						reg_fstate <= BLOCK_STATE;
						reg_block_stall <= 1'b1;
					end		
					else if (~stall_l2 & ~done_l2 & ~mshr_empty) begin
						reg_mshr_read_next <= 1'b1;
						reg_fstate <= READ_NEXT;
					end
					else begin
						reg_fstate <= IDLE;
					end
				end

				BLOCK_STATE: begin
					if (~block) begin
						reg_fstate <= IDLE;
						if (same_line | same_pending)
							reg_stall_proc_d <= 1'b1;
							reg_block_stall <= 1'b0;
						if (done_l2 | flag)
							reg_flag <= 1'b1;
					end
					else if (done_l2 | flag) begin
						reg_block_stall <= 1'b1;
						reg_flag <= 1'b0;
						reg_fstate <= L2_COMPLETE;
						reg_prev_state <= BLOCK_STATE;
		                                reg_same_pending <= (same_line) ? 1'b1 : 1'b0;
		                                reg_diff_line_done <= (diff_line_done) ? 1'b1 : 1'b0;
						reg_stall_proc <= 1'b1;
						reg_we_b <= 1'b1;
						reg_valid_l2 <= 1'b0;
						reg_mshr_get <= 1'b1;
					end
					else begin
						reg_fstate <= diff_line_done? IDLE : BLOCK_STATE;
						reg_block_stall <= 1'b1;
					end
				end

				READ_NEXT: begin
					if (done_l2 | flag) begin
				/*		reg_flag <= 1'b1;*/
						reg_fstate <= L2_COMPLETE;
						reg_prev_state <= READ_NEXT;
						reg_stall_proc <= 1'b1;
						reg_we_b <= 1'b1;
						reg_valid_l2 <= 1'b0;
						reg_mshr_get <= 1'b1;
				
					end 
                                        else begin
						reg_mshr_read_next <= 1'b0;
						reg_fstate <= READ_WAIT;
					end 
				end
				READ_WAIT: begin
					if (done_l2 | flag) begin
						reg_flag <= 1'b1;
				/*		reg_fstate <= L2_COMPLETE;
						reg_prev_state <= READ_WAIT;
						reg_stall_proc <= 1'b1;
						reg_we_b <= 1'b1;
						reg_valid_l2 <= 1'b0;
						reg_mshr_get <= 1'b1;
				*/	end 
					if (dirty) begin
						reg_fstate <= WB_L2_WAIT;
						reg_prev_state <= READ_WAIT;
						reg_rd_valid_b <= 1'b1;
						reg_we_b <= 1'b0;
						reg_valid_l2 <= 1'b1;
						reg_l2_addr_en <= 1'b1;
						reg_rw_l2 <= 1'b1;
						count_start <= 1'b1;
						reg_wb_pending <= 1'b0;
					end
					else begin
						reg_fstate <= IDLE;
						//reg_we_b <= 1'b0; //NN check
						reg_we_b <= 1'b1;
						reg_valid_l2 <= 1'b1;
						reg_l2_addr_en <= 1'b0;
						reg_rw_l2 <= 1'b0;
					end			
				end

				L2_COMPLETE: begin
					if (prev_state==BLOCK_STATE) begin
						reg_block_stall <= 1'b1;
		                                reg_same_pending <= (same_line | same_pending) ? 1'b1 : 1'b0;
						reg_diff_line_done<= (~block|diff_line_done) ? 1'b1:1'b0;
					end else if ((prev_state==WB_L2_WAIT)&(wb_pending))begin
						reg_wb_pending <= 1'b1;
					end
					reg_fstate <= prev_state; 
					reg_mshr_del <= 1'b1;
					reg_stall_proc_d <= 1'b1;
					if (done_l2) begin
						reg_fstate <= L2_COMPLETE;
						reg_prev_state <= prev_state;
						reg_stall_proc <= 1'b1;
						reg_we_b <= 1'b1;
						reg_valid_l2 <= 1'b0;
						reg_mshr_get <= 1'b1;
					end
				end

				READ_L2: begin		
					if (done_l2 | flag) begin
						reg_fstate <= L2_COMPLETE;
						reg_prev_state <= READ_L2;
						reg_stall_proc <= 1'b1;
						reg_we_b <= 1'b1;
						reg_valid_l2 <= 1'b0;
						reg_mshr_get <= 1'b1;
					end 
					else begin	
						reg_fstate <= IDLE;
						//reg_we_b <= 1'b0; //NN check
						reg_we_b <= 1'b1;
						reg_valid_l2 <= 1'b1;
						reg_l2_addr_en <= 1'b0;
						reg_rw_l2 <= 1'b0;
					end
				end

				WB_L2: begin//NN check, remove it?not used!
				end

				WB_L2_WAIT: begin
					if (prev_state==READ_WAIT) begin
						if (stall_l2 & valid_l2)
						   reg_wb_pending <= 1'b1;
						else
						   reg_wb_pending <= 1'b0;
					end else if(wb_pending) begin
						   reg_wb_pending <= 1'b1;
					end

					if (done_l2 | flag) begin
						reg_flag <= 1'b0;
						reg_fstate <= L2_COMPLETE;
						reg_prev_state <= WB_L2_WAIT;
						reg_stall_proc <= 1'b1;
						reg_we_b <= 1'b1;
						reg_valid_l2 <= 1'b0;
						reg_mshr_get <= 1'b1;
					end
					else if (((prev_state==READ_WAIT)&stall_l2&valid_l2) |wb_pending) begin
						reg_fstate <= READ_WAIT;
					end
					else if (count == 1) begin
						count_start <= 1'b0;
						reg_fstate <= WB_L2_WAIT;
					end
					else if (count == 2*L2_CLK_DIV+1)
						reg_fstate <= READ_L2;
					else
						reg_fstate <= WB_L2_WAIT;
						reg_rd_valid_b <= 1'b1;
						reg_valid_l2 <= 1'b0;
						reg_l2_addr_en <= 1'b1;
				end

				default: begin
					reg_flag <= 1'b0;
					reg_rw_l2 <= 1'bx;
					reg_valid_l2 <= 1'bx;
					reg_we_b <= 1'bx;
					reg_rd_valid_b <= 1'bx;
					reg_l2_addr_en <= 1'bx;
					reg_stall_proc <= 1'bx;
					reg_stall_proc_d <= 1'bx;
					reg_mshr_read_next <= 1'bx;
					reg_mshr_get <= 1'bx; 
					reg_mshr_del <= 1'bx;
		                	reg_same_pending <= 1'b0;
		                	reg_diff_line_done <= 1'b0;
                                        reg_wb_pending   <= 1'b0;
        				reg_fstate <= IDLE;
					$display ("Reach undefined state at time %t", $time);
				end
        endcase
    end
endmodule // blocking
