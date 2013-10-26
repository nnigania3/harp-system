module blocking_fsm_L2
(
    input reset,
    input clock,
    input dirty,
    input rw_prev,
    input stall_l2,
    input done_l2,
    input miss,
    output reg rw_l2,
    output reg valid_l2,
    output reg we_b,
    output reg rd_valid_b,
    output reg l2_addr_en,
    output reg stall_out,
	 output reg stall_out_d
);

	 reg reg_rw_l2;
    reg reg_valid_l2;
    reg reg_we_b;
    reg reg_rd_valid_b;
    reg reg_l2_addr_en;
    reg reg_stall_proc;
	 
    reg [5:0] fstate;
    reg [5:0] reg_fstate;
    parameter Idle=0, Read_L2=1, WB_L2=2, WB_L2_Wait=3, Read_L1=4, Write_L1=5, Read_Wait=6;

    initial
    begin
        reg_rw_l2 <= 1'b0;
        reg_valid_l2 <= 1'b0;
        reg_we_b <= 1'b0;
        reg_rd_valid_b <= 1'b0;
        reg_l2_addr_en <= 1'b0;
        reg_stall_proc <= 1'b0;
    end
	 
	 always @ (posedge clock or negedge reset) begin
		if (!reset) begin
			stall_out_d <= 1'b0;
		end
		else begin
			stall_out_d <= stall_out;
		end
	end

    always @(posedge clock or negedge reset)
    begin
        if (~reset) begin
            fstate <= Idle;
            rw_l2 <= 1'b0;
            valid_l2 <= 1'b0;
            we_b <= 1'b0;
            rd_valid_b <= 1'b0;
            l2_addr_en <= 1'b0;
            stall_out <= 1'b0;
        end
        else begin
            fstate <= reg_fstate;
            rw_l2 <= reg_rw_l2;
            valid_l2 <= reg_valid_l2;
            we_b <= reg_we_b;
            rd_valid_b <= reg_rd_valid_b;
            l2_addr_en <= reg_l2_addr_en;
            stall_out <= reg_stall_proc;
        end
    end
	 
/*	 reg [3:0] count;
	 
	 always @(posedge clock or negedge reset)
    begin
        if (~reset) begin
				count <= 0;
		  end
		  else if (count_start)
				count <= 1;
		  else
				count <= count+1;
	 end
*/
    always @(fstate or dirty or rw_prev or stall_l2 or done_l2 or miss)
    begin
        reg_rw_l2 <= 1'b0;
        reg_valid_l2 <= 1'b0;
        reg_we_b <= 1'b0;
        reg_rd_valid_b <= 1'b0;
        reg_l2_addr_en <= 1'b0;
        reg_stall_proc <= 1'b0;
        case (fstate)
            Idle: begin
                if (((miss & dirty) & ~(stall_l2)))
                    reg_fstate <= WB_L2;
                else if (((miss & ~(dirty)) & ~(stall_l2)))
                    reg_fstate <= Read_L2;
                // Inserting 'else' block to prevent latch inference
                else
                    reg_fstate <= Idle;
                reg_rd_valid_b <= 1'b0;
                reg_stall_proc <= 1'b0;
                reg_we_b <= 1'b0;
                reg_valid_l2 <= 1'b0;
                reg_l2_addr_en <= 1'b0;
                reg_rw_l2 <= 1'b0;
            end
            Read_L2: begin
                reg_fstate <= Read_Wait;
                reg_stall_proc <= 1'b0;
                reg_we_b <= 1'b0;
                reg_valid_l2 <= 1'b1;
                reg_l2_addr_en <= 1'b0;
                reg_rw_l2 <= 1'b0;
            end
            WB_L2: begin
                reg_fstate <= Read_L2;
                reg_rd_valid_b <= 1'b1;
                reg_stall_proc <= 1'b0;
                reg_we_b <= 1'b0;
                reg_valid_l2 <= 1'b1;
                reg_l2_addr_en <= 1'b1;
                reg_rw_l2 <= 1'b1;
            end
	/*			WB_L2_Wait: begin
					if (count == 1)
						count_start = 1'b0;
					else if (count == 10)
						reg_fstate <= Read_L2;
					
					reg_rd_valid_b <= 1'b1;
               reg_stall_proc <= 1'b0;
               reg_we_b <= 1'b0;
               reg_valid_l2 <= 1'b0;
               reg_l2_addr_en <= 1'b1;
               reg_rw_l2 <= 1'b0;
				end
            Read_L1: begin
                reg_fstate <= Idle;
                reg_stall_proc <= 1'b1;
                reg_we_b <= 1'b0;
                reg_valid_l2 <= 1'b0;
            end
            Write_L1: begin
                reg_fstate <= Idle;
                reg_stall_proc <= 1'b1;
                reg_we_b <= 1'b1;
                reg_valid_l2 <= 1'b0;
            end
   */         Read_Wait: begin
                if ((done_l2 & ~(rw_prev))) begin
							reg_fstate <= Idle;
							reg_stall_proc <= 1'b1;
							reg_we_b <= 1'b1;
				//			reg_valid_l2 <= 1'b0;
					 end	  
                else if ((done_l2 & rw_prev)) begin
                    reg_fstate <= Idle;
						  reg_stall_proc <= 1'b1;
						  reg_we_b <= 1'b1;
				//		  reg_valid_l2 <= 1'b0;
					 end	  
                // Inserting 'else' block to prevent latch inference
                else begin
                   reg_fstate <= Read_Wait;
						 reg_stall_proc <= 1'b0;
						 reg_we_b <= 1'b0;
				//		 reg_valid_l2 <= 1'b0;
					 end	 
            end
            default: begin
                reg_rw_l2 <= 1'bx;
                reg_valid_l2 <= 1'bx;
                reg_we_b <= 1'bx;
                reg_rd_valid_b <= 1'bx;
                reg_l2_addr_en <= 1'bx;
                reg_stall_proc <= 1'bx;
                $display ("Reach undefined state");
            end
        endcase
    end
endmodule // blocking