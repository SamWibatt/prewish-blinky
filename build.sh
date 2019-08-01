#!/bin/bash
set -ex
# and so this is easy to copy to other projects and rename stuff
proj="prewish"

yosys "$proj".ys
# sean outcomments ../ from next line beginning bc I copied this from nextpnr examples
nextpnr-ice40 --json "$proj".json --pcf "$proj".pcf --asc "$proj".asc
icepack "$proj".asc "$proj".bin

# HEREAFTER SIMULATION STUFF I DON'T KNOW HOW TO DO - does it need to be done for pnr/iceprog?
#icebox_vlog "$proj".asc > "$proj"_chip.v
#iverilog -o "$proj"_tb "$proj"_chip.v "$proj"_tb.v
#vvp -N ./"$proj"_tb

# use
# iceprog prewish.bin
# to send the binary to the chip. iceprog -v shows LOTS of info 