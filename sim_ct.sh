#!/bin/bash
# this one simulates with prewish_tb instead of prewish_sim_tb
echo "SIMULATION =============================================================================================== " > sim_tb_out.txt
echo "SIMULATION =============================================================================================== " > sim_tb_err.txt

# simulation, old: DO IT THIS WAY TO SEE THE SENSIBLE SIMULATION TRACE
iverilog -o prewish_tb.vvp prewish_controller.v prewish_mentor.v prewish_blinky.v prewish_tb.v 1>> sim_tb_out.txt 2>> sim_tb_err.txt
vvp prewish_tb.vvp  1>> sim_tb_out.txt 2>> sim_tb_err.txt
#gtkwave prewish_tb.vcd &

