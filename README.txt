harp-system
===========
We will be desigining a harp core
===========
                       -
->docs                 - Will try to maintain a list of documents and writeups

->projects             - contains DE3 quartus projects. Will contain archieved projects using which you can hopefully create a new project or reuse it. This might have some exrta top level source files which were created for each of the projects and which instantiate of verilog modules preset in source dir. Will try to move them to src->extras when possible.

->src                  - will have all verilog source files as part of the core.

----> core                - Right now only has the source files which need to be changed on the harmonica core. So one should checkout harmonica from Chad's repo and then use this verison instead of his to build a core.

----> cache               - Code for the cache. Have addede all codes needed to design the cache. This includes single L1<->L2 cache as well as shared cache subsystems. Many extra files also included for testing. I have added all changes to the cache in this directory. Will probably create another dir which has original code.

----> extras              - This will have all the extra files I wrote to create the system. Like memory wrappers, top level test files, display modules for testing etc..

------->system_drivers       - This is a really important directory which has all the driver files. Which means all the modules which will drive the DDR2 controller. There are drivers where we can instantiate only one cache, a shared cache, harp-core+cache, memory-wrapper.
      
