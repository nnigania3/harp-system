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

static const unsigned Q(8);
static const unsigned DELAY(8);

#ifdef USE_CACHE
#define INTERNALMEM 0
#else
#define INTERNALMEM 1
#endif

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

          #ifdef DEBUG
	  for(int i=0; i<L; ++i)
		  TAP(feOffset[i]);
          #endif
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
          #ifdef DEBUG
	  for(int i=0; i<L; ++i) DBGTAP(feAddr[i]);
          #endif

	  feEnable = valid && isReady;
	  feInsertidx = Log2(feAddrValid);
	  feInsertSelect = Decoder(feInsertidx, feEnable);
	  feEmpty = !OrN(feAddrValid);
	  
	  inMemaddrSelect = Decoder(Log2(in.wb), feEnable);
	  inMemaddr = Mux(Log2(in.wb), memaddr);
	  feMemaddr = Mux(feEnable, Mux(feInsertidx, feAddr), inMemaddr ); 
	  feCoalesced = AndN(coalescedMatch); 			//NN check this logic!
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
		  feData[i] = Wreg(feEnable, in.r0[i]);
		  feOffset[i] = Mux(feEnable, feAddr[i][range<0,OFFSET-1>()], 
				  memaddr[i][range<0,OFFSET-1>()]); 
		  
		  coalescedMatch[i] = 
		      (memaddr[0][range<OFFSET, L2WORDS-1>()] == memaddr[i][range<OFFSET, L2WORDS-1>()])
			  && feAddrValid[i]; //NN fixed, memaddr is only L2WORDS wide but we were indexing it till N which caused segfault //NN check, shouldnt we check with memaddr[L-1]
		  /*coalescedMatch[i] = 
		      (memaddr[0][range<OFFSET, N>()] == memaddr[i][range<OFFSET, N>()])
			  && feAddrValid[i];*/
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
	  ldqAllFree = AndN(ldqFree);
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

                  //Load req wait logic, when partial match with a store
                  ldqclearWait[i] = Mux(ldqWaitidx[i], stqValid); 
                  ldqRAWwait[i] = Wreg(ldqInsert[i] || !ldqclearWait[i], dependentSt && ldqInsert[i]); 
                  ldqWaitidx[i] = Wreg<CLOG2(Q)>(ldqInsert[i], dependentStidx); 

	  }


	  DBGTAP(reset); DBGTAP(resetReg);
	  DBGTAP(ldqAvailable); DBGTAP(ldqEnable); DBGTAP(ldqAllFree);
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
					stqSize+Lit<CLOG2(Q)+1>(0xF)) ); //NN check

		DBGTAP(stqSize); DBGTAP(tail); DBGTAP(head);
		DBGTAP(stqValid); DBGTAP(stqEnable); 
		DBGTAP(validStqReq);
		node stqValidReady = (Mux(tail, stqValid) );
		DBGTAP(stqValidReady);

		//Load Store Forwarding (LSF) and WAR hazard detection
		bvec<Q>  LSFaddrMatch, WARaddrMatch, RAWaddrMatch;
		bvec<Q> WARlaneMatch;

		for(int i=0; i<Q; ++i)	//per queue entry
		{
			WARaddrMatch[i] = (feMemaddr == ldqMemaddr[i]) && ldqPending[i];	//conservative
			//LSFaddrMatch[i] = (feMemaddr == stqMemaddr[i]) && stqValid[i]; //TODO assumes stq entry is full
                        node addrmatch  = (feMemaddr == stqMemaddr[i]) && stqValid[i]; // NN check
			LSFaddrMatch[i] =  addrmatch && stqOneAddr[i]; //NN 
			RAWaddrMatch[i] =  addrmatch && !stqOneAddr[i]; //NN TODO lsf only when stq coalesced, else make ldq wait!
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

		//RAW detection for partial Ld->St conflict and no LSF
		dependentStidx = Log2(RAWaddrMatch);
		dependentSt = OrN(RAWaddrMatch) && (stqMemaddrOut != feMemaddr); //assumes feMemaddr is the st address
		enableRAW = OrN(RAWaddrMatch); 
		DBGTAP(enableRAW);

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
	                        bvec<N> lane_data = Mux(feEnable, feData[j], in.r0[j]); 
				stqData[j][i] = Wreg<N>(stqInsert[i], lane_data); 
				ostringstream oss;
				oss << "stqdata" << i << "_" << j;
				tap(oss.str(), stqData[j][i]);
			}
			stqiid[i] = Wreg(stqInsert[i], Mux(feEnable, feiid, in.iid) );
			clearWait[i] = Mux(stqWaitidx[i], ldqPending);
			stqWaiting[i] = Wreg(stqInsert[i] || !clearWait[i], dependentLd && stqInsert[i]); 
			stqWaitidx[i] = Wreg<CLOG2(Q)>(stqInsert[i], dependentLdidx); 
			//stqValid[i] = Wreg(stqInsert[i] || (stqTailSelect[i]) || wawMatch[i], stqInsert[i]);
			stqValid[i] = Wreg(stqInsert[i] || (stqTailSelect[i]), stqInsert[i]);	//NN check,  why we need waw in earlier statement, if we diable stqValid and dont send any 'validStqReq' then we stqsize wont decrement and we will end up consuming stqSpace! but then this waw might cause problem for LSF!
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
			ostringstream oss, oss2;
			oss << "stqValid" << i;
			tap(oss.str(), stqValid[i]);
			oss2 << "wawMatch" << i;
			tap(oss2.str(), wawMatch[i]);
		}

		DBGTAP(LSFaddrMatch); 
		DBGTAP(WARaddrMatch); 
		DBGTAP(RAWaddrMatch); 
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
					(ldqInsert[i] && !enableLSF                      && (memStall || ldqPendingFlag)));
					//(ldqInsert[i] && !enableLSF && !ldqPendingFlag && memStall) );
		}

		node WARexists = Mux(tail, stqWaiting);
		node RAWexists = Mux(pendingldqidx, ldqRAWwait);//NN check

		//send ld if not store
		//send store ONLY when stq is full, no WAR at tail of stq, AND no ld request (ldq bypass)
#if 1	
		sendldreq = !memStall && ( ldqEnable || 
				!( ( (stqSize == Lit<CLOG2(Q)+1>(Q)) && !WARexists) || !ldqPendingFlag) ); 
		sendstreq = !sendldreq && !memStall;
#else	
		sendldreq = !memStall && ( (ldqEnable && !enableLSF && !enableRAW) || 
				!( ( (stqSize == Lit<CLOG2(Q)+1>(Q)) && !WARexists) || !(ldqPendingFlag && !RAWexists )) ); //NN check, even when LSF and when data inserted in ldq why is load req sent?
		sendstreq = !sendldreq && !memStall && Mux(tail, stqValid);
		//sendstreq = !ldqEnable && !ldqPendingFlag 
		//	&& (stqSize == Lit<CLOG2(Q)+1>(Q)) && !WARexists && !memStall;
#endif
		stqTailSelect = Decoder(tail, sendstreq);

		ldqMemaddrOut = Mux(!ldqPendingFlag && !enableLSF, Mux(pendingldqidx, ldqMemaddr), 
				feMemaddr);
		stqMemaddrOut = Mux(tail, stqMemaddr);
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
		//node memValidOut = (ldqEnable && !enableLSF && !enableRAW) || (ldqPendingFlag && !RAWexists ) || Mux(tail, stqValid); //NN check, add mem stall condition
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

		bvec<Q> ldqReturnLeader;	
#if INTERNALMEM
                bvec<L> mem_valid_word = Mux(tail, stqOffsetValid);
		vec<L, bvec<N> > sramout, memDataIn; 
		for(int i=0; i<L; ++i)
		{
			//sramout[i] = Syncmem(memaddrOut[i], Mux(tail, stqData[i]), sendstreq);
			sramout[i] = Syncmem(memaddrOut[i], Mux(tail, stqData[i]), memWrite  && mem_valid_word[i]); //NN Check
			memLaneDataIn[i] = delay(sramout[i], DELAY-1);

                        #ifdef DEBUG
			DBGTAP(sramout[i]);
                        #endif
			//DBGTAP(memLaneDataIn[i]);
			ostringstream oss, oss2, oss3;
			oss << "memaddrOut" << "_" <<i;
			tap(oss.str(), memaddrOut[i]);
			oss3 << "memLaneDataIn" << "_" <<i;
			tap(oss3.str(), memLaneDataIn[i]);
			oss2 << "mem_lane_valid"<<"_"<< i;
			tap(oss2.str(), memWrite && mem_valid_word[i]);
		}
		returnqidx = delay(pendingldqidx, DELAY);
		memvalid = delay(memValidOut && sendldreq, DELAY);
#else

                memStall            = Input("cache_stall_in");
                bvec<1> reset_in    = Input<1>("reset_in");    
                returnqidx          = Input<CLOG2(Q)>("cache_id_in");
                memvalid            = Input ("cache_ready_in");
                bvec<N*L> memDataIn = Input<N*L>("cache_data_in");

		bvec<N*L> cache_data_out;
                bvec<L> cache_valid_word;
                node cache_rw_out = memWrite;
                node cache_valid_out = memWrite || sendldreq;  //sendldreq||sendstreq
                bvec<CLOG2(Q)> cache_id_out = pendingldqidx; //NN change this so we send unique id for stores as well?
                node cache_reset_n = !reset_in[0];
                //bvec<CLOG2(N/8) + OFFSET> tempOffset = Lit<OFFSET + CLOG2(N/8)>(0)
		bvec<N> cache_addr_out = Zext<N>(Cat(memaddrOut[0][range<OFFSET, L2WORDS-1>()], Lit<OFFSET + CLOG2(N/8)>(0)));  //NN check, offset bits not needed still do it make it zero? add byte/word bits
		//memaddrOut[i] =  Cat(tempAddr[range<OFFSET, L2WORDS-1>()], tempOffset );
		vec<L, bvec<N>> temp_cache_data_out;// = Mux(tail, stqData[i]);
                bvec<L> mem_offset_valid = Mux(tail, stqOffsetValid);
                bvec<L> error;

		for(int i=0; i<L; ++i)
		{
			////For Coalsced accesses!
                        //bvec<OFFSET> word_sel = Mux(tail, stqOffset[i]);
                        //temp_cache_data_out[i] = Mux(tail, stqData[i]);
                        //cache_valid_word[i]    = mem_offset_valid[i];
                        bvec<OFFSET> word_sel;
                        bvec<L> selbits;
                        vec<L, bvec<N>> seldata;
                        for (unsigned j = 0; j < L; ++j){
                          selbits[j] = mem_offset_valid[j] && (Mux(tail, stqOffset[j]) == Lit<OFFSET>(i));
                          seldata[j] = Mux(tail, stqData[j]);
                        }

                        cache_valid_word[i] = OrN(selbits);

                        // Error if more than one bit set. OK if 0 bits are set.
                        error[i] = OrN(selbits & (selbits - Lit<L>(1))) && cache_valid_word[i];

                        word_sel = Enc(selbits);
                        temp_cache_data_out[i] = Mux(word_sel, seldata);
                        
			ostringstream oss, oss2, oss3;
			oss << "wordsel" << "_" <<i;
			tap(oss.str(), word_sel);
			oss2 << "Cache_data_out" << "_" <<i;
			tap(oss2.str(), temp_cache_data_out[i]);
			oss3 << "memaddrOut" << "_" <<i;
			tap(oss3.str(), memaddrOut[i]);
                }
                TAP(error);
                OUTPUT(cache_reset_n);
                OUTPUT(cache_addr_out);
                OUTPUT(cache_data_out);
                OUTPUT(cache_rw_out);
                OUTPUT(cache_valid_out);
                OUTPUT(cache_id_out);
                OUTPUT(cache_valid_word);
   
		for(int i=0; i<L; ++i) 	
			for(int j=0; j<N; ++j){
                                cache_data_out[i * N + j] = temp_cache_data_out[i][j];
				memLaneDataIn[i][j] = memDataIn[i*N+j];
                        }

	//	TAP(memaddrOut); TAP(memWrite); TAP(memValidOut); TAP(pendingldqidx); 
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

#if INTERNALMEM
				bvec<N> laneData = memLaneDataIn[j];
#else
				bvec<N> laneData = Mux( Mux(returnqidx, ldqOffset[j]), memLaneDataIn);
#endif
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

	  //isReady = (feEmpty || feCoalesced) && ldqAvailable && stqSize != Lit<CLOG2(Q)+1>(Q); 
	  isReady = (feEmpty || feCoalesced) && ldqAllFree && (stqSize <= Lit<CLOG2(Q)+1>(Q-L)); //NN check stqsize < Q - L, TODO: add logic for L ldqFree entries
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

	  o.valid = (readyToCommit);// TODO support wb bypass || memvalid;
	  o.iid = (Mux(readyToCommit, Mux(returnqidx, ldqiid), Mux(loadedldqidx, ldqiid) ) );
	  o.didx = (Mux(readyToCommit, Mux(returnqidx, ldqdidx), Mux(loadedldqidx, ldqdidx) ) );
	  o.wb = (Mux(readyToCommit, Mux(returnqidx, ldqwb), Mux(loadedldqidx, ldqwb) ) );
          #ifdef DEBUG
	  DBGTAP(o.out[0]);
	  DBGTAP(o.out[1]);
	  DBGTAP(o.out[2]);
	  DBGTAP(o.out[3]);
	  DBGTAP(o.valid);
	  DBGTAP(o.iid);
	  DBGTAP(o.didx);
          #endif
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

      //bvec<N> sramout = Syncmem(memaddr[i], r0, valid && !op[0], "rom.hex");

      ////o.out[i] = sramout >> Reg(memshift);

      // Simple character output from lane 0.
      if (i == 0) {
        node io(addr[N-1]), io_wr(valid && !op[0]),
             char_out(io_wr && addr[range<0, N-2>()] == Lit<N-1>(0));
        bvec<7> char_out_val(r0[range<0, 6>()]);
        OUTPUT(char_out);
        TAP(addr);
        OUTPUT(char_out_val);
      }
    }

//	  isReady = Lit(1); //NN check, why were we doing this?
#if 1 
          #ifdef DEBUG
	  DBGTAP(in.iid); DBGTAP(in.didx);
          #endif
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
  chdl::vec<L, chdl::bvec<N> > feData;
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
  chdl::node ldqAllFree;
  chdl::node dependentSt;
  chdl::bvec<CLOG2(Q)> dependentStidx;
  chdl::bvec<Q> ldqRAWwait, ldqclearWait;
  chdl::vec<Q, chdl::bvec<CLOG2(Q)> > ldqWaitidx;

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
  chdl::bvec<L2WORDS> stqMemaddrOut; 

  // load store forwarding
  chdl::node enableLSF;
  chdl::node enableRAW;
  chdl::vec<L, chdl::bvec<N> > stqLSFData;
};


#endif
