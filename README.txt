=======================================================
harp-system
=======================================================
Git repo for building a system using a harmonica core based on the HARP ISA.
***Each directory has more specific information in its README.***

======================Harp System Repository Organization.=================================
************Author: Nimit Nigania (nimit.nigania@gmail.com)************
                       -
->docs                 - A list of documents and writeups. Has the thesis included as well. Read thesis to get overall idea of design. Read the unoffical system_build document to know more about how to setup simulation and run the code on the FPGA board. Many things from the system build document are used in the README.txt files present in each specific directory.

->projects             - contains DE3 quartus projects. Will contain archieved projects using which you can hopefully create a new project or reuse it. This might have some exrta top level source files which were created for each of the projects and which instantiates verilog modules present in the source dir.

->src                  - will have all verilog source files as part of the whole system.

----> core                - Has the source files which need to be changed for the harmonica core. So one should checkout harmonica from Chad's repo (link below) and then use this verison instead of his to build a core or merge the changes for some of the files present in this directory.

----> cache               - Code for the cache. Have addede all codes needed to design the cache. This includes single L1<->L2 cache as well as shared cache subsystems. Many extra files also included for testing. I have added all changes to the cache in this directory. 

----> extras              - This will have all the extra files I wrote to create the system. Like memory wrappers, top level test files, display modules for testing etc.

------->system_drivers       - This is a really important directory which has all the driver files. Which means all the modules which will drive the DDR2 controller. This file instantiates the core and the cache. The number of cores and caches instantiated depends on the desired system. I have created a lot of example files for each kind of system, this is discussed more later.


=======================Other Required Tools===============================
************Author: Chad Kersey (chad.d.kersey@gmail.com)************

Original Harmonica
  https://github.com/cdkersey/harmonica

It requires harptool:
  https://github.com/cdkersey/harptool

It also requires CHDL:
  https://github.com/cdkersey/chdl

Brief CHDL introduction:
  http://www.cdkersey.com/wordpress/?p=35

Very brief tutorial/demo on getting CHDL designs running on FPGA is provided at:
  http://www.cdkersey.com/wordpress/?p=51

=======================ISSUES/TODO===============================
ISSUES:
The main issue is the clock. Right now the operating frequency is 62.5 MHz. The DDR2 runs at 125 MHz. DDR2's minimum operating frequency is 125MHz and its functionality below that is not guaranteed.

The timing requirement of the design as reported by Quartus is about 62.5MHz for single lane and about 50 MHz for the SIMD lane. Which means running it will be slightly risky. Even when we run the design at 62.5MHz we are still able to run the single lane and SIMD core for all the applications in the 'testprogs' folder. I was also able to run the heterogeneous systems. But I did start running into problems when I started running 8Little-1Big Core design. The cache by itself can run at around 125MHz so the bottleneck is probably the harmonica core.

TODO:
- add rom support in SIMT LSU.
- Run warp core on FPGA board.
- Performance issue in LSU: For the 'isReady' logic. Right now we stall if not all entries are free, so fix this logic!
- change ddr wrapper buffer size to eight as that how much L2 masht holds, right now its 4

=======================Altera Liscencing===============================
Altera Licensing
Setting up license:
You need to run a license server on at least 2 out of the 3 machines which have been authorized:
Machines authorized to run the license file:
sunnylotus.cc.gt.atl.ga.us (main server)
damint.cc.gt.atl.ga.us
lamint.cc.gt.atl.ga.us

Log-in to these machines and run this command:
<quartus directory>/linux/lmgrd -c <license file directory>/1-BFS3BX_License.dat -l log

License file location here: '/harp-system/src/extras/1-BFS3BX_License.dat'

Just login to sunnylotus and any of damint/lamint machine and run the above commands and the license server should be ready for you.Need to run on atleast two machine including 'sunnylotus'.

If above dont work, look here for instructions to run license server:
http://www.altera.com/download/licensing/setup/lic-setup-float-unix.html

Specify License in quartus:
Once you have the license server running you need to tell Quartus its location. In Quartus go to '->tool->license setup'. At the location of "license file:" just use any of (depending on which machine has server running):
1801@sunnylotus.cc.gt.atl.ga.us
1802@damint.cc.gt.atl.ga.us
1803@lamint.cc.gt.atl.ga.us
=======================================================
