# prewish-blinky

### note: I'm a beginner with programmable logic. If you are, too, be aware I'm not yet setting good examples. If you're an expert, I welcome your critiques!

* platform: [Lattice iCEstick ice40hx1k](http://www.latticesemi.com/en/Products/DevelopmentBoardsAndKits/iCEstick)
* toolchain: Icestorm - [github](https://github.com/cliffordwolf/icestorm), [home page](http://www.clifford.at/icestorm/)
    * iverilog
    * yosys
    * nextpnr
    * gtkwave
* dev system: running on a Virtualbox VM running Ubuntu 18.04, host system Windows 10 laptop
    * which later turned into an Ubuntu laptop when Windows 10 updates trashed Virtualbox :P
* circuit wiring: 
    * IceStick built-in LEDs on pins 95 (green), 96-99 (red), active high
    * Built-in 12MHz oscillator on pin 21, associated using an SB_GB module to a global buffer
    * Active low momentary contact button on pin 44, pulled up internally
    * DIP switch, active low, pins 112 (LSB) to 119 (MSB), all pulled up internally
    * refer to [pinout image by pighixxx](images/icestick_pinout.png)  

## objective

* Blink IceStick onboard green LED
* Create a peripheral to blink the LED according to an 8-bit mask
    * on for "1" bit, off for "0"
    * each bit ~1/10 second
    * e.g. 8'b10100000 does two quick blinks and a pause, repeatedly
    * it uses a simple interface (see under purpose.)
* and whatever other modules are necessary to drive the peripheral
* allow user to set mask on an 8 position DIP switch and "load" it with a debounced button

## purpose
* I'm new to HDLs but done a little bit of digital design
* Learning Verilog now that there are open source tools and cheap dev hardware (as of writing on 7/30/19!)
* Ramping up to learning [Wishbone b4 classic pipelined (pdf)](https://cdn.opencores.org/downloads/wbspec_b4.pdf) (say).
    * Hence **"prewish" - Pre-Wishbone interface project!**
    * So I can get used to designing and using interface standards
        * So I can use and contribute open source Verilog modules
    * I don't like the terms "Master" and "Slave" so I'm calling things "Mentor" and "Student", or M and S
    * Simplified interface:
        * all active high like Wishbone
        * reset line global to the interface
        * system clock line global
        * 8 bit data input to S modules
        * 8 bit data output from M modules (they can be both!)
        * strobe line
* produce implementations of: 
    * student (S) - [prewish_blinky.v](https://github.com/SamWibatt/prewish-blinky/blob/master/prewish_blinky.v)
        * blinks an LED according to an 8 bit mask
    * mentor (M) - [prewish_mentor.v](https://github.com/SamWibatt/prewish-blinky/blob/master/prewish_mentor.v)
        * accepts input from upstream module (here, the controller) and is therefore its student
        * delivers it to downstream S
    * controller (syscon equivalent) - [prewish_controller.v](https://github.com/SamWibatt/prewish-blinky/blob/master/prewish_controller.v)
        * generates reset pulse
        * generates interface system clock
        * accept input from user via 8 bit DIP switch and a "load" button
    * input handler - [prewish_debounce.v](https://github.com/SamWibatt/prewish-blinky/blob/master/prewish_debounce.v)
        * works but is poorly defined with 1 bit input and 8 bits output.
    
