Harp Core Main files:
=======================
Files
=======================
You can get all HARP tools from the harmonica and harptool git repository. I have made only minor changes to the files and I have only included those file in my git repo. You should merge these changes with the file from original harmoncia repo.

- harmonica.cpp: This is the main file which has all pipeline stages and instantiates all the blocks. I have made only 1-2changes (using ifdef statements)
 
- lsu.h: has the unit 'SimtLsu' which is the load store or coalescing unit. To enable this unit use the flag 'USE_SIMT_LSU' when compiling harmonica. If you want the lanes to interface with the cache then also use the flag 'USE_CACHE', else by default each lane will get its own private RAM.

- funcunit.h:has the units for the execute stage. It also has the 'SramLsu' which is the basic MMU for blocking requests. There are two variations of it. By default we will create a RAM for ceach lane for use and also a ROM without any interface with cache. But if you want to interface a cache with your harmonica core then use the flag 'USE_CACHE' when compiling harmonica.

- config.h: This sets up the basic config. Set the number of registers and the number of lanes here. I have only made small changes to change the width of the address bits to 30 when using a cache (we use a DRAM with 1GB address space).

- Makefile: You need to define the flags '-DUSE_SIMT_LSU -DUSE_CACHE' to enable certain configurations as mentioned above and also set the ARCH variable when doing SIMD simulations to set up the number of lanes.

/testprog/*: This has all the applications used for the thesis work. 
             Single Lane benchmarks:
             -bubble.s: single lane bubble sort
             - sieve.s: find prime numbers in 1-100
             -matmul.s: matrix multiplication
             -sum_mem.s: array sum
             
             SIMD benchmarks:
             (register %r0 is initialized with the Lane id for each lane and the same instruction is executed for all the lanes)!
             matmul_mt.s: Matrix multiplication with SIMD instructions.
             sum_simd8.s: Do a un-coalesced sum of a an array of numbers
             sum_sim8coal.s: Do a coalesced sum of a an array of numbers
             simd_randtest*.s: random tests to stress the cache and load/store unit.
   
=======================
Building harmonica.v
=======================
harmonica.v: This is the verilog file generated once you 'make' harmonica. This is the verilog file for the core used for our projects. It has signals for I/O (char_out*) and cache.

Building harmonica: Just do 'make' and set the appropriate flags in Makefile and change the config.h according to what type of core is need.
I/O read/write: The harmonica core has the signals 'char_out' and 'char_out_val'. 'char_out_val': says the data on char_out is valid. 'char_out' is some data which the core wants to output to I/O or to external modules which they can use for whatever purpose. An read/writes done at address 0x80000000 are sent to 'char_ou' and assert'char_out_va'.
=======================================================
