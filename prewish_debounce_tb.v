// making a little tb for just the debounce, bc I should do that.
// and make a gneralized sim.sh.
// kind of ok `timescale 100ns/10ns
`timescale 100ns/100ns

// Main module -----------------------------------------------------------------------------------------

module prewish_debounce_tb;
	

	// TESTBENCH BOILERPLATE =========================================================================================================================================

	//here is the core of the prewish interconnect
	//here is generic clock. use for CLK_I in modules
    reg clk = 0;
    always #1 clk = (clk === 1'b0);

	//and a little lump to act as the tiniest syscon ever: -----------------------------------------------
	//from https://electronics.stackexchange.com/questions/405363/is-it-possible-to-generate-internal-reset-pulse-in-verilog-with-machxo3lf-fpga
    //tis worky, drops reset to 0 at 15 clocks
    reg [3:0] rst_cnt = 0;
	wire reset = ~rst_cnt[3];     // My reset is active high, original was active low; I think that's why it was called rst_n
	always @(posedge clk)      // see if I can use the output that way
		if( reset )               // active high reset
            rst_cnt <= rst_cnt + 1;
	//end tiny syscon ------------------------------------------------------------------------------------

	//and a clock divider, bc I think I'm going to design my modules to use buffered clocks & therefore clock param
	//which lets me consolidate the clock dividing and save ffs if I want to potato-stamp copies of modules all over
	//by default, assuming iceStick 12 MHz clock, can fancy up the math and do pll stuff later.
	//so, 20 bits would be a divide-by-million so 12Hz, ish. fiddle around from there.
	//for simulation, let's make this small, like say 7, we do want to be able to have a pseudo-noisy input whose frequency is a lot higher than the
	//debounce interval. 128 should make us not need too much simulation time, but give us good resolution
	//delete or duplicate or decorate as needed. Maybe modularize.
	parameter SLOW_CLK_BITS=7;
	reg [SLOW_CLK_BITS-1:0] slow_clk_ct = 0;
	
	always @(posedge clk) begin
		if (~reset) begin
			slow_clk_ct <= slow_clk_ct + 1;
		end else begin
			slow_clk_ct <= 0;
		end
	end
	
	wire slow_clk = slow_clk_ct[SLOW_CLK_BITS-1];			//hopework - does! but much too predictable, 

	//more interconnect stuff
	wire strobe;
    wire[7:0] data;

	// END TESTBENCH BOILERPLATE =====================================================================================================================================
	//here's what we're testing
	// module prewish_debounce(
	// 	input CLK_I,
	// 	input RST_I,
	// 	output STB_O,        //mentor/outgoing interface, writes to caller with current status byte
	// 	output[7:0] DAT_O,
	// 	input STB_I,        //then here is the student that takes direction from testbench
	// 	input[7:0] DAT_I,
	// 	input iN_button,	// active low input from button, caller presumably just passes this straight along from a pad WILL BE REFACTORED INTO AN ARRAY
	// 	input i_dbclock,	// debounce (slow) clock 
	// 	//output ACK_O,		// do I need this? let's say not, for the moment; I think it's for stuff that might not work right away and will ping back later with results?
	// 	output o_alive      // debug outblinky
	// );





    //bit for creating gtkwave output
    initial begin
        //uncomment the next two for gtkwave?
		$dumpfile("prewish_debounce_tb.vcd");
		$dumpvars(0, prewish_debounce_tb);
    end

    initial begin
        #128000 $finish;
    end

endmodule

