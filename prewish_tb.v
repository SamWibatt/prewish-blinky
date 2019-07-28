//this version is meant to use the prewish_controller instead of prewish_syscon
//for doing sim of thing that will be put on the actual chip
//the controller creates all the other modules

/*
    SB_GB clk_gb (
        .USER_SIGNAL_TO_GLOBAL_BUFFER(clki),
        .GLOBAL_BUFFER_OUTPUT(clk)
    );


*/


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

    prewish_controller #(.NEWMASK_CLK_BITS(7)) controller(
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
        #7111 $finish;
    end

endmodule
