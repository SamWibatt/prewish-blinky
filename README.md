# prewish-blinky

* platform: [Lattice iCEstick ice40hx1k](http://www.latticesemi.com/en/Products/DevelopmentBoardsAndKits/iCEstick)
* toolchain: Icestorm - [github](https://github.com/cliffordwolf/icestorm), [home page](http://www.clifford.at/icestorm/)
    * iverilog
    * yosys
    * nextpnr
    * gtkwave
* dev system: running on a Virtualbox VM running Ubuntu 18.04, host system Windows 10 laptop

## objective

* Blink IceStick onboard green LED
* Create a peripheral to blink the LED according to an 8-bit mask
    * on for "1" bit, off for "0"
    * each bit ~1/10 second
    * e.g. 8'b10100000 does two quick blinks and a pause, repeatedly
    * it uses a simple interconnect (see under purpose.)
* and whatever other modules are necessary to drive the peripheral

## purpose
* I'm new to HDLs but done a little bit of digital design
* Learning Verilog now that there are open source tools and cheap dev hardware (as of writing on 7/30/19!)
* Ramping up to learning [Wishbone b4 classic pipelined (pdf)](https://cdn.opencores.org/downloads/wbspec_b4.pdf) (say).
    * So I can get used to writing interconnects
    * I don't like the terms "Master" and "Slave" so I'm calling things "Mentor" and "Student", or M and S
    * Simplified interconnect:
        * all active high like Wishbone
        * reset line global to the interconnect
        * 8 bit data input to S
        * 8 bit data output from M
        * strobe line
* produce implementations of: 
    * student (S)
        * blinks an LED according to an 8 bit mask
    * mentor (M)
        * accepts input from upstream module (here, the controller)
        * delivers it to downstream S
    * controller (syscon equivalent)
        * generates reset pulse
        * generates interconnect system clock
        * accept input from user via 8 bit DIP switch and a "load" button
            * _initial version iterates through a list of predefined masks_
