`timescale 1ns/100ps
module top();
  reg phi, togclk, reset_in;

  wire [6:0] charsel, text, wrcol; 
  wire [0:6] disp1, disp2;
  wire hsync, vsync, valid, led1;
  wire [11:0] dac_vid;

  //harmonica   h(phi, valid, charsel);
  //vgacont   v(phi, charsel, valid, dac_vid, hsync, vsync);
  //harmonica   h(phi, reset_in, valid, charsel);	//reset_in for memory, its reset low (0=> reset)
  //nn_de3_cache_test     cache(phi, valid, charsel);
  //de3_display   display(phi, charsel, valid, disp1, disp2, led1);
  //cache_disp_top cache_top1 (phi, charsel, valid, disp1, disp2, led1);
  harp_core_cache_test harp_core_cache_test_top(.OSC1_50(phi), .HEX0(disp1), .HEX1(disp2));
   
  initial
    begin
       $dumpfile("dump.vcd");
       $dumpvars(2, top);
       phi = 0; togclk = 0;
       reset_in = 1;
       #9 togclk = 1;
       #12 reset_in = 0;
       #499991 $finish;
       //#10991 $finish;
    end

   always
     begin
       #10 phi = phi ^ togclk;
     end
endmodule // top
