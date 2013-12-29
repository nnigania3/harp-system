#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <map>

#include <chdl/gateops.h>
#include <chdl/bvec-basic-op.h>
#include <chdl/adder.h>
#include <chdl/mult.h>
#include <chdl/divider.h>
#include <chdl/shifter.h>
#include <chdl/mux.h>
#include <chdl/enc.h>
#include <chdl/llmem.h>
#include <chdl/memory.h>

#include <chdl/opt.h>
#include <chdl/tap.h>
#include <chdl/sim.h>
#include <chdl/netlist.h>
#include <chdl/analysis.h>
#include <chdl/hierarchy.h>

#include "pipeline.h"

#include "config.h"
//#include "funcunit.h"

#ifdef USE_SIMT_LSU
#include "lsu.h"
#else
#include "funcunit.h"
#endif

#if 1
#define DBGTAP(x) do { TAP(x); } while(0)
#else
#define DBGTAP(x) do {} while(0)
#endif

using namespace std;
using namespace chdl;

#include "harpinst.h"
#include "fpu.h"
#include "regfile.h"

#ifndef SIMPLE_BRANCH_PREDICTOR
#include "bpred.h"
#else
// This is the basic design for the branch prediction module. Given the current
// fetch PC, this unit has to determine the next PC at which to fetch. When
// jumps are taken and resolved, the "jmpPc" and "takenJmp" signals are
// asserted.
node SetClearReg(node s, node c) { return Wreg(s || c, s); }

template <unsigned LAT, unsigned N>
  node BranchPredict
    (bvec<N> predictPc, bvec<N> pc, bvec<N> pc_d,
     bvec<N> jmpPc, node takenJmp, node isJmp, node predicated, node brMispred)
{
  bvec<N> prevJmpPc(Wreg(takenJmp, pc_d)), prevJmpDest(Wreg(takenJmp, jmpPc));
  node prevJmpValid(SetClearReg(takenJmp, brMispred && !takenJmp));
  predictPc = prevJmpDest;
  return pc == prevJmpPc && prevJmpValid;
}
#endif

template <unsigned N> bvec<N> InstructionMemory(bvec<N> addr) {
  #ifdef SIMULATE_ICACHE_MISS
  // Stall every tenth cycle, simulating, e.g., icache misses.
  bvec<4> stallctr;
  stallctr = Reg(Mux(GetStall(0), 
                      Mux(stallctr == Lit<4>(9),
                          stallctr + Lit<4>(1), Lit<4>(0)),
                      stallctr));
  PipelineBubble(0, stallctr == Lit<4>(9));
  DBGTAP(stallctr);
  #endif

  bvec<LOG2ROMSZ-CLOG2(N/8)> a(addr[range<CLOG2(N/8), LOG2ROMSZ-1>()]);
  return PipelineReg(0, LLRom<LOG2ROMSZ-CLOG2(N/8), N>(a, "rom.hex"));
}

template <unsigned N> vec<N, bvec<1>> contort(bvec<N> x) {
  vec<N, bvec<1>> r;
  for (unsigned i = 0; i < N; ++i) r[i][0] = x[i];
  return r;
}

template <unsigned N, unsigned M> bvec<M> OrCols(vec<N, bvec<M>> in) {
  bvec<M> r;
  for (unsigned i = 0; i < M; ++i) {
    bvec<N> x;
    for (unsigned j = 0; j < N; ++j) x[i] = in[j][i];
    r[i] = OrN[x];
  }

  return r;
}

vec<1, bvec<1>> contort(node x) { return contort(bvec<1>(x)); }

template<unsigned N, unsigned R, unsigned L> struct harmonica {
  harmonica() {}
  ~harmonica() {
    for (size_t i = 0; i < funcUnits.size(); ++i) delete funcUnits[i];
  }

  void addFuncUnit(FuncUnit<N, R, L> *fu) { funcUnits.push_back(fu); }

  void generate() {
    // // // Fetch  Unit // // //
    hierarchy_enter("FetchUnit");

    bvec<IIDBITS> iid;
    bvec<N> pc, pc_d, jmpPc, predictedPc;
    node takenJmp, validInst(GetValid(0)), brMispred,
      bpStall(GetStall(0) || !validInst), hasPred, predictTaken, isJmp;
    predictTaken =
      BranchPredict<2>
        (predictedPc, pc, pc_d, jmpPc, takenJmp, isJmp, hasPred, brMispred);
    iid = Reg(Mux(GetStall(0), iid + Lit<IIDBITS>(1), iid));
    pc = Wreg(!bpStall || brMispred,
              Mux(brMispred,
                    Mux(predictTaken, pc + Lit<N>(N/8), predictedPc),
                    Mux(takenJmp, pc_d + Lit<N>(N/8), jmpPc)));
    DBGTAP(pc);
    DBGTAP(iid);
    DBGTAP(validInst);
    DBGTAP(brMispred);
    DBGTAP(predictTaken);
    DBGTAP(jmpPc);

    bvec<N> ir(PipelineReg(2, InstructionMemory(pc)));
    DBGTAP(ir);

    hierarchy_exit();

    // Fetch->Decode pipeline regs
    pc_d = PipelineReg(2, PipelineReg(1, pc));                   DBGTAP(pc_d);
    node validInst_d(PipelineReg(2, PipelineReg(1, validInst))); DBGTAP(validInst_d);
    bvec<IIDBITS> iid_d(PipelineReg(2, PipelineReg(1, iid)));    DBGTAP(iid_d);
    bvec<N> inst_count;
    inst_count = Wreg(validInst_d, inst_count + Lit<N>(1)); DBGTAP(inst_count);

    // // // Decoder // // //
    harpinst<N, CLOG2(R), CLOG2(R)> inst(ir);
    node wrmem_d(inst.is_store());

    // // // Registers/Scheduling // // //
    // Predicate register file
    hierarchy_enter("PredRegFile");
    bvec<L> px, predvalue, p0value, p1value, p_wb_val, p_wb;
    node p0valid, p1valid, predvalid;
    bvec<CLOG2(R)> p_wb_idx;
    bvec<IIDBITS> p_wb_iid, p_wb_curiid;

    vec<3, rdport<CLOG2(R), 1, L>> prf_rd;
    prf_rd[0] = rdport<CLOG2(R), 1, L>(inst.get_psrc0(), contort(p0value));
    prf_rd[1] = rdport<CLOG2(R), 1, L>(inst.get_psrc1(), contort(p1value));
    prf_rd[2] = rdport<CLOG2(R), 1, L>(inst.get_pred(), contort(predvalue));
    wrport<CLOG2(R), 1, L> prf_wr(p_wb_idx, contort(p_wb_val), p_wb);
    Regfile(prf_rd, prf_wr, "p");

    hasPred = inst.has_pred();
    px = bvec<L>(validInst_d) & (bvec<L>(!inst.has_pred()) | predvalue);

    hierarchy_exit();

    DBGTAP(predvalue);
    DBGTAP(predvalid);
    DBGTAP(px);

    // Predicate valid bits

    hierarchy_enter("PredValidBits");

    bvec<L> wrpred_d(px & bvec<L>(inst.has_pdst() && !GetStall(1)));
    vec<3, rdport<CLOG2(R), 1, 1> > pvb_rd;
    pvb_rd[0] = rdport<CLOG2(R), 1, 1>(inst.get_psrc0(), contort(p0valid));
    pvb_rd[1] = rdport<CLOG2(R), 1, 1>(inst.get_psrc1(), contort(p1valid));
    pvb_rd[2] = rdport<CLOG2(R), 1, 1>(inst.get_pred(), contort(predvalid));
    Bitfile(pvb_rd, p_wb_idx, OrN(p_wb), inst.get_pdst(), OrN(wrpred_d), "p");
    PipelineBubble(3, inst.has_psrc0() && !p0valid);
    PipelineBubble(3, inst.has_psrc1() && !p1valid);
    PipelineBubble(3, inst.has_pred() && !predvalid);

    hierarchy_exit();

    // Predicate writer IID bits
    hierarchy_enter("PredIIDTable");

    vec<1, rdport<CLOG2(R), IIDBITS, 1>> piid_rd;
    piid_rd[0] =
      rdport<CLOG2(R), IIDBITS, 1>(p_wb_idx, vec<1, bvec<6>>(p_wb_curiid));
    wrport<CLOG2(R), IIDBITS, 1> piid_wr(inst.get_pdst(), iid_d, OrN(wrpred_d));
    Regfile(piid_rd, piid_wr, "piid");

    hierarchy_exit();

    // GP register file
    hierarchy_enter("GPRegFile");    

    vec<L, bvec<N>> r0value, r1value, r2value, r_wb_val;
    bvec<L> r_wb;
    node r0valid, r1valid, r2valid;
    bvec<CLOG2(R)> r_wb_idx;
    bvec<IIDBITS> r_wb_iid, r_wb_curiid;
    vec<3, rdport<CLOG2(R), N, L>> rf_rd;
    rf_rd[0] = rdport<CLOG2(R), N, L>(inst.get_rsrc0(), r0value);
    rf_rd[1] = rdport<CLOG2(R), N, L>(inst.get_rsrc1(), r1value);
    rf_rd[2] = rdport<CLOG2(R), N, L>(inst.get_rsrc2(), r2value);
    wrport<CLOG2(R), N, L> rf_wr(r_wb_idx, r_wb_val, r_wb);
    Regfile(rf_rd, rf_wr);

    DBGTAP(r0valid); DBGTAP(r1valid); DBGTAP(r2valid);
    //DBGTAP(r0value[0]); DBGTAP(r1value[0]); DBGTAP(r2value[0]);
    DBGTAP(r_wb); DBGTAP(r_wb_iid); DBGTAP(r_wb_curiid);
    DBGTAP(r_wb_idx); //DBGTAP(r_wb_val[0]);
    DBGTAP(p_wb); DBGTAP(p_wb_iid); DBGTAP(p_wb_curiid);
    DBGTAP(p_wb_idx); DBGTAP(p_wb_val);

    hierarchy_exit();

    // GPR valid bits
    hierarchy_enter("GPValidBits");

    bvec<L> wrreg_d(px & bvec<L>(inst.has_rdst() && !GetStall(1)));
    vec<3, rdport<CLOG2(R), 1, 1> > rvb_rd;
    rvb_rd[0] = rdport<CLOG2(R), 1, 1>(inst.get_rsrc0(), contort(r0valid));
    rvb_rd[1] = rdport<CLOG2(R), 1, 1>(inst.get_rsrc1(), contort(r1valid));
    rvb_rd[2] = rdport<CLOG2(R), 1, 1>(inst.get_rsrc2(), contort(r2valid));
    Bitfile(rvb_rd, r_wb_idx, OrN(r_wb), inst.get_rdst(), OrN(wrreg_d));
    PipelineBubble(3, inst.has_rsrc0() && !r0valid);
    PipelineBubble(3, inst.has_rsrc1() && !r1valid);
    PipelineBubble(3, inst.has_rsrc2() && !r2valid);

    DBGTAP(wrreg_d);
    DBGTAP(wrpred_d);
    //DBGTAP(inst.get_rdst());

    hierarchy_exit();

    // GPR writer IID bits
    hierarchy_enter("GPIIDTable");

    vec<1, rdport<CLOG2(R), IIDBITS, 1> > riid_rd;
    riid_rd[0] =
      rdport<CLOG2(R), IIDBITS, 1>(r_wb_idx, vec<1, bvec<6>>(r_wb_curiid));
    wrport<CLOG2(R), IIDBITS, 1> riid_wr(inst.get_rdst(), iid_d, OrN(wrreg_d));
    Regfile(riid_rd, riid_wr, "riid");

    vec<8, fuInput<N, R, L>> fuin;
    bvec<8> fustall;
    bvec<N> nextpc_d(PipelineReg(2, PipelineReg(1, pc + Lit<N>(N/8)))),
            nextpc_x(PipelineReg(3, nextpc_d));
    DBGTAP(nextpc_d);
    DBGTAP(nextpc_x);

    hierarchy_exit();
    
    for (unsigned i = 0; i < 8; ++i) {
      fuin[i].pc = nextpc_x;
      fuin[i].imm = PipelineReg(3, inst.get_imm());
      fuin[i].hasimm = PipelineReg(3, inst.has_imm());
      fuin[i].iid = PipelineReg(3, iid_d);
      fuin[i].op = PipelineReg(3, inst.get_opcode());
      fuin[i].didx = PipelineReg(3, inst.get_rdst());
      fuin[i].pdest = PipelineReg(3, inst.has_pdst());
      fuin[i].wb = PipelineReg(3, px);
      fuin[i].stall = fustall[i];

      for (unsigned j = 0; j < L; ++j) {
        fuin[i].r0[j] = PipelineReg(3, r0value[j]);
        fuin[i].r1[j] = PipelineReg(3, r1value[j]);
        fuin[i].r2[j] = PipelineReg(3, r2value[j]);
        fuin[i].p0[j] = PipelineReg(3, p0value[j]);
        fuin[i].p1[j] = PipelineReg(3, p1value[j]);
      }
    }

    #if 0
    DBGTAP(fuin[0].r0[0]);
    DBGTAP(fuin[0].r1[0]);
    DBGTAP(fuin[0].r2[0]);
    DBGTAP(fuin[0].imm);
    DBGTAP(fuin[0].p0);
    DBGTAP(fuin[0].p1);
    DBGTAP(fuin[0].iid);
    DBGTAP(fuin[0].didx);
    DBGTAP(fuin[0].op);
    #endif
    DBGTAP(fustall);

    // Determine taken jump
    isJmp = inst.is_jmp() && !GetStall(1); DBGTAP(isJmp);
    node brdiv(isJmp && OrN(px) && !AndN(px));
    takenJmp = !GetStall(1) && px[0] && isJmp;
    jmpPc = Mux(
      inst.has_imm(), r0value[0], pc_d + inst.get_imm() + Lit<N>(N/8)
    );
    PipelineFlush(2, brMispred);

    DBGTAP(brdiv);
    DBGTAP(takenJmp);

    brMispred = !GetStall(1) && 
                  validInst_d && ((takenJmp && jmpPc != pc) ||
                                   (!takenJmp && pc != pc_d + Lit<N>(N/8)));

    // // // Functional Units // // //
    // Decide at the decode stage which functional unit is producing the result.
    bvec<64> opdec(Decoder(inst.get_opcode(), OrN(px)));
    vector<node> fu_sel;
    for (unsigned i = 0; i < funcUnits.size(); ++i) {
      vector<node> sel_nodes;
      vector<unsigned> opcodes(funcUnits[i]->get_opcodes());
      for (unsigned j = 0; j < opcodes.size(); ++j)
        sel_nodes.push_back(opdec[opcodes[j]]);
      fu_sel.push_back(OrN(sel_nodes) && (OrN(wrreg_d | wrpred_d) || wrmem_d));
      //DBGTAP(fu_sel[i]);
    }

    // Attach the inputs and outputs
    vec<8, fuOutput<N, R, L>> fuout;
    bvec<8> fu_issue, fu_notready;
    for (unsigned i = 0; i < funcUnits.size(); ++i) {
      fu_issue[i] = PipelineReg(3, fu_sel[i]);
      fuout[i] = funcUnits[i]->generate(fuin[i], fu_issue[i]);
      fu_notready[i] = !funcUnits[i]->ready() && fu_issue[i];
    }
    PipelineStall(3, OrN(fu_notready));
    #if 0
    DBGTAP(fuout[0].out[0]);  DBGTAP(fuout[1].out[0]);
    DBGTAP(fuout[0].valid);   DBGTAP(fuout[1].valid);
    DBGTAP(fuout[0].iid);     DBGTAP(fuout[1].iid);
    DBGTAP(fuout[0].didx);    DBGTAP(fuout[1].didx);
    DBGTAP(fuout[0].wb);      DBGTAP(fuout[1].wb);
    #endif
    DBGTAP(fu_notready);

    // Count in-flight operations (operations in flight in the execution units)
    node inc_ifo(PipelineReg(3, validInst_d && !inst.is_store() &&
                                (!isJmp || inst.get_opcode() == Lit<6>(0x1b) ||
                                           inst.get_opcode() == Lit<6>(0x1c)))),
         dec_ifo;
    bvec<IIDBITS> ifo;
    vec<4, bvec<IIDBITS>> ifo_in;
    ifo_in[0] = ifo;
    ifo_in[1] = ifo - Lit<IIDBITS>(1);
    ifo_in[2] = ifo + Lit<IIDBITS>(1);
    ifo_in[3] = ifo;
    ifo = Reg(Mux(Cat(inc_ifo, dec_ifo), ifo_in));
    DBGTAP(ifo); DBGTAP(inc_ifo); DBGTAP(dec_ifo);

    // Writeback
    bvec<8> fu_valid, fu_pdest;
    for (unsigned i = 0; i < 8; ++i) {
      fu_valid[i] = fuout[i].valid;
      fu_pdest[i] = fuout[i].pdest;
    }

    node try_r_wb(OrN(fu_valid & ~fu_pdest)),
         try_p_wb(OrN(fu_valid & fu_pdest));
    bvec<3> fu_r_out_sel(Log2(fu_valid & ~fu_pdest)),
            fu_p_out_sel(Log2(fu_valid & fu_pdest));
    bvec<8> other_val_r(~(Lit<8>(1)<<fu_r_out_sel) & (fu_valid&~fu_pdest)),
            other_val_p(~(Lit<8>(1)<<fu_p_out_sel) & (fu_valid&fu_pdest));
    node collision_r(OrN(other_val_r)), collision_p(OrN(other_val_p));
    DBGTAP(other_val_r); DBGTAP(collision_r);
    DBGTAP(other_val_p); DBGTAP(collision_p);

    fustall = other_val_r | other_val_p;

    vec<L, vec<8, bvec<N>>> fu_outputs;
    vec<8, bvec<LOG2(R)>> fu_didx;
    vec<8, bvec<IIDBITS>> fu_iid;
    for (unsigned i = 0; i < funcUnits.size(); ++i) {
      for (unsigned j = 0; j < L; ++j)
        fu_outputs[j][i] = fuout[i].out[j];
      fu_didx[i] = fuout[i].didx;
      fu_iid[i] = fuout[i].iid;
    }

    vec<8, bvec<L>> wbouts;
    for (unsigned i = 0; i < 8; ++i) wbouts[i] = fuout[i].wb;
    bvec<L> wbout_r(Mux(fu_r_out_sel, wbouts)),
            wbout_p(Mux(fu_p_out_sel, wbouts));

    for (unsigned i = 0; i < L; ++i)
      r_wb_val[i] = Mux(fu_r_out_sel, fu_outputs[i]);
    r_wb_idx = Mux(fu_r_out_sel, fu_didx);
    r_wb_iid = Mux(fu_r_out_sel, fu_iid);

    for (unsigned i = 0; i < L; ++i)
      p_wb_val[i] = Mux(fu_p_out_sel, fu_outputs[i])[0];
    p_wb_idx = Mux(fu_p_out_sel, fu_didx);
    p_wb_iid = Mux(fu_p_out_sel, fu_iid);

    r_wb = bvec<L>(try_r_wb && (r_wb_iid == r_wb_curiid)) & wbout_r;
    p_wb = bvec<L>(try_p_wb && (p_wb_iid == p_wb_curiid)) & wbout_p;
    dec_ifo = try_r_wb || try_p_wb;
    DBGTAP(try_r_wb); DBGTAP(try_p_wb); DBGTAP(fu_pdest); DBGTAP(fu_valid);

    // Generate hazard unit/pipeline regs.
    genPipelineRegs();
  }  

  vector<FuncUnit<N, R, L>*> funcUnits;
};

int main() {
  harmonica<WIDTH, REGS, LANES> pipeline;

  pipeline.addFuncUnit(new BasicAlu<WIDTH, REGS, LANES>());
  pipeline.addFuncUnit(new PredLu<WIDTH, REGS, LANES>());
  #ifdef USE_IDIOTIC_DIVIDER
  pipeline.addFuncUnit(new PipelinedDivider<WIDTH,REGS,LANES>());
  #else
  pipeline.addFuncUnit(new SerialDivider<WIDTH, REGS, LANES>());
  #endif

  #ifdef USE_SIMT_LSU
  pipeline.addFuncUnit(new SimtLsu<WIDTH, REGS, LANES, RAMSZ>());
  #else
  pipeline.addFuncUnit(new SramLsu<WIDTH, REGS, LANES, RAMSZ>());
  #endif

  pipeline.generate();

  //#ifndef DEBUG
  optimize();
  //#endif

  // Do the simulation
  // Output verilog
  ofstream verilog_file("harmonica.v");
  print_verilog("harmonica", verilog_file);
  #ifdef DEBUG
  ofstream wave_file("harmonica.vcd");
  run(wave_file, SIM_CYCLES);
  //#else
  #endif

  // Print a top-level schematic
  ofstream dot_file("harmonica.dot");
  dot_schematic(dot_file);

  // Do some metrics
  cout << "Critical path length: " << critpath() << endl;
}
