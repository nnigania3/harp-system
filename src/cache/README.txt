=======================
Cache (L1+L2)
=======================
For overview of the cache read the thesis write up and also the '/doc/Final_Report_Format_Kani_Hassan.pdf'

=======================
Files
=======================
Main Files:
cache_subsystem.v : This is the L1+L2 cache top level file. It instantiates 1 L1 and 1 L2
cache_shared.v:  This is the 2x L1+L2 cache top level file. It instantiates 2 L1's and 1 L2, along with an arbiter.
Arbiter1.v: This is the arbiter used for shared cache. Right now this is for 2 L1 caches. To support more caches just changes the input signal list to add the extra signals and change the arbitration code a little (at line: 84)
L2_cache.v: L2 cache, this nstantiates lot of components. But mainly it instantiates either a 'Mem_dummy' which is a dummy memory or it can instantiate a block to interface with the DDR2 ('mem_ctrl_wrapper'). By default it will instantiates a block to interface with the DDR but if you want to use the dummy memory then use the DUMMY_MEM flag while compiling your verilog code. (Example: iverilog -DDUMMY_MEM my_code.v)
L1_cache.v: L1 cache. Main components are the 'tag ram', 'data ram', 'mshr' and the 'non blocking fsm'.
nonblocking_fsm.v: cache controller used by both L1 and L2. 

****Cache submodules***
DMem.v
FIFO.v
GenericMux.v
GenericOneHotMux.v
L1_tag.v
L2_ram.v
MSHR_2.v
Mem_dummy.v
array.v
bus_signal_switcher.v
data_ram.v
data_ram_simd.v
fill_list_shift_register.v
free_list_FIFO.v
tag_array.v

****Misc/Extra files****
data_array.sv
MSHR_1.v
MSHR_1_test.v
RAM_MGF.v
RAM_MGF_bb.v
RAM_MGF_inst.v
blocking.smf
blocking.v
blocking_fsm.v
blocking_fsm_L1.v
cache_disp_top.v
fast_to_slow_clk_signal.v
file_list.txt
freq_div.v
mshr_dummy.v
slow_to_fast_clk_signal.v

****Test files****
MSHR_2_test.v
blocking.sv
nn_de3_cache_test.v
temp.sv
temp_arb.v
Arbiter1_test.v
test.sv
test_L2.v
test_bench_cache_top.v
test_blocking.v
test_nonblocking.v
test_shared.v

=============================
DDR2 / Cache-Memory Interface
=============================
Memory / DDR2 Code:

We have the option to choose either a dummy memory created using block RAM or we can use an actual DDR2. This is controlled by a flag called 'DUMMY_MEM' which is used in the L2 cache code to either use a dummy memory or use an interface for the DDR2 and drive the DDR2 signals.

If creating a new project it is recommended to copy the example project and use your HARP system by creating a corresponding 'ddr2_ctrl_test_example_sim_e0_d0.v' and keeping everything else unchanged. Some snapshots of the DDR2 settings in the megacore wizrd is here: '/harp-system/src/extras/ddr2_params_snaps/'

DDR2 controller is instantiated using the DDR2 Megacore wizard. Use the parameters and the pin configuration used in the example project. Be very careful in changing these as this can make the DDR to not function properly. You need to only do this once and no other changes will be needed. The DDR2 wizard also creates some example projects which you can use for simulation of just the DDR2 model.

DDR2 RTL  Simulation of example project:

To simulate just the DDR2 model using model sim. Open ModelSim and run this command:   
'do .../<ip_name>/<ip_name_example_project>/simulation/verilog/mentor/run.do'
[You might have to create the verilog simulation file by running 'generate_sim_verilog_example_design.tcl' script in Quartus. This script is located at  .../<ip_name>/<ip_name_example_project>/simulation/]
These simulations use a DDR2 model from Altera and can be slow. You can take these as an example to understand how the memory controller is organized but its not required.
=======================================================
