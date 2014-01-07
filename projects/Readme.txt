=======================================================
This is where I will put in all my DE3 projects in archived form!
=======================================================
This project includes all the sources/modules that we need to test our system in any way. You can copy his project and create new ones from this, specially keeping in mind the DDR2 megacore and pin assignment settings used for this project which is the most problemtic part.

The source file references in this project might refer to a different directory (mostly all files are archived so it will refer to some directory inside the restored project folder). So make sure you change their location and add the source files present in this/your git repo for consistency. Other than source files for cache, core, and extras, everything else will be part of the project folder and you dont have to get them from anywhere(already present when you restore the archived project). Once you have all files present just run the whole flow and burn your binary on the FPGA.

********As mentioned earlier you can test many different configurations on board using this project******** Please refer to the 'Unofficial Guide For Running Harp System Simulations' document for more details.

=======================================================
Test options:

********Memory:
		- You can use DDR2 or a dummy memory as you want. If you want to use either use the flag 'DUMMY_MEM' by setting the macro. Where to set this in quartus is discussed in the unofficial document. This can help to do quick tests or to do simple tests to check core,cache without DDR2. 

********Cache / Core:
		- You can drive your DDR2 using different test cases. The driver file used in project is "ddr2_ctrl_test_example_sim_e0_d0.v". But you use following instead (I generally copy them to "ddr2_ctrl_test_example_sim_e0_d0.v" and keep using this file so I dont have to keep making changes in my project)
			- using only the memory wrapper: see the driver file "ddr2_ctrl_test_example_sim_e0_d0_fifo.v" Does simple read/write tests.
			- Using harp core which internalyl instantiates a cache use "ddr2_ctrl_test_example_sim_e0_d0_harp.v"
			- Using only cache to test DDR2. We generate traffic for cache which in turn sends requests to DDR2 "ddr2_ctrl_test_example_sim_e0_d0_cache.v"
			- Using only shared cache to test DDR2. We generate traffic for cache which in turn sends requests to DDR2 "ddr2_ctrl_test_example_sim_e0_d0_cache_shared.v"
			- To test the whole SIMD system "ddr2_ctrl_test_example_sim_e0_d0_harp_simd.v"
			- Other files are discussed in the extras folder.
=======================================================
Note: DDR2 megacore settings and the pin assignments can create problems if made changes. Do it at your risk. 
