#!/bin/bash
# this one simulates with prewish_tb instead of prewish_sim_tb
echo "SIMULATION =============================================================================================== " > sim_debounce_tb_out.txt
echo "SIMULATION =============================================================================================== " > sim_debounce_tb_err.txt

# simulation, old: DO IT THIS WAY TO SEE THE SENSIBLE SIMULATION TRACE
iverilog -o prewish_debounce_tb.vvp prewish_debounce.v prewish_debounce_tb.v 1>> sim_debounce_tb_out.txt 2>> sim_debounce_tb_err.txt
vvp prewish_debounce_tb.vvp  1>> sim_debounce_tb_out.txt 2>> sim_debounce_tb_err.txt
#gtkwave -o does optimization of vcd to FST format, good for the big sims
# or just do it here
vcd2fst prewish_debounce_tb.vcd prewish_debounce_tb.fst
rm prewish_debounce_tb.vcd
#gtkwave -o prewish_debounce_tb.fst &

