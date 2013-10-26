**********************//////////////////////////////////////////////////////////////////////****************************
**********************My Doubts and Answers / Questions one will ask when going thorugh CHDL****************************

- What is node? How are registers modelled?
- How to instantiate a module?
- How are instructions read by the core?
- What are the pipeline regs for?
	- Regs between pipeline stages with stall signals which prevent it from writing value to its output
- What happend to local variables inside a loop? (what if we have a 'node' in a loop?)
	- each time you create a node it is either copied from somehwere or a new node is created. So if you have nodes in a for loop then everytime a new node is created for each iteration.
- Where do the signal names go? how to monitor a signal or prevent chdl from changing its name
	- Using the 'TAP' option. Then chdl will not optimize signal and its name will be retained.
- Initial statements in the final code
	-Only usde for initialization purpose. This initialization is synthesizable and is part of the bit stream.SO  (initial x = 0) is valid!
- We use lot of 'Wreg' for a conditonal write to a reigster, wont it create a latch?
	- No, all the registers (D-Flip Flops) are clocked in the design. So 'Reg', 'Wreg' are all registers.
- What is the hierarchy statement for?
	- It is used to create a heirchachy in the design, mostly good for debug purpose and generate a *.hier file which can be viewed to see the control flow graphs.
- When a store instruction reaches the memory stage why does it not assert a valid output signal in orginal Harmonica design?
	- stored a committed as soon as they reach the memory stage.
!- how is store accounted for if commited in mem stage?
- <harmonica> How do 'valid', 'issue', 'fuin::isReady','fuout::valid', 'fuin::stall' signal work.
- How to use the vga controller to display the output
- How do signals appeat in the output? difference in TAP/DBGTAP/OUTPUT
	- be careful in directly using TAP as it will create a signal with the exact same name, so if is signal[i] it will be wire signal[i]

!- How to dump variables to view in GTK, dumpvars(,2)? How to view signals of nested modules like we see in ModelSim
!- Why is this not working!
	bvec<1> pending_read= Wreg(some_node, ~pending_read);
	Answer: declare variables before using them, even if thety are nodes, vectors etc.
- We need a register which can write on a posedge of another signals rather than just 'clk'
!- Need to fix use before declaration error given my ModelSim and ignored by GTKwave/QuartusII
- Found iVerilog a little relaxed in reporting the errors in verilog. (Have found Altera quartus compiler as good as it gives important warnings atleast and no errors).
- How to create an INPUT/OUTPUT node.
	- use OUTUT(node) and the node will appear at the output
	- use "bvec<2> a = Input<2>("a");" then "a" will appear as an input
- How to interpret the symbols in harp assembly (like, 'perm' 'global' 'align')
- Add reset support in the HARP core?
**********************//////////////////////////////////////////////////////////////////////****************************


**********************//////////////////////////////////////////////////////////////////////****************************
**********************  Summary Of CHDL / Documentation / Your understanding  ****************************

- Each module has a implicit clock.
- You need to know how to use each of the block. See the possible instantiations in the chdl library.
- Node is basically a wire. bvev is a vector of nodes.
- When instantiating a module then it assumes that the module to be connected has this format module[clk(implicit), inputs, outputs]
- Everything is made up of nodes. So if you want to create a register create a node/wire for that and then use 'Reg' to map it to a register or use 'Wreg' which conditionally writes the input node to the 'registered' output node (mean its clocked).
- If you want to escape ModelSim then its recommended to install GTKWAVE and iVerilog. Both of them are open source and sources can be installed from their website.
	-iVerilog: it will compile the verilog sources into a target file (netlist). We can them run the executable it creates to see the outputs of the signals we selected earlier in our verilog code (using 'dumpvars', 'dumpfile' in verilog test bench). iVerilog does not have a wave form viewer hence we need a seperate simulator to run the netlist and see the waveforms. Hence we use GTKwave.
		- To compile: "iverilog -o run_sim -c verilog_files.txt -s top_most_module". Once done we can just run the binary('./run_sim') to get the signal values in the dump file we had specified.
	-GTKwave: it is a wave form viewer, we can use this to view the signals values dumped out by iVerilog in wave format.

**********************//////////////////////////////////////////////////////////////////////****************************


**********************//////////////////////////////////////////////////////////////////////****************************
**********************  Testing Notes  ****************************
- (RTL) Testing when connecting cache_subsystem.v to HARP.
	- Basic load/store miss pass. baisc ld/st hit pass.
	- sum_mem.s code pass
	- consecutive loads (hit->hit, hit->miss) pass
	- consecutive stores so it stalls the pipeline after some reqs sent to mem (mem not ready anymore). Stalling of pipeline works good for stores.
	- sieve passes which prints out the prime numbers in ASCII format to the output
	- bubble sort also works
		- there was bug in harp-cache interface. As we were asserting the valid_out when ROM was selected in a wrong way.
		- (CHECK!) also added feature in cache. So that when cache is reset we set stall_out as high! it seems to work with the harp core right now!
	- Tested Memory controller in RLT using the DDR2 model provided by Altera.
		- This model works fine when I directly simulate in Modelsim using "run.do" in example_project/simulation/
!?		- When I directyl try to run the memory model as part of my project simulation then I run into issue when using mem_wrapper. It says that we are trying to send a ReadCommand to DDR without waiting for TRC time (time we should wait after an activate command is issued)
		- Simulating the original project takes a lot of time as it goes through the whole caliberations phase!
		- Doing gate level simulation will take 2.5/3 days just to do caliberation. So beware.
- harp core freq mostly limited to freq->80Mhz (I am able to run sieve at 125MHz, but not at 150Mhz). Cache limited to -> 255.5/2MHz -> 127.75MHz, not completely sure but thats what cache_original shows! Core+cache-> 120.22/2 -> 60 MHz and this is what harp+cache! and this is what limits our integrated core!This 60MHz is also what harp+cache+DDR shows

- (RTL) Testing shared_cache and arbiter to HARP.
	- Tested Arbitor1_nn.v first using simple tests.
	- tested shared cache using tests preset in shared_cache test file. It all seemed to pass
	- Just be careful when instantiatin more than 2 L1 caches as it shared_cache code needs to be manually changed in that case.

- (DE3 board) Testing original Harp core ( In my testing I wrote outputs to leds and the 2 7-seg displays.)(Quartus Project in: original_harp_trial/original_harp_trial.qpf)
	- Output sum of 15nos (= 120) on the 2 7-segs displays (it shows: 78 which is hex form of 120)
	- Ran the seive code to check till code end completion by dumping out some data to 7-seg displays
	- ran hello world to display hex form of the ASCII output of the last char sent out.
- (DE3 board) Testing original cache
	- done testing using simple tests
- (DE3 board) Testing original cache + harp
	- passes sieve, mem_sum
?	- bubble
- (DE3 board) Testing DDR + random traffic generator
	- was able to run on board using DDR freq -> 266.667MHz (avl interface freq-> 133.224). Used "ddr2_ctrl_org" for my mem ctrl.
	- I set 6 leds correspodning to local done/pass/fail and driver done/pass/fail (I do this for most of DDR tests)
	- was able to run on board using DDR freq -> 125MHz (avl interface freq-> 62.5). Used pin assignments from "ddr2_ctrl_org", else if i tried to copy pin assignments or generate it, it creates a lot of problems. Project used was "ddr2_ctrl_test_example"
- (DE3 board) Testing DDR + mem wrapper
	- passes simple driver test of mem_sum. Ran at DDR freq->125MHz (ddr_ctrl_test), 266.667 MHz (ddr2_crl_org, ddr2_ctrl_test)
- (DE3 board) Testing DDR + mem wrapper + cache
	- passes simple driver test of mem_sum. Ran at DDR freq->125MHz (ddr_ctrl_test), 266.667 MHz (ddr2_crl_org, ddr2_ctrl_test)
- (DE3 board) Testing DDR + mem wrapper + cache + harp
	- passes simple driver test of mem_sum. Ran at DDR freq->125MHz (interface 62MHz) (ddr_ctrl_test)
	- also seems to pass "bubble sort". I just displayed the last sorted no. which is '9' on the seven segment displays. DDR freq->125MHz
- (DE3 board) Testing DDR + mem wrapper + shared (2*L1+L2) cache
	- passes simple driver test of mem_sum. Ran at DDR freq->125MHz (ddr_ctrl_test). Look at testbench driver "ddr2_ctrl_test_example_sim_e0_d0_cache_shared.v"
**********************//////////////////////////////////////////////////////////////////////****************************
**********************  Misc  ****************************
- For the warning
	"Critical Warning (176647): DLL atom "......|altera_mem_if_dll_stratixiii:dll0|dll_wys_m" is using a clock period of 8.0 ns, which is outside the valid range for its configuration mode. When the delay buffer mode is "HIGH" and the delay chain length is "12", the valid range is from 2.7 ns to 4.17 ns."
		- Altera says: This critical warning can be ignored for DDR2 SDRAM memory interface operating below 240MHz since this is considered a low frequency external memory interface design and the calibration process is able to compensate for the resulting discrepancy.
**********************//////////////////////////////////////////////////////////////////////****************************
