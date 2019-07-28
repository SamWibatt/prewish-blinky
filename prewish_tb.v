//this version is meant to use the prewish_controller instead of prewish_syscon
//for doing sim of thing that will be put on the actual chip
//the controller creates all the other modules

/*
    SB_GB clk_gb (
        .USER_SIGNAL_TO_GLOBAL_BUFFER(clki),
        .GLOBAL_BUFFER_OUTPUT(clk)
    );


*/

//let's see if I can do 12 MHz
//8.3333333333333333333333333333333e-8 seconds per tick
// = 83.3 nanos, not real accurate
// = 83,333 picos, close enough.
//`timescale 83333ps/1ns
// weird, seems you can only do 1 or 2 as the first digit.
// can I do 100 nanos? That'd be in the ballpark but slow.
// FIGURE OUT HOW TO DO THAT PLL THING OR WHATEVER so I can do this - if it ends up mattering.
`timescale 100ns/10ns

//here's a cheap fake of the SB_GB module that the other tool chain uses 
//this lets it compile!
module SB_GB(input USER_SIGNAL_TO_GLOBAL_BUFFER, output GLOBAL_BUFFER_OUTPUT);
    assign GLOBAL_BUFFER_OUTPUT = USER_SIGNAL_TO_GLOBAL_BUFFER;
endmodule


// Main module -----------------------------------------------------------------------------------------

module prewish_tb;
    reg clk = 0;
    always #1 clk = (clk === 1'b0);

    wire reset;
    wire sysclk;
    wire strobe;
    wire[7:0] data;
    wire led;         //active high LED
    reg mnt_stb=0;       //STB_I,        //then here is the student that takes direction from testbench
    reg[7:0] mnt_data=8'b00000000;  //DAT_I

	//thing that makes this really use a clock routing thing
    SB_GB clk_gb (
		.USER_SIGNAL_TO_GLOBAL_BUFFER(i_clk),
		.GLOBAL_BUFFER_OUTPUT(CLK_O)             //can I use the output like this?
    );



    //module prewish_controller(
    //    input i_clk, 
    //    output RST_O
    //    output CLK_O
    //           );

    // was this for small simulation clocks prewish_controller #(.NEWMASK_CLK_BITS(9)) controller(
    // now let's try with real clock values, or as close as I can get - REAL ones take too long, but let's move it out more,
    // like have... 16 bits? default is 26, which is 1000 times longer.
    // one problem with this organization is that I can't get at the blinky's parameter - can I? Can I add a param to controller that
    // passes it along? Let us try. We want a blinky mask clock to be about 3 full cycles of 8... let's say 32x as fast as newmask clk so 5 fewer bits?
    // let's try 6 - ok, that proportion looks not bad!
    parameter CTRL_MASK_CLK_BITS 16
    prewish_controller #(.NEWMASK_CLK_BITS(CTRL_MASK_CLK_BITS),.BLINKY_MASK_CLK_BITS(10)) controller(

        .i_clk(clk),
        .RST_O(reset),
        .CLK_O(sysclk)
    );

    //bit for creating gtkwave output
    initial begin
        //uncomment the next two for gtkwave?
        $dumpfile("prewish_tb.vcd");
        $dumpvars(0, prewish_tb);
    end

    initial begin
        /* test from original simulated one - here we will let
        //see if I can just wait some cycles
        mnt_data = 8'b10101000;
        #21 mnt_stb = 1;
        #1 mnt_stb = 0;
        #637 mnt_data = 8'b11001010;
        #99 mnt_stb = 1;
        #811 mnt_stb = 0;       //test long strobe
        #711 $finish;       
        */
        //for short sim #7111 $finish;
        #1000000 $finish;           //longer sim, mask clock is now 16 bits
        //#1000000000 $finish;      //"real" time, and probably short for that
    end

endmodule
