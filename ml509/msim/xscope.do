onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/ml509_e/scope_e/DDR_tCP
add wave -noupdate -divider {New Divider}
add wave -noupdate /testbench/rst
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/ml509_e/scope_e/ddr_e/sys_clk
add wave -noupdate /testbench/ml509_e/dcm_lckd
add wave -noupdate /testbench/ml509_e/ddrs_rst
add wave -noupdate -divider xdr_init
add wave -noupdate /testbench/ml509_e/scope_e/ddrs_rst
add wave -noupdate -expand /testbench/ml509_e/scope_e/ddr_e/xdr_init_e/timers
add wave -noupdate /testbench/ml509_e/scope_e/ddr_e/xdr_init_e/xdr_init_clk
add wave -noupdate /testbench/ml509_e/scope_e/ddr_e/xdr_init_e/xdr_init_rst
add wave -noupdate /testbench/ml509_e/scope_e/ddr_e/xdr_init_e/xdr_init_req
add wave -noupdate /testbench/ml509_e/scope_e/ddr_e/xdr_init_e/xdr_init_pc
add wave -noupdate -divider {New Divider}
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/bl_cod
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/bl_tab
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/cl_tab
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/cwl_tab
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/CL_COD
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/CWL_COD
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/DQSOL_TAB
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/DQSX_LAT
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/DQSZL_TAB
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/DQSZX_TAB
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/DQZL_TAB
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/DQZX_TAB
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/RWNL_TAB
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/RWNX_LAT
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/STRL_TAB
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/STRX_LAT
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/WID_LAT
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/WWNL_TAB
add wave -noupdate -group constant /testbench/ml509_e/scope_e/ddr_e/xdr_sch_e/WWNX_LAT
add wave -noupdate /testbench/ml509_e/scope_e/ddr_e/sys_rst
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1542819 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 110
configure wave -valuecolwidth 204
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {3281250 ps}