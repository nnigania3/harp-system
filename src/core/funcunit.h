#ifndef __FUNCUNIT_H
#define __FUNCUNIT_H

#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <map>

#include <chdl/gateops.h>
#include <chdl/bvec-basic-op.h>

#include <chdl/adder.h>
#include <chdl/shifter.h>
#include <chdl/mux.h>
#include <chdl/enc.h>
#include <chdl/llmem.h>
#include <chdl/memory.h>

#include <chdl/opt.h>
#include <chdl/tap.h>
#include <chdl/sim.h>
#include <chdl/netlist.h>
#include <chdl/hierarchy.h>
#include <chdl/submodule.h>

#include <chdl/statemachine.h>
#include <chdl/input.h>
#define DBGTAP(x) TAP(x)

static const unsigned IDLEN(6);

template <unsigned N, unsigned R, unsigned L> struct fuInput {
  chdl::bvec<N> imm, pc;
  chdl::vec<L, chdl::bvec<N>> r0, r1, r2;
  chdl::bvec<L> p0, p1;
  chdl::node hasimm, stall, pdest;

  chdl::bvec<6> op;
  chdl::bvec<IDLEN> iid;
  chdl::bvec<CLOG2(R)> didx;

  chdl::bvec<L> wb;
};

template <unsigned N, unsigned R, unsigned L> struct fuOutput {
  chdl::vec<L, chdl::bvec<N>> out;
  chdl::bvec<L> wb;
  chdl::bvec<IDLEN> iid;
  chdl::node valid, pdest;
  chdl::bvec<CLOG2(R)> didx;
};

template <unsigned N, unsigned R, unsigned L> class FuncUnit {
 public:
  FuncUnit() {}

  virtual std::vector<unsigned> get_opcodes() = 0;

  virtual fuOutput<N, R, L> generate(fuInput<N, R, L> in, chdl::node valid) = 0;
  virtual chdl::node ready() { return chdl::Lit(1); } // Output is ready.
};

// Functional unit with 1-cycle latency supporting all common arithmetic/logic
// instructions.
template <unsigned N, unsigned R, unsigned L>
  class BasicAlu : public FuncUnit<N, R, L>
{
 public:
  std::vector<unsigned> get_opcodes() {
    std::vector<unsigned> ops;

    for (unsigned i = 0x05; i <= 0x0c; ++i) ops.push_back(i); // 0x05 - 0x0c
    for (unsigned i = 0x0f; i <= 0x16; ++i) ops.push_back(i); // 0x0f - 0x16
    for (unsigned i = 0x19; i <= 0x1c; ++i) ops.push_back(i); // 0x19 - 0x1c
    ops.push_back(0x25);

    return ops;
  }

  virtual fuOutput<N, R, L> generate(fuInput<N, R, L> in, chdl::node valid) {
    using namespace std;
    using namespace chdl;

    hierarchy_enter("BasicAlu");

    #ifdef DEBUG
    tap("valid_alu", valid);
    tap("stall_alu", in.stall);
    #endif

    fuOutput<N, R, L> o;
    node w(!in.stall);

    for (unsigned i = 0; i < L; ++i) {
      bvec<N> a(in.r0[i]), b(Mux(in.hasimm, in.r1[i], in.imm));

      bvec<N> sum(Adder(a, Mux(in.op[0], b, ~b), in.op[0]));
      bvec<N> prod;
      #ifndef EXTERNAL_MUL
        prod = a * b;
      #else
        Module("asyncmul").outputs(prod).inputs(a)(b);
      #endif

      vec<64, bvec<N>> mux_in;
      mux_in[0x05] = -a;
      mux_in[0x06] = ~a;
      mux_in[0x07] = a & b;
      mux_in[0x08] = a | b;
      mux_in[0x09] = a ^ b;
      mux_in[0x0a] = sum;
      mux_in[0x0b] = sum;
      mux_in[0x0c] = prod;
      mux_in[0x0f] = a << Zext<CLOG2(N)>(b);
      mux_in[0x10] = a >> Zext<CLOG2(N)>(b);
      mux_in[0x11] = mux_in[0x07];
      mux_in[0x12] = mux_in[0x08];
      mux_in[0x13] = mux_in[0x09];
      mux_in[0x14] = sum;
      mux_in[0x15] = sum;
      mux_in[0x16] = prod;
      mux_in[0x19] = mux_in[0x0f];
      mux_in[0x1a] = mux_in[0x10];
      mux_in[0x1b] = in.pc;
      mux_in[0x1c] = in.pc;
      mux_in[0x25] = b;

      o.out[i] = Wreg(w, Mux(in.op, mux_in));
    }

    o.valid = Wreg(w, valid);
    o.iid = Wreg(w, in.iid);
    o.didx = Wreg(w, in.didx);
    o.pdest = Wreg(w, in.pdest);
    o.wb = Wreg(w, in.wb);
  
    isReady = w;

    hierarchy_exit();

    return o;
  }

  virtual chdl::node ready() { return isReady; }
 private:

  chdl::node isReady;
};

// Predicate logic unit. All of the predicate/predicate and register/predicate
// instructions.
template <unsigned N, unsigned R, unsigned L>
 class PredLu : public FuncUnit<N, R, L>
{
 public:
  std::vector<unsigned> get_opcodes() {
    std::vector<unsigned> ops;

    for (unsigned i = 0x26; i <= 0x2c; ++i) ops.push_back(i); // 0x26 - 0x2c

    return ops;
  }

  virtual fuOutput<N, R, L> generate(fuInput<N, R, L> in, chdl::node valid) {
    using namespace std;
    using namespace chdl;

    hierarchy_enter("PredLu");

    fuOutput<N, R, L> o;

    node w(!in.stall);

    for (unsigned i = 0; i < L; ++i) {
      bvec<N> r0(in.r0[i]);
      node p0(in.p0[i]), p1(in.p1[i]);

      bvec<64> mux_in;
      mux_in[0x26] = OrN(r0);
      mux_in[0x27] = p0 && p1;
      mux_in[0x28] = p0 || p1;
      mux_in[0x29] = p0 != p1;
      mux_in[0x2a] = !p0;
      mux_in[0x2b] = r0[N-1];
      mux_in[0x2c] = !OrN(r0);

      o.out[i] = Zext<N>(bvec<1>(Wreg(w, Mux(in.op, mux_in))));
    }

    o.valid = Wreg(w, valid);
    o.iid = Wreg(w, in.iid);
    o.didx = Wreg(w, in.didx);
    o.pdest = Wreg(w, in.pdest);
    o.wb = Wreg(w, in.wb);
    isReady = w;

    hierarchy_exit();

    return o;
  }

  chdl::node ready() { return isReady; }
 private:
  chdl::node isReady;
};

// Integrated SRAM load/store unit with no MMU, per-lane RAM
template <unsigned N, unsigned R, unsigned L, unsigned SIZE>
  class SramLsu : public FuncUnit<N, R, L>
{
 public:
  std::vector<unsigned> get_opcodes() {
    std::vector<unsigned> ops;

    ops.push_back(0x23);
    ops.push_back(0x24);

    return ops;
  }

  virtual fuOutput<N, R, L> generate(fuInput<N, R, L> in, chdl::node valid) {
    const unsigned L2RAMWDS(CLOG2(SIZE/(N/8))), L2ROMWDS(CLOG2(ROMSZ/(N/8)));

    using namespace std;
    using namespace chdl;

    hierarchy_enter("SramLsu");

    fuOutput<N, R, L> o;

    node w(!in.stall);

    bvec<6> op(in.op);
    bvec<N> imm(in.imm);

//NN- signals begin
    bvec<L> mem_out_stall;
    bvec<1> test_valid; 
    bvec<N> test_out  ; 
    bvec<1> test_pdest; 
    bvec<L> test_wb   ; 
    bvec<IDLEN> test_iid;
    bvec<CLOG2(R)> test_didx;
    bvec<N> fu_mem_data_out;
    bvec<1> clkby2 = Input<1>("clkby2");
//NN- signals end

    for (unsigned i = 0; i < L; ++i) {	
      bvec<N> r0(in.r0[i]), r1(in.r1[i]), imm(in.imm),
              addr(imm + Mux(op[0], r1, r0));			//op[0]=0=r1 =>st
      bvec<L2RAMWDS> ramaddr(Zext<L2RAMWDS>(addr[range<CLOG2(N/8), N-1>()]));
      bvec<L2ROMWDS> romaddr(Zext<L2ROMWDS>(addr[range<CLOG2(N/8), N-1>()]));
      bvec<CLOG2(N)> memshift(Lit<CLOG2(N)>(8) *
                                Zext<CLOG2(N)>(addr[range<0, CLOG2(N/8)-1>()]));
      node romsel(addr < Lit<N>(ROMSZ));

      bvec<N> sramout = Syncmem(ramaddr, r0, valid && !op[0] && !romsel),
              romout  = Reg(LLRom<L2ROMWDS, N>(romaddr, "rom.hex"));

// *****NN-Code Begin*****
    bvec<1> reset_in = Input<1>("reset_in");    
    node mem_reset(!reset_in[0]);
    //node reset = Lit(1);

    bvec<IDLEN> mem_out_iid;
    bvec<1> mem_out_ready;
    bvec<N> mem_sramout;
    node ram_issue;
    node issue;
    bvec<1> pending_read, temp;
    //pending_read= Wreg(mem_out_ready[0] || (ram_issue && op[0]), ~pending_read);
    pending_read	= Wreg(mem_out_ready[0] || (ram_issue && op[0]), pending_read + Lit<1>(1));
    temp        	= Mux(Wreg(valid && temp[0], romsel || !op[0]), ~pending_read, bvec<1>(!in.stall));
    node test_isReady   = temp[0] && !mem_out_stall[i];
    isReady		= test_isReady ;
    issue 		= test_isReady && valid ;
    ram_issue 		= test_isReady && valid && !romsel ;

    Module("cache_subsystem").inputs(clkby2)(bvec<1>(mem_reset))(addr)(r0)(bvec<1>(!op[0]))(bvec<1>(ram_issue))(in.iid).outputs(mem_sramout)(mem_out_iid)(mem_out_ready)(bvec<1>(mem_out_stall[i])); //all should be bitvec
 
    node test_trig = Wreg(issue, romsel);
    bvec<CLOG2(N)> memshift_out = Wreg(issue, memshift);
    node rom_out_valid = Wreg(w, valid && op[0]);
    test_valid = Mux(test_trig, Wreg(w, mem_out_ready), bvec<1>(rom_out_valid));
    test_out   = Mux(test_trig, Wreg(w, mem_sramout), romout ) >> Reg(memshift_out); //check
    test_pdest = Wreg(issue, in.pdest);
    test_wb    = Wreg(issue, in.wb);
    test_iid   = Wreg(issue, in.iid);
    test_didx  = Wreg(issue, in.didx);

    #if 1
    node mem_rw_in = !op[0];
    bvec<IDLEN> mem_iid_in  = in.iid;
    node tap_stall_out = mem_out_stall[i];
    node fu_mem_rom_in = romsel;

    DBGTAP(pending_read	);
    DBGTAP(mem_reset	);
    DBGTAP(addr		);
    DBGTAP(r0		);
    DBGTAP(mem_rw_in	);
    DBGTAP(issue	);
    DBGTAP(ram_issue	);
    DBGTAP(mem_iid_in	);
    DBGTAP(mem_sramout	);
    DBGTAP(mem_out_iid	);
    DBGTAP(mem_out_ready);
    DBGTAP(tap_stall_out);
    DBGTAP(test_isReady	);
    DBGTAP(test_iid	);
    DBGTAP(test_didx	);
    DBGTAP(test_out	);
    DBGTAP(test_valid	);
    DBGTAP(fu_mem_rom_in);
    #endif
// *****NN-Code End*****

      //o.out[i] = Mux(Reg(romsel), sramout, romout) >> Reg(memshift);
      o.out[i] = test_out ;
      // Simple character output from lane 0.
      if (i == 0) {
        node writeram(valid && !op[0] && !romsel), writeinst(valid && !op[0]),
             readram(valid && op[0] && !romsel);
        bvec<N> writeval(r0);
        node io(addr[N-1]), io_wr(valid && !op[0]),
             char_out(io_wr && addr[range<0, N-2>()] == Lit<N-1>(0));
        bvec<7> char_out_val(r0[range<0, 6>()]);
        OUTPUT(char_out);
        OUTPUT(char_out_val);
      }
    }

    //o.valid = Wreg(w, valid && op[0]);
    //o.iid   = Wreg(w, in.iid);
    //o.didx  = Wreg(w, in.didx);
    //o.pdest = Wreg(w, in.pdest);
    //o.wb    = Wreg(w, in.wb);
    o.valid = test_valid[0] ;
    o.iid   = test_iid   ;
    o.didx  = test_didx  ;
    o.pdest = test_pdest[0] ;
    o.wb    = test_wb    ;
    #if 1					//NN Debug
    node fu_mem_issue_in 	= valid;
    node fu_mem_stall_in	= in.stall;
    node fu_mem_rw_in 		= !op[0];
    node fu_mem_valid_out	= o.valid;
    bvec<IDLEN> fu_mem_iid_out	= o.iid;
    fu_mem_data_out 		= test_out;

    DBGTAP(fu_mem_issue_in 	);
    DBGTAP(fu_mem_stall_in	);
    DBGTAP(fu_mem_rw_in 	);
    DBGTAP(fu_mem_valid_out	);
    DBGTAP(fu_mem_iid_out	);
    DBGTAP(fu_mem_data_out	);
    #endif

    hierarchy_exit();

    return o;
  }

  chdl::node ready() { return isReady; }
 private:
  chdl::node isReady;
};

//
//	cache_subsystem cache
//	(
//		clk,
//		reset,
//		addr_in, 	// address in from the core
//		data_in, 	// data from the core
//		rw_in, 		// read / write command
//		valid_in, 	//  valid reg on the addr, data buses
//		id_in, 		// ld/st Q id for request
//		data_out,	// data to be given to the core
//		id_out,	// ld/st Q id for request being satisfied
//		ready_out, 	// the memory request for which data is ready
//		stall_out 	// the memory system cannot accept anymore requests
//	);
//

template <unsigned N, bool D>
  chdl::bvec<N> Shiftreg(
    chdl::bvec<N> in, chdl::node load, chdl::node shift, chdl::node shin
  )
{
  using namespace chdl;
  using namespace std;

  HIERARCHY_ENTER();  

  bvec<N+1> val;
  val[D?N:0] = shin;

  if (D) {
    for (int i = N-1; i >= 0; --i)
      val[i] = Reg(Mux(load, Mux(shift, val[i], val[i+1]), in[i]));
    HIERARCHY_EXIT();
    return val[range<0, N-1>()];
  } else {
    for (unsigned i = 1; i < N; ++i)
      val[i] = Reg(Mux(load, Mux(shift, val[i], val[i-1]), in[i-1]));
    HIERARCHY_EXIT();
    return val[range<1, N>()];
  }
}

template <unsigned N>
  chdl::bvec<N> Rshiftreg(
    chdl::bvec<N> in, chdl::node load, chdl::node shift,
    chdl::node shin = chdl::Lit(0)
  )
{ return Shiftreg<N, true>(in, load, shift, shin); }

template <unsigned N>
  chdl::bvec<N> Lshiftreg(
    chdl::bvec<N> in, chdl::node load, chdl::node shift,
    chdl::node shin = chdl::Lit(0)
  )
{ return Shiftreg<N, false>(in, load, shift, shin); }

template <unsigned N>
  void Serdiv(
    chdl::bvec<N> &q, chdl::bvec<N> &r, chdl::node &ready, chdl::node &waiting,
    chdl::bvec<N> n, chdl::bvec<N> d, chdl::node v, chdl::node stall
  )
{
  using namespace std;
  using namespace chdl;

  // The controller
  Statemachine<N+3> sm;
  bvec<CLOG2(N+3)> state(sm);
  sm.edge(0, 0, !v);
  sm.edge(0, 1, v);
  for (unsigned i = 1; i < N+2; ++i)
    sm.edge(i, i+1, Lit(1));
  sm.edge(N+2, 0, !stall);
  sm.generate();
  ready = (bvec<CLOG2(N+3)>(sm) == Lit<CLOG2(N+3)>(N+2));
  waiting = (bvec<CLOG2(N+3)>(sm) == Lit<CLOG2(N+3)>(0));

  // The data path
  bvec<2*N> s(Rshiftreg(Cat(d, Lit<N>(0)), v, Lit(1)));
  node qbit(Cat(Lit<N>(0), r) >= s);
  r = Reg(Mux(v, Mux(qbit, r, r - s[range<0, N-1>()]), n));
  q = Lshiftreg(Lit<N>(0), v, !ready, qbit);
}

template <unsigned N, unsigned R, unsigned L>
  class SerialDivider : public FuncUnit<N, R, L>
{
 public:
  std::vector<unsigned> get_opcodes() {
    std::vector<unsigned> ops;

    ops.push_back(0x0d);
    ops.push_back(0x0e);
    ops.push_back(0x17);
    ops.push_back(0x18);

    return ops;
  }

  virtual fuOutput<N, R, L> generate(fuInput<N, R, L> in, chdl::node valid) {
    using namespace std;
    using namespace chdl;

    hierarchy_enter("SerialDivider");

    fuOutput<N, R, L> o;
    node outputReady, issue(valid && isReady);

    for (unsigned i = 0; i < L; ++i) {
      bvec<N> n(in.r0[i]), d(Mux(in.hasimm, in.r1[i], in.imm)), q, r;
      Serdiv(q, r, outputReady, isReady, n, d, issue, in.stall);
      o.out[i] = Mux(Wreg(issue, in.op[0]), r, q);
    }

    o.valid = outputReady;
    o.iid = Wreg(issue, in.iid);
    o.didx = Wreg(issue, in.didx);
    o.pdest = Lit(0);
    o.wb = Wreg(issue, in.wb);
  
    hierarchy_exit();

    return o;
  }

  virtual chdl::node ready() { return isReady; }
 private:

  chdl::node isReady;
};

chdl::node Pipe(chdl::node stall, chdl::node in, unsigned stages) {
  using namespace chdl;
  if (stages == 0) return in;
  else return Wreg(!stall, Pipe(stall, in, stages-1));
}

template <unsigned N>
  chdl::bvec<N> Pipe(chdl::node stall, chdl::bvec<N> in, unsigned stages)
{
  using namespace chdl;
  using namespace std;

  bvec<N> out;
  for (unsigned i = 0; i < N; ++i)
    out[i] = Pipe(stall, in[i], stages);
  return out;
}

template <unsigned N, unsigned R, unsigned L>
  class PipelinedDivider : public FuncUnit<N, R, L>
{
 public:
  std::vector<unsigned> get_opcodes() {
    std::vector<unsigned> ops;

    ops.push_back(0x0d);
    ops.push_back(0x0e);
    ops.push_back(0x17);
    ops.push_back(0x18);

    return ops;
  }

  virtual fuOutput<N, R, L> generate(fuInput<N, R, L> in, chdl::node valid) {
    using namespace std;
    using namespace chdl;

    hierarchy_enter("PipelinedDivider");

    fuOutput<N, R, L> o;

    node stall(in.stall);

    for (unsigned i = 0; i < L; ++i) {
      bvec<2*N> rq;
      bvec<N> n(in.r0[i]), d(Mux(in.hasimm, in.r1[i], in.imm)),
              q(rq[range<0,N-1>()]), r(rq[range<N,2*N-1>()]);
      Module("divider").inputs(n)(d)(bvec<1>(stall)).outputs(rq);

      o.out[i] = Mux(Pipe(stall, in.op[0], 7), r, q);

      TAP(r); TAP(q); TAP(rq); TAP(n); TAP(d);
    }

    o.valid = Pipe(stall, valid, 7);
    o.iid = Pipe(stall, in.iid, 7);
    o.didx = Pipe(stall, in.didx, 7);
    o.pdest = Lit(0);
    o.wb = Pipe(stall, in.wb, 7);
  
    isReady = !stall;

    hierarchy_exit();

    return o;
  }

  virtual chdl::node ready() { return isReady; }
 private:

  chdl::node isReady;
};

#endif
