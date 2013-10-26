
# (C) 2001-2013 Altera Corporation. All rights reserved.
# Your use of Altera Corporation's design tools, logic functions and 
# other software and tools, and its AMPP partner logic functions, and 
# any output files any of the foregoing (including device programming 
# or simulation files), and any associated documentation or information 
# are expressly subject to the terms and conditions of the Altera 
# Program License Subscription Agreement, Altera MegaCore Function 
# License Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by Altera 
# or its authorized distributors. Please refer to the applicable 
# agreement for further details.

# ACDS 13.0sp1 232 win32 2013.08.30.12:08:16

# ----------------------------------------
# Auto-generated simulation script

# ----------------------------------------
# Initialize the variable
if ![info exists SYSTEM_INSTANCE_NAME] { 
  set SYSTEM_INSTANCE_NAME ""
} elseif { ![ string match "" $SYSTEM_INSTANCE_NAME ] } { 
  set SYSTEM_INSTANCE_NAME "/$SYSTEM_INSTANCE_NAME"
} 

if ![info exists TOP_LEVEL_NAME] { 
  set TOP_LEVEL_NAME "ddr2_ctrl_test_example_sim"
} 

if ![info exists QSYS_SIMDIR] { 
  set QSYS_SIMDIR "./../"
} 

if ![info exists QUARTUS_INSTALL_DIR] { 
  set QUARTUS_INSTALL_DIR "C:/altera/13.0sp1/quartus/"
} 


# ----------------------------------------
# Copy ROM/RAM files to simulation directory
alias file_copy {
  echo "\[exec\] file_copy"
  file copy -force $QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_sequencer_mem.hex ./
  file copy -force $QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_AC_ROM.hex ./
  file copy -force $QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_inst_ROM.hex ./
}

# ----------------------------------------
# Create compilation libraries
proc ensure_lib { lib } { if ![file isdirectory $lib] { vlib $lib } }
ensure_lib          ./libraries/     
ensure_lib          ./libraries/work/
vmap       work     ./libraries/work/
vmap       work_lib ./libraries/work/
if { ![ string match "*ModelSim ALTERA*" [ vsim -version ] ] } {
  ensure_lib                  ./libraries/altera_ver/      
  vmap       altera_ver       ./libraries/altera_ver/      
  ensure_lib                  ./libraries/lpm_ver/         
  vmap       lpm_ver          ./libraries/lpm_ver/         
  ensure_lib                  ./libraries/sgate_ver/       
  vmap       sgate_ver        ./libraries/sgate_ver/       
  ensure_lib                  ./libraries/altera_mf_ver/   
  vmap       altera_mf_ver    ./libraries/altera_mf_ver/   
  ensure_lib                  ./libraries/altera_lnsim_ver/
  vmap       altera_lnsim_ver ./libraries/altera_lnsim_ver/
  ensure_lib                  ./libraries/stratixiii_ver/  
  vmap       stratixiii_ver   ./libraries/stratixiii_ver/  
}


# ----------------------------------------
# Compile device library files
alias dev_com {
  echo "\[exec\] dev_com"
  if { ![ string match "*ModelSim ALTERA*" [ vsim -version ] ] } {
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_primitives.v" -work altera_ver      
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/220model.v"          -work lpm_ver         
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/sgate.v"             -work sgate_ver       
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_mf.v"         -work altera_mf_ver   
    vlog -sv "$QUARTUS_INSTALL_DIR/eda/sim_lib/altera_lnsim.sv"     -work altera_lnsim_ver
    vlog     "$QUARTUS_INSTALL_DIR/eda/sim_lib/stratixiii_atoms.v"  -work stratixiii_ver  
  }
}

# ----------------------------------------
# Compile the design files in correct order
alias com {
  echo "\[exec\] com"
  vlog                                        "$QSYS_SIMDIR/submodules/alt_mem_ddrx_mm_st_converter.v"                                       
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_addr_cmd.v"                                              
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_addr_cmd_wrap.v"                                         
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_ddr2_odt_gen.v"                                          
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_ddr3_odt_gen.v"                                          
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_lpddr2_addr_cmd.v"                                       
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_odt_gen.v"                                               
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_rdwr_data_tmg.v"                                         
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_arbiter.v"                                               
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_burst_gen.v"                                             
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_cmd_gen.v"                                               
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_csr.v"                                                   
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_buffer.v"                                                
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_buffer_manager.v"                                        
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_burst_tracking.v"                                        
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_dataid_manager.v"                                        
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_fifo.v"                                                  
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_list.v"                                                  
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_rdata_path.v"                                            
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_wdata_path.v"                                            
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_ecc_decoder.v"                                           
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_ecc_decoder_32_syn.v"                                    
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_ecc_decoder_64_syn.v"                                    
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_ecc_encoder.v"                                           
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_ecc_encoder_32_syn.v"                                    
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_ecc_encoder_64_syn.v"                                    
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_ecc_encoder_decoder_wrapper.v"                           
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_axi_st_converter.v"                                      
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_input_if.v"                                              
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_rank_timer.v"                                            
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_sideband.v"                                              
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_tbp.v"                                                   
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_timing_param.v"                                          
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_controller.v"                                            
  vlog     "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_ddrx_controller_st_top.v"                                     
  vlog -sv "+incdir+$QSYS_SIMDIR/submodules/" "$QSYS_SIMDIR/submodules/alt_mem_if_nextgen_ddr2_controller_core.sv"                           
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_dmaster_p2b_adapter.v"              
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_dmaster_b2p_adapter.v"              
  vlog                                        "$QSYS_SIMDIR/submodules/altera_avalon_packets_to_master.v"                                    
  vlog                                        "$QSYS_SIMDIR/submodules/altera_avalon_st_packets_to_bytes.v"                                  
  vlog                                        "$QSYS_SIMDIR/submodules/altera_avalon_st_bytes_to_packets.v"                                  
  vlog                                        "$QSYS_SIMDIR/submodules/altera_avalon_sc_fifo.v"                                              
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_dmaster_timing_adt.v"               
  vlog                                        "$QSYS_SIMDIR/submodules/altera_avalon_st_jtag_interface.v"                                    
  vlog                                        "$QSYS_SIMDIR/submodules/altera_jtag_dc_streaming.v"                                           
  vlog                                        "$QSYS_SIMDIR/submodules/altera_jtag_sld_node.v"                                               
  vlog                                        "$QSYS_SIMDIR/submodules/altera_jtag_streaming.v"                                              
  vlog                                        "$QSYS_SIMDIR/submodules/altera_pli_streaming.v"                                               
  vlog                                        "$QSYS_SIMDIR/submodules/altera_avalon_st_clock_crosser.v"                                     
  vlog                                        "$QSYS_SIMDIR/submodules/altera_avalon_st_pipeline_base.v"                                     
  vlog                                        "$QSYS_SIMDIR/submodules/altera_avalon_st_idle_remover.v"                                      
  vlog                                        "$QSYS_SIMDIR/submodules/altera_avalon_st_idle_inserter.v"                                     
  vlog -sv                                    "$QSYS_SIMDIR/submodules/driver_definitions.sv"                                                
  vlog -sv                                    "$QSYS_SIMDIR/submodules/addr_gen.sv"                                                          
  vlog -sv                                    "$QSYS_SIMDIR/submodules/burst_boundary_addr_gen.sv"                                           
  vlog -sv                                    "$QSYS_SIMDIR/submodules/lfsr.sv"                                                              
  vlog -sv                                    "$QSYS_SIMDIR/submodules/lfsr_wrapper.sv"                                                      
  vlog -sv                                    "$QSYS_SIMDIR/submodules/rand_addr_gen.sv"                                                     
  vlog -sv                                    "$QSYS_SIMDIR/submodules/rand_burstcount_gen.sv"                                               
  vlog -sv                                    "$QSYS_SIMDIR/submodules/rand_num_gen.sv"                                                      
  vlog -sv                                    "$QSYS_SIMDIR/submodules/rand_seq_addr_gen.sv"                                                 
  vlog                                        "$QSYS_SIMDIR/submodules/reset_sync.v"                                                         
  vlog -sv                                    "$QSYS_SIMDIR/submodules/scfifo_wrapper.sv"                                                    
  vlog -sv                                    "$QSYS_SIMDIR/submodules/seq_addr_gen.sv"                                                      
  vlog -sv                                    "$QSYS_SIMDIR/submodules/template_addr_gen.sv"                                                 
  vlog -sv                                    "$QSYS_SIMDIR/submodules/template_stage.sv"                                                    
  vlog -sv                                    "$QSYS_SIMDIR/submodules/driver_csr.sv"                                                        
  vlog -sv                                    "$QSYS_SIMDIR/submodules/avalon_traffic_gen_avl_use_be_avl_use_burstbegin.sv"                  
  vlog -sv                                    "$QSYS_SIMDIR/submodules/block_rw_stage_avl_use_be_avl_use_burstbegin.sv"                      
  vlog -sv                                    "$QSYS_SIMDIR/submodules/driver_avl_use_be_avl_use_burstbegin.sv"                              
  vlog -sv                                    "$QSYS_SIMDIR/submodules/driver_fsm_avl_use_be_avl_use_burstbegin.sv"                          
  vlog -sv                                    "$QSYS_SIMDIR/submodules/read_compare_avl_use_be_avl_use_burstbegin.sv"                        
  vlog -sv                                    "$QSYS_SIMDIR/submodules/single_rw_stage_avl_use_be_avl_use_burstbegin.sv"                     
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_mem_if_dll_stratixiii.sv"                                      
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_mem_if_oct_stratixiii.sv"                                      
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_c0.v"                               
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_dmaster.v"                          
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0.v"                               
  vlog                                        "$QSYS_SIMDIR/submodules/altera_avalon_mm_bridge.v"                                            
  vlog                                        "$QSYS_SIMDIR/submodules/altera_mem_if_sequencer_cpu_no_ifdef_params_sim_cpu_inst.v"           
  vlog                                        "$QSYS_SIMDIR/submodules/altera_mem_if_sequencer_cpu_no_ifdef_params_sim_cpu_inst_test_bench.v"
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_mem_if_sequencer_mem_no_ifdef_params.sv"                       
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_mem_if_sequencer_rst.sv"                                       
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_merlin_arbitrator.sv"                                          
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_merlin_burst_uncompressor.sv"                                  
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_merlin_master_agent.sv"                                        
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_merlin_slave_agent.sv"                                         
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_merlin_traffic_limiter.sv"                                     
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_addr_router.sv"                  
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_addr_router_001.sv"              
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_addr_router_002.sv"              
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_cmd_xbar_demux.sv"               
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_cmd_xbar_demux_001.sv"           
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_cmd_xbar_demux_002.sv"           
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_cmd_xbar_mux_003.sv"             
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_cmd_xbar_mux_005.sv"             
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_id_router.sv"                    
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_id_router_003.sv"                
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_id_router_005.sv"                
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_irq_mapper.sv"                   
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_rsp_xbar_demux_003.sv"           
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_rsp_xbar_demux_005.sv"           
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_rsp_xbar_mux.sv"                 
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_s0_rsp_xbar_mux_001.sv"             
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_ac_ROM_no_ifdef_params.v"                                  
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_ac_ROM_reg.v"                                              
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_bitcheck.v"                                                
  vlog -sv                                    "$QSYS_SIMDIR/submodules/rw_manager_core.sv"                                                   
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_datamux.v"                                                 
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_data_broadcast.v"                                          
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_data_decoder.v"                                            
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_ddr2.v"                                                    
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_di_buffer.v"                                               
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_di_buffer_wrap.v"                                          
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_dm_decoder.v"                                              
  vlog -sv                                    "$QSYS_SIMDIR/submodules/rw_manager_generic.sv"                                                
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_inst_ROM_no_ifdef_params.v"                                
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_inst_ROM_reg.v"                                            
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_jumplogic.v"                                               
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_lfsr12.v"                                                  
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_lfsr36.v"                                                  
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_lfsr72.v"                                                  
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_pattern_fifo.v"                                            
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_ram.v"                                                     
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_ram_csr.v"                                                 
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_read_datapath.v"                                           
  vlog                                        "$QSYS_SIMDIR/submodules/rw_manager_write_decoder.v"                                           
  vlog -sv                                    "$QSYS_SIMDIR/submodules/sequencer_data_mgr.sv"                                                
  vlog -sv                                    "$QSYS_SIMDIR/submodules/sequencer_phy_mgr.sv"                                                 
  vlog -sv                                    "$QSYS_SIMDIR/submodules/sequencer_reg_file.sv"                                                
  vlog                                        "$QSYS_SIMDIR/submodules/sequencer_scc_acv_phase_decode.v"                                     
  vlog -sv                                    "$QSYS_SIMDIR/submodules/sequencer_scc_acv_wrapper.sv"                                         
  vlog -sv                                    "$QSYS_SIMDIR/submodules/sequencer_scc_mgr.sv"                                                 
  vlog                                        "$QSYS_SIMDIR/submodules/sequencer_scc_reg_file.v"                                             
  vlog                                        "$QSYS_SIMDIR/submodules/sequencer_scc_siii_phase_decode.v"                                    
  vlog -sv                                    "$QSYS_SIMDIR/submodules/sequencer_scc_siii_wrapper.sv"                                        
  vlog                                        "$QSYS_SIMDIR/submodules/sequencer_scc_sv_phase_decode.v"                                      
  vlog -sv                                    "$QSYS_SIMDIR/submodules/sequencer_scc_sv_wrapper.sv"                                          
  vlog                                        "$QSYS_SIMDIR/submodules/afi_mux_ddrx.v"                                                       
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_clock_pair_generator.v"          
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_read_valid_selector.v"           
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_addr_cmd_datapath.v"             
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_reset.v"                         
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_acv_ldc.v"                       
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_memphy.sv"                       
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_reset_sync.v"                    
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_new_io_pads.v"                   
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_fr_cycle_shifter.v"              
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_fr_cycle_extender.v"             
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_read_datapath.sv"                
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_write_datapath.v"                
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_simple_ddio_out.sv"              
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_phy_csr.sv"                      
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_iss_probe.v"                     
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_addr_cmd_pads.v"                 
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_flop_mem.v"                      
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0.sv"                              
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_p0_altdqdqs.v"                      
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altdq_dqs2_ddio_3reg_stratixiii.sv"                                   
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altdq_dqs2_abstract.sv"                                               
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altdq_dqs2_cal_delays.sv"                                             
  vlog -sv                                    "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0_pll0.sv"                            
  vlog                                        "$QSYS_SIMDIR/submodules/altera_reset_controller.v"                                            
  vlog                                        "$QSYS_SIMDIR/submodules/altera_reset_synchronizer.v"                                          
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_merlin_slave_translator.sv"                                    
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_merlin_master_translator.sv"                                   
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_d0.v"                                   
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0_if0.v"                                  
  vlog -sv                                    "$QSYS_SIMDIR/submodules/alt_mem_if_ddr2_mem_model_top_mem_if_dm_pins_en_mem_if_dqsn_en.sv"    
  vlog -sv                                    "$QSYS_SIMDIR/submodules/alt_mem_if_common_ddr_mem_model_mem_if_dm_pins_en_mem_if_dqsn_en.sv"  
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_mem_if_checker_no_ifdef_params.sv"                             
  vlog                                        "$QSYS_SIMDIR/submodules/ddr2_ctrl_test_example_sim_e0.v"                                      
  vlog -sv                                    "$QSYS_SIMDIR/submodules/verbosity_pkg.sv"                                                     
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_avalon_reset_source.sv"                                        
  vlog -sv                                    "$QSYS_SIMDIR/submodules/verbosity_pkg.sv"                                                     
  vlog -sv                                    "$QSYS_SIMDIR/submodules/altera_avalon_clock_source.sv"                                        
  vlog                                        "$QSYS_SIMDIR/ddr2_ctrl_test_example_sim.v"                                                    
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/NN_code/mem_ctrl_wrapper.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/cache_subsystem.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/L2_cache.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/nonblocking_fsm.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/fill_list_shift_register.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/L1_cache.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/free_list_FIFO.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/MSHR_2.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/L1_tag.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/tag_array.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/blocking_fsm.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/MSHR_1.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/mshr_dummy.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/blocking_fsm_L1.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/L2_ram.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/GenericOneHotMux.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/array.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/data_ram.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/GenericMux.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/blocking.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/freq_div.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/../NN_code/de3_display.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/../NN_code/bcd_7seg_dec.v"
  vlog                                        "C:/Users/hparch/Dropbox/Personal/Thesis/Project/Cache_Minhaj_final/../NN_code/freq_div_nn.v"
  vlog                                        "$QSYS_SIMDIR/ddr2_ctrl_test_example_sim.v"                                                    
}

# ----------------------------------------
# Elaborate top level design
alias elab {
  echo "\[exec\] elab"
  vsim -t ps -L work -L work_lib -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixiii_ver $TOP_LEVEL_NAME
}

# ----------------------------------------
# Elaborate the top level design with novopt option
alias elab_debug {
  echo "\[exec\] elab_debug"
  vsim -novopt -t ps -L work -L work_lib -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixiii_ver $TOP_LEVEL_NAME
}

# ----------------------------------------
# Compile all the design files and elaborate the top level design
alias ld "
  dev_com
  com
  elab
"

# ----------------------------------------
# Compile all the design files and elaborate the top level design with -novopt
alias ld_debug "
  dev_com
  com
  elab_debug
"

# ----------------------------------------
# Print out user commmand line aliases
alias h {
  echo "List Of Command Line Aliases"
  echo
  echo "file_copy                     -- Copy ROM/RAM files to simulation directory"
  echo
  echo "dev_com                       -- Compile device library files"
  echo
  echo "com                           -- Compile the design files in correct order"
  echo
  echo "elab                          -- Elaborate top level design"
  echo
  echo "elab_debug                    -- Elaborate the top level design with novopt option"
  echo
  echo "ld                            -- Compile all the design files and elaborate the top level design"
  echo
  echo "ld_debug                      -- Compile all the design files and elaborate the top level design with -novopt"
  echo
  echo 
  echo
  echo "List Of Variables"
  echo
  echo "TOP_LEVEL_NAME                -- Top level module name."
  echo
  echo "SYSTEM_INSTANCE_NAME          -- Instantiated system module name inside top level module."
  echo
  echo "QSYS_SIMDIR                   -- Qsys base simulation directory."
  echo
  echo "QUARTUS_INSTALL_DIR           -- Quartus installation directory."
}
file_copy
h
