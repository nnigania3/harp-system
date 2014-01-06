`timescale 1ns/100ps
module top();
  reg phi, togclk;// reset_in;
  wire reset_in;  

  wire [6:0] charsel, text, wrcol; 
  wire [0:6] disp1, disp2;
  wire hsync, vsync, valid, led1;
  wire [11:0] dac_vid;
  wire clk1, clkby2;
  //harmonica   h(phi, valid, charsel);
  //vgacont   v(phi, charsel, valid, dac_vid, hsync, vsync);
  //harmonica   h(clk1, phi, reset_in, valid, charsel);	//reset_in for memory, its reset low (0=> reset)
//  nn_de3_cache_test     cache(phi, valid, charsel, clkby2);
 // de3_display   display(phi, charsel, valid, disp1, disp2, led1);
  ddr2_ctrl_test_example_sim_e0_d0   mem_driver(.clk(clk1), .clkby2(phi), .reset_n(reset), .avl_ready(avl_ready), .avl_read_req(avl_read_req) , .avl_rdata(avl_rdata), .avl_rdata_valid(avl_rdata_valid));	//reset_in for memory, its reset low (0=> reset)
nn_reset_source #(.INITIAL_RESET_CYCLES (30)) reset_source(clk1, reset);
   
  initial
    begin
       $dumpfile("dump.vcd");
       $dumpvars(0, top);
       phi = 0; togclk = 0;
       #9 togclk = 1;
       #299991 $finish;
       //#10991 $finish;
    end

   always
     begin
       #5 phi = phi ^ togclk;
     end

   freq_div_nn #(.DIVLOG(1)) freq_div1 (phi, clk1);


   reg [31:0] reset_time;
   initial begin
        reset_time <= 0;
   end
   always @ (posedge clk1)
   begin
        if (reset_in == 1'b1 )
          reset_time <= reset_time + 1;
   end

   assign reset_in = (reset_time < 31'd10) ? 1'b1 : 1'b0 ;

endmodule // top
