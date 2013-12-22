#ifndef CONFIG_H
#define CONFIG_H

#define SIMPLE_BRANCH_PREDICTOR
#define SIMULATE_ICACHE_MISS
//#define USE_IDIOTIC_DIVIDER
//#define MEM_FOR_REGS
//#define EXTERNAL_MUL

static const unsigned WIDTH(32),
                      REGS(16),
                      ROMSZ(1024),
#ifdef USE_CACHE
                      RAMSZ(1073741824), //1GB address space
#else
                      RAMSZ(1024),
#endif
                      IIDBITS(6),
                      LANES(8);
const unsigned SIM_CYCLES(600);
static const unsigned FPU_E(8), FPU_M(23);

static const unsigned LOG2WIDTH(CLOG2(WIDTH)), LOG2ROMSZ(CLOG2(ROMSZ));

#endif
