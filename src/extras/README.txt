=======================================================
sample_harp_cores/* : see below
system_drivers/*    : see below
testbench.v	    : testbench used for RTL simulations.
1-BFS3BX_License.dat: License file to setup Quartus tool.
bcd_7seg_dec.v      : bcd to 7-segment display converter
blinker.v           : blinker used just to test LED and measure clock on board is needed.
file_list.txt       : list of files which can be used in RTL simulation when using iverilog.
freq_div_nn.v       : clock frequency divider
mem_ctrl_wrapper.v  : memory wrapper which is used to interface the L2 with the DDR2.
nn_reset_source.v   : Module to generate reset signal for as many cycles as set in parameter.
de3_display.v       : modules to display numbers by creating a BCD number from input.
de3_display_new.v   : modules to output BCD bit one by one along with the hex position. Takes a 32bit number as an input. Module used to display performance number on the board.
ddr2_params_snaps/* : Quartus MegaCore snapshots of the DDR2 configuration used for this system. This is for reference in case the user want to create its own DDR2 rather than using the one present in the projects folder.
nn_de3_memwrapper_test.v: testbench to test the memory wrapper which is used to interface the L2 with the DDR2.

=======================System Drivers (/harp-system/src/extras/system_drivers/)===============================
ddr2_ctrl_test_example_sim_e0_d0.v: is the main driver of the DDR2 this is the file which generates signals from our system to the outside world (which is the DDR2 right now and also LED's and 7 segment displays) . This file instantiates the core and the cache. The number of cores and caches instantiated depends on the desired system. I have created a lot of example files for each kind of system, this is discussed more later.

There are several options in /harp-system/src/extras/system_drivers/*

Doing Single Core runs    :   ddr2_ctrl_test_example_sim_e0_d0_harp.v
Doing dual core runs      :   ddr2_ctrl_test_example_sim_e0_d0_2core_harp.v
Doing SIMD core runs      :   ddr2_ctrl_test_example_sim_e0_d0_harp_simd.v
Doing Big.Little core runs:   ddr2_ctrl_test_example_sim_e0_d0_harp_1Big2Little.v

Just copy any of these to ddr2_ctrl_test_example_sim_e0_d0.v 
Each of these driver files also have code to set test flag (LED) for each application as I mentioned before. So comment/uncomment the lines for testing the application that your HARP core is running.

=======================Sample harmonica cores (/harp-system/src/extras/sample_harp_cores/)===============================
Sample Harmonica cores:
Some sample harmonica cores for both single lane and multiple lane applications are placed here for use:
../harp-system/src/extras/sample_harp_cores/harmonica.v.*
You can use any of them as your core but be sure to set the flags when using SIMD cores for SIMD simulations (the cache code uses these flags as well). The data generated in the thesis is using all these harmonica cores.
=======================================================
