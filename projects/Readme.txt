This is where I will put in all my DE3 projects in archived form!
-Added project "DE3_ddr_trial"
This is project which includes mostly all the sources/modules that we need to test our system in any way. You can copy his project and create new ones from this, specially keeping in mind the DDR2 megacore and pin assignment settings used for this project which is the most problemtic part.

The source file references in this project might refer to a different directory. So make sure you change that and add the source files present in this git repo. Other than source files for cache,core, extras everything else will be part of the project files.

********As mentioned earlier you can test many different configurations on board using this project********.

////////////////////////////////////////
Test options:

********Memory:
		- You can use DDR2 or a dummy memory as you want. If you want to use either uncomment the DDR/dummy module and comment out the dummy/DDR modules as the case may be in the L2_cache.v code. This can help do quick tests to do simple tests to check core,cache without DDR2. 

********Cache / Core:
		- You can drive your DDR2 using different test cases. The driver file used in project is "ddr2_ctrl_test_example_sim_e0_d0.v". But you use following instead (I generally copy them to "ddr2_ctrl_test_example_sim_e0_d0.v" and keep using this file so I dont have to keep making changes in my project)
			- using only the memory wrapper: see the driver file "ddr2_ctrl_test_example_sim_e0_d0_fifo.v" Does simple read/write tests.
			- Using harp core which internalyl instantiates a cache use "ddr2_ctrl_test_example_sim_e0_d0_harp.v"
			- Using only cache to test DDR2. We generate traffic for cache which in turn sends requests to DDR2 "ddr2_ctrl_test_example_sim_e0_d0_cache.v"
			- Using only shared cache to test DDR2. We generate traffic for cache which in turn sends requests to DDR2 "ddr2_ctrl_test_example_sim_e0_d0_cache_shared.v"
	
////////////////////////////////////////
CAUTION:
   DDR2 megacore settings and the pin assignments can create big problems if made changes. Do it at your risk. 
