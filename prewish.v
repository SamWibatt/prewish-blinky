/*
	prewish first version: just a power-on reset.
	input clock, output reset.
    
    This isn't really what I want to have be the main module, though. It's really a resetter.
    Can I have multiple modules in a file? Yes I can. Let's call it a syscon! Syscons emit reset and clock!
*/

module prewish_syscon(
    input i_clk, 
    output RST_O,               //wy not use the wishbone name
    output CLK_O                //"
           );

	//thing that makes this really use a clock
    SB_GB clk_gb (
		.USER_SIGNAL_TO_GLOBAL_BUFFER(i_clk),
        .GLOBAL_BUFFER_OUTPUT(CLK_O)             //can I use the output like this?
    );

    //from https://electronics.stackexchange.com/questions/405363/is-it-possible-to-generate-internal-reset-pulse-in-verilog-with-machxo3lf-fpga
    //tis worky, drops reset to 0 at 15 seconds (with the 1 second sim tick.)
    reg [3:0] rst_cnt = 0;
    wire RST_O = ~rst_cnt[3];     // My reset is active high, original was active low; I think that's why it was called rst_n
    always @(posedge CLK_O)      // see if I can use the output that way
        if( RST_O )               // active high reset
            rst_cnt <= rst_cnt + 1;
    
endmodule

