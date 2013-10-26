module cache_disp_top (phi, charsel, valid, disp1, disp2, led1);
  input phi;
  output wire [6:0] charsel; 
  output [0:6] disp1, disp2;
  output led1;
  output wire valid;
  wire clk1, clk2; 
	
  nn_de3_cache_test     cache(clk1, valid, charsel, phi);
  de3_display   display(clk1, charsel, valid, disp1, disp2, led1);
  
  freq_div_nn #(.DIVLOG(1)) freq_div1 (phi, clk1);
  freq_div_nn #(.DIVLOG(2)) freq_div2 (phi, clk2);
  
endmodule
