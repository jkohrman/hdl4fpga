onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/rst
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/clk_p
add wave -noupdate /testbench/cke
add wave -noupdate /testbench/cs_n
add wave -noupdate /testbench/ras_n
add wave -noupdate /testbench/cas_n
add wave -noupdate /testbench/we_n
add wave -noupdate -radix hexadecimal -childformat {{/testbench/addr(12) -radix hexadecimal} {/testbench/addr(11) -radix hexadecimal} {/testbench/addr(10) -radix hexadecimal} {/testbench/addr(9) -radix hexadecimal} {/testbench/addr(8) -radix hexadecimal} {/testbench/addr(7) -radix hexadecimal} {/testbench/addr(6) -radix hexadecimal} {/testbench/addr(5) -radix hexadecimal} {/testbench/addr(4) -radix hexadecimal} {/testbench/addr(3) -radix hexadecimal} {/testbench/addr(2) -radix hexadecimal} {/testbench/addr(1) -radix hexadecimal} {/testbench/addr(0) -radix hexadecimal}} -subitemconfig {/testbench/addr(12) {-height 16 -radix hexadecimal} /testbench/addr(11) {-height 16 -radix hexadecimal} /testbench/addr(10) {-height 16 -radix hexadecimal} /testbench/addr(9) {-height 16 -radix hexadecimal} /testbench/addr(8) {-height 16 -radix hexadecimal} /testbench/addr(7) {-height 16 -radix hexadecimal} /testbench/addr(6) {-height 16 -radix hexadecimal} /testbench/addr(5) {-height 16 -radix hexadecimal} /testbench/addr(4) {-height 16 -radix hexadecimal} /testbench/addr(3) {-height 16 -radix hexadecimal} /testbench/addr(2) {-height 16 -radix hexadecimal} /testbench/addr(1) {-height 16 -radix hexadecimal} /testbench/addr(0) {-height 16 -radix hexadecimal}} /testbench/addr
add wave -noupdate /testbench/ba
add wave -noupdate -radix hexadecimal /testbench/dq
add wave -noupdate -expand /testbench/dqs
add wave -noupdate /testbench/nuhs3dsp_e/ddr_a_10_OBUF/I
add wave -noupdate /testbench/nuhs3dsp_e/ddr_a_10_OBUF/O
add wave -noupdate -radix hexadecimal /testbench/nuhs3dsp_e/ddr_a
add wave -noupdate -radix hexadecimal /testbench/nuhs3dsp_e/ddrphy_a
add wave -noupdate /testbench/nuhs3dsp_e/dcms_e_ddr_lckd
add wave -noupdate /testbench/nuhs3dsp_e/scope_e_ddr_e_wrfifo_i_xdr_fifo_g_0_outbyte_i_phases_g_1_ram_b_ram_g_6_ram_i_SLICEM_F/CLK
add wave -noupdate /testbench/nuhs3dsp_e/scope_e_ddr_e_wrfifo_i_xdr_fifo_g_0_outbyte_i_phases_g_1_ram_b_ram_g_6_ram_i_SLICEM_F/WE
add wave -noupdate /testbench/nuhs3dsp_e/scope_e_ddrs_di_rdy
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {4881698 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 593
configure wave -valuecolwidth 100
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
WaveRestoreZoom {4861491 ps} {4896196 ps}