#ifndef __LSU_H
#define __LSU_H

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

#include <chdl/statemachine.h>

#include "funcunit.h"

static const unsigned Q(4);
static const unsigned DELAY(8);

#define INTERNALMEM 1
#define DBGTAP(x) TAP(x)

// SIMT LSU
template <unsigned N, unsigned R, unsigned L, unsigned SIZE>
  class SimtLsu : public FuncUnit<N, R, L>
{
 public:
  std::vector<unsigned> get_opcodes() {
    std::vector<unsigned> ops;

    ops.push_back(0x23);
    ops.push_back(0x24);

    return ops;
  }

  template <unsigned M> 
	  chdl::bvec <M> delay (chdl::bvec <M> in, unsigned cycles) {
	  if (cycles == 0) return in;
	  else return chdl::Reg<M>(delay(in, cycles-1));
  }
  chdl::node delay(chdl::node in, unsigned cycles) {
	  if (cycles == 0) return in;
	  else return chdl::Reg(delay(in, cycles-1));
  }
  
  
  template<unsigned L2WORDS>
  void frontEnd(fuInput<N, R, L> in, chdl::vec<L, chdl::bvec<L2WORDS> > memaddr, 
		  chdl::node write, chdl::node valid) {
	  const unsigned L2WORDS(CLOG2(SIZE/(N/8)));
	  const unsigned OFFSET(CLOG2(L));
	  using namespace chdl;

	  DBGTAP(feMemaddr); DBGTAP(feOffsetValid); DBGTAP(feValid); DBGTAP(feWrite);
	  for(int i=0; i<L; ++i)
		  TAP(feOffset[i]);

	  bvec<L> feAddrValid, feInsertSelect, inMemaddrSelect;
	  bvec<CLOG2(L)> feInsertidx;
	  vec<L, bvec<L2WORDS> > feAddr;
	  bvec<L2WORDS> inMemaddr;
	  bvec<L> coalescedMatch, inputAddrMatch, feAddrMatch;
	  node feCoalescedReg,
		   feWriteReg;

	  DBGTAP(feAddrValid); DBGTAP(feInsertSelect);
	  DBGTAP(feInsertidx); DBGTAP(inputAddrMatch); DBGTAP(feAddrMatch);
	  DBGTAP(feCoalescedReg); DBGTAP(feCoalesced); 
	  DBGTAP(feEnable); DBGTAP(feEmpty); DBGTAP(feWriteReg);
	  DBGTAP(feiid);
	  for(int i=0; i<L; ++i) DBGTAP(feAddr[i]);

	  feEnable = valid && isReady;
	  feInsertidx = Log2(feAddrValid);
	  feInsertSelect = Decoder(feInsertidx, feEnable);
	  feEmpty = !OrN(feAddrValid);
	  
	  inMemaddrSelect = Decoder(Log2(in.wb), feEnable);
	  inMemaddr = Mux(Log2(in.wb), memaddr);
	  feMemaddr = Mux(feEnable, Mux(feInsertidx, feAddr), inMemaddr ); 
	  feCoalesced = AndN(coalescedMatch); 
	  feCoalescedReg = Wreg(feEnable, AndN(coalescedMatch) ); 
	  feOneAddr = AndN(inputAddrMatch); 
	  feWrite = Mux(feEnable, feWriteReg, write );
	  feWriteReg = Wreg(feEnable, write);

	  feValid = feEnable || !feEmpty;
	  feiid = Wreg(feEnable, in.iid);
	  fedidx = Wreg(feEnable, in.didx);
	  fewb = Wreg(feEnable, in.wb);
	 	
	  for(int i=0; i<L; ++i)
	  {
		  feAddr[i] = Wreg(feEnable, memaddr[i]);	
		  feAddrValid[i] = Wreg(feEnable || feAddrMatch[i], 
				  Mux(feEnable, !feAddrMatch[i], !inputAddrMatch[i]) );	
		  
		  inputAddrMatch[i] = ( inMemaddr[range<OFFSET,L2WORDS-1>()] == memaddr[i][range<OFFSET,L2WORDS-1>()] ) && in.wb[i];
		  feAddrMatch[i] = ( feMemaddr[range<OFFSET,L2WORDS-1>()] == feAddr[i][range<OFFSET,L2WORDS-1>()] ) && feAddrValid[i];

		  feOffsetValid[i] = Mux(feEnable, feAddrMatch[i], inputAddrMatch[i]);
		  feOffset[i] = Mux(feEnable, feAddr[i][range<0,OFFSET-1>()], 
				  memaddr[i][range<0,OFFSET-1>()]); 
		  
		  coalescedMatch[i] = 
		      (memaddr[0][range<OFFSET, L2WORDS-1>()] == memaddr[i][range<OFFSET, L2WORDS-1>()])
			  && feAddrValid[i];
		  /*coalescedMatch[i] = 
		      (memaddr[0][range<OFFSET, N>()] == memaddr[i][range<OFFSET, N>()])
			  && feAddrValid[i];*/ //NN fix, memaddr is only L2WORDS wide but we were indexing it till N which caused segfault
	  }

	  DBGTAP(inMemaddr);
  }


template <unsigned L2WORDS>
  void ldq(fuInput<N, R, L> in, chdl::vec<L, chdl::bvec<L2WORDS> > memaddr ) {
	  const unsigned L2WORDS(CLOG2(SIZE/(N/8)));
	  const unsigned OFFSET(CLOG2(L));
	  using namespace std;
	  using namespace chdl;
	  
	  node resetReg;
	  node reset = !resetReg;
	  resetReg = Reg(Lit(1));

	  stqEnable = feValid && feWrite;
	  ldqEnable = feValid && !feWrite;
	  freeldqidx= Log2(ldqFree);
	  ldqAvailable = OrN(ldqFree);
	  ldqInsert = Decoder(freeldqidx, ldqEnable);
	  returnSelect = Decoder(returnqidx, memvalid); 
	  for(int i=0; i<Q; ++i)
	  {
		  // TODO ldq bypass on write back path for SIMT (for setting free flag)
		  node ldqWBbypass = (ldqDone[i] && !readyToCommit );
		  node isLeader = returnqidx == ldqLeaders[i];
		  // set free if leader and: fully loaded, no reg stall, or ldqWBbypass
		  // if not leader then free on return select
		  ldqFree[i] = Wreg(reset || (ldqInsert[i]) || ldqDone[i] || returnSelect[i], 
				  reset || ldqDone[i] || (returnSelect[i] && !isLeader) ); 
		  ldqMemaddr[i] = Wreg<L2WORDS>(ldqInsert[i], feMemaddr);
		  ldqiid[i] = Wreg(ldqInsert[i], Mux(feEnable, feiid, in.iid) );
		  ldqdidx[i] = Wreg(ldqInsert[i], Mux(feEnable, fedidx, in.didx));
		  ldqwb[i] = Wreg(ldqInsert[i], Mux(feEnable, fewb, in.wb) );
		  for(int j=0; j<L; ++j)
		  {
			  ldqOffset[j][i] = Wreg(ldqInsert[i], feOffset[j]); 
		  }
		  ldqOffsetValid[i] = Wreg(ldqInsert[i], feOffsetValid); 
		  ldqLeaders[i] = Wreg(ldqInsert[i], Mux(feEnable, ldqLeader, freeldqidx) );
		  ldqLeader = Wreg(feEnable, freeldqidx);

		  ostringstream oss, oss2;
		  oss << "ldqMemaddr" << i;
		  tap(oss.str(), ldqMemaddr[i]);
		  oss2 << "ldqOffsetValid" << i;
		  tap(oss2.str(), ldqOffsetValid[i]);
	  }

	  DBGTAP(reset); DBGTAP(resetReg);
	  DBGTAP(ldqAvailable); DBGTAP(ldqEnable);
	  DBGTAP(ldqInsert);
	  DBGTAP(ldqDone);
	  DBGTAP(ldqFree);
	  DBGTAP(readyToCommit);

	  for(int i=0; i<L; ++i)
	  {
		  ostringstream oss;
		  oss << "memaddr" << i;
		  tap(oss.str(), memaddr[i]);
	  }
  }


template <unsigned L2WORDS>
	void stq(fuInput<N, R, L> in, chdl::vec<L, chdl::bvec<L2WORDS> > memaddr ) {
		const unsigned L2WORDS(CLOG2(SIZE/(N/8)));
		const unsigned OFFSET(CLOG2(L));
		using namespace std;
		using namespace chdl;

		//head/tail pointers into stq
		validStqReq = sendstreq && Mux(tail, stqValid);
		tail = Wreg(validStqReq, tail+Lit<CLOG2(Q)>(1) ); 
		head = Wreg(stqEnable, head+Lit<CLOG2(Q)>(1) ); 
		stqSize = Wreg( Xor(stqEnable, validStqReq), 
				Mux(validStqReq, stqSize+Lit<CLOG2(Q)+1>(1), 
					stqSize+Lit<CLOG2(Q)+1>(0xF)) ); 

		DBGTAP(stqSize); DBGTAP(tail); DBGTAP(head);
		DBGTAP(stqValid); DBGTAP(stqEnable); 
		DBGTAP(validStqReq);
		node stqValidReady = (Mux(tail, stqValid) );
		DBGTAP(stqValidReady);

		//Load Store Forwarding (LSF) and WAR hazard detection
		bvec<Q>  LSFaddrMatch, WARaddrMatch;
		bvec<Q> WARlaneMatch;

		for(int i=0; i<Q; ++i)	//per queue entry
		{
			WARaddrMatch[i] = (feMemaddr == ldqMemaddr[i]) && ldqPending[i];	//conservative
			LSFaddrMatch[i] = (feMemaddr == stqMemaddr[i]) && stqValid[i]; //TODO assumes stq entry is full
		}
#if 1	
		vec<L, bvec<N> > stqQData;
		for(int k=0; k<L; ++k) //per lane
			stqQData[k] = Mux(Log2(LSFaddrMatch), stqData[k]);

		for(int j=0; j<L; ++j) //per lane
		{
			vec<Q, bvec<N> > stqLaneData;
			stqLSFData[j] = Mux(feOffset[j], stqQData);  //TODO arbitrary stq data offset
		}
#else
		for(int j=0; j<L; ++j)
			stqLSFData[j] = Mux(Enc(LSFaddrMatch), stqData[j]);
#endif

		//LSF detection
		enableLSF = OrN(LSFaddrMatch); 
		DBGTAP(enableLSF);
		//WAR detection
		bvec<CLOG2(Q)> dependentLdidx = Log2(WARaddrMatch);
		dependentLd = OrN(WARaddrMatch) && (ldqMemaddrOut != feMemaddr); //assumes feMemaddr is the st address
		bvec<Q> wawMatch;	//Write After Write detection

		stqInsert = Decoder(head, stqEnable);
		for(int i=0; i<Q; ++i)
		{
			wawMatch[i] = feMemaddr == stqMemaddr[i];
			stqMemaddr[i] = Wreg<L2WORDS>(stqInsert[i], feMemaddr);
			for(int j=0; j<L; ++j)	//TODO: allow arbitrary cross-lane stores
			{
				stqData[j][i] = Wreg<N>(stqInsert[i], in.r0[j]); 
				ostringstream oss;
				oss << "stqdata" << i << "_" << j;
				tap(oss.str(), stqData[j][i]);
			}
			stqiid[i] = Wreg(stqInsert[i], Mux(feEnable, feiid, in.iid) );
			clearWait[i] = Mux(stqWaitidx[i], ldqPending);
			stqWaiting[i] = Wreg(stqInsert[i] || !clearWait[i], dependentLd && stqInsert[i]); 
			stqWaitidx[i] = Wreg<CLOG2(Q)>(stqInsert[i], dependentLdidx); 
			stqValid[i] = Wreg(stqInsert[i] || (stqTailSelect[i]) || wawMatch[i], stqInsert[i]);
			for(int j=0; j<L; ++j)
			{
				stqOffsetValid[i][j] = Wreg(stqInsert[i], feOffsetValid[j]); 
				stqOffset[j][i] = Wreg(stqInsert[i], feOffset[j]); 

				ostringstream oss, oss2;
				oss << "stqOffset" << i << "_" << j;
				tap(oss.str(), stqOffset[j][i]);
				oss2 << "stqOffsetValid" << i << "_" << j;
				tap(oss2.str(), stqOffsetValid[i][j]);
			}
			stqOneAddr[i] = Wreg(stqInsert[i], feOneAddr);
		}

		DBGTAP(LSFaddrMatch); 
		DBGTAP(WARaddrMatch); 
		//DBGTAP(stqLSFData); 
		DBGTAP(stqTailSelect); DBGTAP(stqInsert);
	}


	void memoryInterface() {
	  const unsigned L2WORDS(CLOG2(SIZE/(N/8)));
	  const unsigned OFFSET(CLOG2(L));
	  using namespace std;
	  using namespace chdl;
		
		node memStall;
		node ldqPendingFlag = OrN(ldqPending);
		bvec<CLOG2(Q)> pendingldqidx = Mux(ldqPendingFlag, freeldqidx, Log2(ldqPending) );
		bvec<Q> ldqReq = Decoder(pendingldqidx, ldqPendingFlag);

		for(int i=0; i<Q; ++i)
		{
			//ldqPending[i] = 1 when: on insert 
			//ldqPending[i] = 0 when: sent to memory, insert & bypass, or memStall
			// bypass occurs when ldqEmpty or no ldqPending
			ldqPending[i] = Wreg( (ldqInsert[i] ) || (ldqReq[i] && sendldreq ), 
					(ldqInsert[i] && !enableLSF && !ldqPendingFlag && memStall) );
		}

		node WARexists = Mux(tail, stqWaiting);
		//send ld if not store
		//send store ONLY when stq is full, no WAR at tail of stq, AND no ld request (ldq bypass)
#if 1	
		sendldreq = !memStall && ( ldqEnable || 
				!( ( (stqSize == Lit<CLOG2(Q)+1>(Q)) && !WARexists) || !ldqPendingFlag) );
		sendstreq = !sendldreq && !memStall;
#else	
		sendstreq = !ldqEnable && !ldqPendingFlag 
			&& (stqSize == Lit<CLOG2(Q)+1>(Q)) && !WARexists && !memStall;
		sendldreq = !sendstreq && !memStall;
#endif
		stqTailSelect = Decoder(tail, sendstreq);

		ldqMemaddrOut = Mux(!ldqPendingFlag && !enableLSF, Mux(pendingldqidx, ldqMemaddr), 
				feMemaddr);
		bvec<L2WORDS> stqMemaddrOut = Mux(tail, stqMemaddr);
		vec<L, bvec<L2WORDS> > memaddrOut;
		for(int i=0; i<L; ++i)
		{
			bvec<L2WORDS> tempAddr = Mux(sendldreq, stqMemaddrOut, ldqMemaddrOut);//TODO: only 1 addr per cycle or entry
			bvec<OFFSET> stqMemaddrOffset = Mux(tail, stqOffset[i]);
			bvec<OFFSET> ldqMemaddrOffset = Mux(!ldqPendingFlag && !enableLSF, Mux(pendingldqidx, ldqOffset[i]), feOffset[i]);
			bvec<OFFSET> tempOffset = Mux(sendldreq, stqMemaddrOffset, ldqMemaddrOffset);
			memaddrOut[i] =  Cat(tempAddr[range<OFFSET, L2WORDS-1>()], tempOffset );

			ostringstream oss;
			oss << "stqMemaddrOffset" << i;
			tap(oss.str(), stqMemaddrOffset);
		}
		node memValidOut = ldqEnable || ldqPendingFlag || Mux(tail, stqValid); 
		node memWrite = Mux(tail, stqValid) && sendstreq;

		DBGTAP(ldqPending);
		DBGTAP(sendldreq); DBGTAP(sendstreq);
		DBGTAP(stqWaiting);
		DBGTAP(ldqMemaddrOut);

		//when to signal 1 word store?
		//when stq entry only has 1 address - all offsets are the same, or only 1 valid offset
		//node oneWord = sameOffset || oneOffset;

		//TODO: must add latch to memory output
		vec<L, bvec<N> > memLaneDataIn;

                bvec<L> mem_write_mask = Mux(tail, stqOffsetValid);
		bvec<Q> ldqReturnLeader;	
#if INTERNALMEM
		vec<L, bvec<N> > sramout, memDataIn; 
		for(int i=0; i<L; ++i)
		{
			//sramout[i] = Syncmem(memaddrOut[i], Mux(tail, stqData[i]), sendstreq);
			sramout[i] = Syncmem(memaddrOut[i], Mux(tail, stqData[i]), sendstreq  && mem_write_mask[i]); //NN Check
			memLaneDataIn[i] = delay(sramout[i], DELAY-1);

			DBGTAP(sramout[i]);
			DBGTAP(memLaneDataIn[i]);
			ostringstream oss, oss2;
			oss << "memaddrOut" << "_" <<i;
			tap(oss.str(), memaddrOut[i]);
			oss2 << "mem_write_mask"<<"_"<< i;
			tap(oss2.str(), sendstreq  && mem_write_mask[i]);
		}
		returnqidx = delay(pendingldqidx, DELAY);
		memvalid = delay(memValidOut && sendldreq, DELAY);
#else
		bvec<N*L> > sramout, memDataIn; 
		memDataIn = Input<L*N>("memDataIn"); 
		returnqidx = Input<CLOG2(Q)>("memqidIn"); 
		memvalid = Input("memValidIn");
		memStall = Input("memStall");
		//output? memaddrOut

		for(int i=0; i<L; ++i) 	
			for(int j=0; j<N; ++j) 
				memLaneDataIn[i][j] = memDataIn[i*N+j];

		TAP(memaddrOut); TAP(memWrite); TAP(memValidOut); TAP(pendingldqidx); 
#endif

		bvec<CLOG2(Q)> leaderqidx = Mux(returnqidx, ldqLeaders);
		ldqReturnLeader = Decoder(leaderqidx, memvalid);

		for(int i=0; i<Q; ++i) 	
		{
			bvec<L> laneOffsetValids = Mux(returnqidx, ldqOffsetValid);
			vec<L, bvec<OFFSET> > laneOffsets;
			for(int j=0; j<L; ++j)	//per lane
			{	
				node ldqLaneMemLoad = (ldqReturnLeader[i] && laneOffsetValids[j]); 
				//ldqLaneLoaded - set on ldqInsert (LSF), data from memory
				//				- unset on ldqDone (committed to WB)
				ldqLaneLoaded[i][j] = 
					Wreg( ldqInsert[i] || ldqLaneMemLoad || ldqDone[i], 
							(ldqInsert[i] && enableLSF) || (ldqLaneMemLoad ) );

				bvec<N> laneData = Mux( Mux(returnqidx, ldqOffset[j]), memLaneDataIn);
				ldqData[j][i] = 
					Wreg<N>( (ldqReturnLeader[i] && laneOffsetValids[j]) || ldqInsert[i], 
					Mux(ldqInsert[i], laneData, stqLSFData[j]) ); 

				ostringstream oss, oss2;
				oss << "ldqdata" << i << "_" << j;
				tap(oss.str(), ldqData[j][i]);
				oss2 << "ldqOffset" << i << "_" << j;
				tap(oss2.str(), ldqOffset[j][i]);
			}
		}

		DBGTAP(pendingldqidx); DBGTAP(returnqidx);
		DBGTAP(memvalid); 
		DBGTAP(memValidOut); 
		DBGTAP(ldqPendingFlag);
		DBGTAP(ldqReturnLeader);
	}


	fuOutput<N, R, L> commit(chdl::node stall) {
	  const unsigned L2WORDS(CLOG2(SIZE/(N/8)));
	  const unsigned OFFSET(CLOG2(L));
	  using namespace std;
	  using namespace chdl;
	  fuOutput<N, R, L> o;
	  node regStall = Reg(stall);	
	  node ldqLoadedFlag = OrN(ldqLoaded);
	  bvec<CLOG2(Q)> loadedldqidx = Log2(ldqLoaded);
	  bvec<Q> ldqCommit = Decoder(loadedldqidx, ldqLoadedFlag);

	  for(int i=0; i<Q; ++i)
	  {
		  ldqLoaded[i] = AndN(ldqLaneLoaded[i]);
		  ldqDone[i] = ldqCommit[i] && !regStall;
		  ostringstream oss;
		  oss << "ldqLoaded" << i;
		  tap(oss.str(), ldqLoaded[i]);
	  }
	  readyToCommit = OrN(ldqDone); 

	  isReady = (feEmpty || feCoalesced) && ldqAvailable && stqSize != Lit<CLOG2(Q)+1>(Q); 
	  DBGTAP(isReady);	
	  DBGTAP(stall);	

	  vec<L, bvec<N> > wbData; 
	  for(int j=0; j<L; ++j)
	  {
		  wbData[j] = Mux(loadedldqidx, ldqData[j]);
		  o.out[j] = (wbData[j]); //Mux(readyToCommit, memDataIn, wbData[j]); TODO support wb bypass
		  /*ostringstream oss;
			oss << "data " << j;
			tap(oss.str(), o.out[j]);
		   */
	  }

	  DBGTAP(o.out[0]);
	  DBGTAP(o.out[1]);
	  DBGTAP(o.out[2]);
	  DBGTAP(o.out[3]);
	  o.valid = (readyToCommit);// TODO support wb bypass || memvalid;
	  o.iid = (Mux(readyToCommit, Mux(returnqidx, ldqiid), Mux(loadedldqidx, ldqiid) ) );
	  o.didx = (Mux(readyToCommit, Mux(returnqidx, ldqdidx), Mux(loadedldqidx, ldqdidx) ) );
	  o.wb = (Mux(readyToCommit, Mux(returnqidx, ldqwb), Mux(loadedldqidx, ldqwb) ) );
	  DBGTAP(o.valid);
	  DBGTAP(o.iid);
	  DBGTAP(o.didx);
	  bvec<IDLEN> returnqiid = Mux(returnqidx, ldqiid);
	  bvec<IDLEN> loadedqiid = Mux(loadedldqidx, ldqiid);
	  DBGTAP(returnqiid);
	  DBGTAP(loadedqiid);

	  return o;
	}
	
  virtual fuOutput<N, R, L> generate(fuInput<N, R, L> in, chdl::node valid) {
    const unsigned L2WORDS(CLOG2(SIZE/(N/8)));
	const unsigned OFFSET(CLOG2(L));

	using namespace std;
	using namespace chdl;

    hierarchy_enter("SramLsu");

    fuOutput<N, R, L> o;

    node w(!in.stall);

    bvec<6> op(in.op);
    bvec<N> imm(in.imm);

	vec<L, bvec<L2WORDS> > memaddr;
    for (unsigned i = 0; i < L; ++i) {
      bvec<N> r0(in.r0[i]), r1(in.r1[i]), imm(in.imm),
              addr(imm + Mux(op[0], r1, r0));
      memaddr[i] = (Zext<L2WORDS>(addr[range<CLOG2(N/8), N-1>()]));
      bvec<CLOG2(N)> memshift(Lit<CLOG2(N)>(8) *
                                Zext<CLOG2(N)>(addr[range<0, CLOG2(N/8)-1>()]));

      bvec<N> sramout = Syncmem(memaddr[i], r0, valid && !op[0], "rom.hex");

      o.out[i] = sramout >> Reg(memshift);

      // Simple character output from lane 0.
      if (i == 0) {
        node io(addr[N-1]), io_wr(valid && !op[0]),
             char_out(io_wr && addr[range<0, N-2>()] == Lit<N-1>(0));
        bvec<7> char_out_val(r0[range<0, 6>()]);
        TAP(char_out);
        TAP(char_out_val);
      }
    }

	  isReady = Lit(1);
#if 1 
	  DBGTAP(in.iid); DBGTAP(in.didx);
	  DBGTAP(valid); DBGTAP(op);

	  frontEnd(in, memaddr, !op[0], valid);

	  ldq(in, memaddr); 

	  stq(in, memaddr);	  

	  memoryInterface();

	  o = commit(in.stall);
	
#else
	  o.valid = Wreg(w, valid && op[0]);
	  o.iid = Wreg(w, in.iid);
	  o.didx = Wreg(w, in.didx);
	  o.wb = Wreg(w, in.wb); 
#endif
	  o.pdest = Wreg(w, in.pdest);

    hierarchy_exit();

    return o;
  }
  virtual chdl::node ready() { return isReady; }
 private:
	chdl::node isReady;
  #define OFFSET CLOG2(L)
  #define L2WORDS CLOG2(SIZE/(N/8))
  //front end variables
  chdl::bvec<L2WORDS> feMemaddr;
  chdl::vec<L, chdl::bvec<OFFSET> > feOffset;
  chdl::bvec<L> feOffsetValid;
  chdl::node feValid;
  chdl::node feWrite;
  chdl::bvec<CLOG2(R)> fedidx;
  chdl::bvec<IDLEN> feiid;
  chdl::node feCoalesced;
  chdl::node feEmpty;
  chdl::node feEnable;
  chdl::bvec<L> fewb;
  chdl::node feOneAddr;
  
  // load queue
  chdl::vec<L, chdl::vec<Q, chdl::bvec<N> > > ldqData;
  chdl::vec<Q, chdl::bvec<CLOG2(R)> > ldqdidx;
  chdl::vec<Q, chdl::bvec<IDLEN> > ldqiid;
  chdl::vec<Q, chdl::bvec<L> > ldqwb;
  chdl::vec<Q, chdl::bvec<L2WORDS> > ldqMemaddr;
  chdl::vec<L, chdl::vec<Q, chdl::bvec<OFFSET> > > ldqOffset;
  chdl::vec<Q, chdl::bvec<L> > ldqOffsetValid, ldqLaneLoaded;
  chdl::bvec<Q> ldqFree, ldqDone, ldqInsert, ldqPending, ldqLoaded, returnSelect;
  chdl::vec<Q, chdl::bvec<CLOG2(Q)> > ldqLeaders;
  chdl::bvec<CLOG2(Q)> ldqLeader;

  // misc ldq signals
  chdl::node memvalid;					//data from mem is valid 
  chdl::node readyToCommit; 			//have loaded ldq entry for commit
  chdl::node stqEnable, ldqEnable;  	//write enable for insertion
  chdl::bvec<CLOG2(Q)> freeldqidx, returnqidx; //qid of data from mem
  chdl::bvec<L2WORDS> ldqMemaddrOut; 
  chdl::node ldqAvailable;

  // store queue
  chdl::node dependentLd;
  chdl::node sendldreq, sendstreq;
  chdl::node validStqReq; 		//output to memory arbitration select signal
  chdl::bvec<Q> stqInsert, stqWaiting, stqValid, clearWait, stqTailSelect, stqOneAddr;
  chdl::vec<L, chdl::vec<Q, chdl::bvec<N> > > stqData;
  chdl::vec<Q, chdl::bvec<IDLEN> > stqiid;
  chdl::vec<Q, chdl::bvec<CLOG2(Q)> > stqWaitidx;
  chdl::vec< Q, chdl::bvec<L2WORDS> > stqMemaddr;
  chdl::bvec<CLOG2(Q)+1> stqSize;
  chdl::bvec<CLOG2(Q)> head, tail;
  chdl::vec<L, chdl::vec<Q, chdl::bvec<OFFSET> > > stqOffset;
  chdl::vec<Q, chdl::bvec<L> > stqOffsetValid;

  // load store forwarding
  chdl::node enableLSF;
  chdl::vec<L, chdl::bvec<N> > stqLSFData;
};


#endif
