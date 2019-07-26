// this version of the testbench is meant for the non-optimized .v, i.e. prewish.v and not prewish_chip.v

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

module prewish_sim_tb;
    reg clk = 0;
    always #1 clk = (clk === 1'b0);

    wire reset;
    wire sysclk;
    wire strobe;
    wire[7:0] data;
    wire led;         //active high LED
    reg mnt_stb=0;       //STB_I,        //then here is the student that takes direction from testbench
    reg[7:0] mnt_data=8'b00000000;  //DAT_I



	//from this:
    //module prewish_syscon(
    //    input i_clk, 
    //    output RST_O
    //    output CLK_O
    //           );

    prewish_syscon syscon(
        .i_clk(clk),
        .RST_O(reset),
        .CLK_O(sysclk)
    );
    
    //module prewish_mentor(
    //    input CLK_I,
    //    input RST_I,
    //    output STB_O,
    //    output[7:0] DAT_O
    //);

    prewish_mentor mentor(
        .CLK_I(sysclk),
        .RST_I(reset),
        .STB_O(strobe),
        .DAT_O(data),
        .STB_I(mnt_stb),        //then here is the student that takes direction from testbench
        .DAT_I(mnt_data)
    );

    //module prewish_blinky (
    //    input CLK_I,
    //    input RST_I,
    //    input STB_I,
    //    input[7:0] DAT_I,
    //    output o_led
    //);
    
    prewish_blinky #(.SYSCLK_DIV_BITS(3)) blinky (
        .CLK_I(sysclk),
        .RST_I(reset),
        .STB_I(strobe),
        .DAT_I(data),
        .o_led(led)
    );    

    //bit for creating gtkwave output
    initial begin
        //uncomment the next two for gtkwave?
        $dumpfile("prewish_sim_tb.vcd");
        $dumpvars(0, prewish_sim_tb);
    end

    initial begin
        //see if I can just wait some cycles
        mnt_data = 8'b1010100;
        #20 mnt_stb = 1;
        #21 mnt_stb = 0;
        #700 mnt_data = 8'b11001010;
        mnt_stb = 1;
        #711 mnt_stb = 0;       //test long strobe
        #1111 $finish;        
    end

endmodule
