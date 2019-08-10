#!/bin/bash
# this one simulates with prewish_tb instead of prewish_sim_tb
echo "SIMULATION =============================================================================================== " > sim_tb_out.txt
echo "SIMULATION =============================================================================================== " > sim_tb_err.txt

# simulation, old: DO IT THIS WAY TO SEE THE SENSIBLE SIMULATION TRACE
iverilog -D SIM_STEP -o prewish_tb.vvp prewish_controller.v prewish_mentor.v prewish_blinky.v prewish_debounce.v prewish_tb.v 1>> sim_tb_out.txt 2>> sim_tb_err.txt
vvp prewish_tb.vvp  1>> sim_tb_out.txt 2>> sim_tb_err.txt
#gtkwave -o does optimization of vcd to FST format, good for the big sims
# or just do it here
vcd2fst prewish_tb.vcd prewish_tb.fst
rm -f prewish_tb.vcd
#gtkwave -o prewish_tb.vcd &
