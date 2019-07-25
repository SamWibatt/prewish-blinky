#!/bin/bash
echo "SIMULATION =============================================================================================== " > sim_out.txt
echo "SIMULATION =============================================================================================== " > sim_err.txt

# simulation, old: DO IT THIS WAY TO SEE THE SENSIBLE SIMULATION TRACE
iverilog -o prewish.vvp prewish.v prewish_mentor.v prewish_blinky.v prewish_sim_tb.v 1>> sim_out.txt 2>> sim_err.txt
vvp prewish.vvp  1>> sim_out.txt 2>> sim_err.txt
#gtkwave prewish_tb.vcd &

