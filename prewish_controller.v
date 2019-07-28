/*
	prewish controller first version
	
*/



// MAIN ********************************************************************************************************************************************
module prewish_controller(
    input i_clk, 
    output RST_O,               //wy not use the wishbone name - and maybe even bring these out to pins could be fun for testing with that little logic analyzer
    output CLK_O                //"
);

	// **************** inputs for dip swicth and load button. Output for the actual blinky LED!


    //from https://electronics.stackexchange.com/questions/405363/is-it-possible-to-generate-internal-RST_O-pulse-in-verilog-with-machxo3lf-fpga
    //tis worky, drops RST_O to 0 at 15 seconds (with the 1 second sim tick.)
    reg [3:0] rst_cnt = 0;
    wire RST_O = ~rst_cnt[3];     // My RST_O is active high, original was active low; I think that's why it was called rst_n
	always @(posedge CLK_O)      // see if I can use the output that way
		if( RST_O )               // active high RST_O
            rst_cnt <= rst_cnt + 1;


	// END SYSCON ========================================================================================================================	

    wire strobe;
    wire[7:0] data;
    wire led;         //active high LED
    reg mnt_stb=0;       //STB_I,        //then here is the student that takes direction from testbench
    reg[7:0] mask=8'b00000000;  //DAT_I


	// FOR THE HARDWARE VERSION THE CONTROLLER HERE GENERATES SYSCON SIGNALS ==========================================================
	// should this be here?
	//thing that makes this really use a clock routing thing
	/* let's put in test bench...?	
    SB_GB clk_gb (
		.USER_SIGNAL_TO_GLOBAL_BUFFER(i_clk),
		.GLOBAL_BUFFER_OUTPUT(CLK_O)             //can I use the output like this?
    );
	*/
	//instead do this until we have to put that back
	assign CLK_O = i_clk;
	

	
	/* we don't need a syscon, we are one! Think about this.
	//from this:
    //module prewish_syscon(
    //    input i_clk, 
    //    output RST_O
    //    output CLK_O
    //           );

    prewish_syscon syscon(
        .i_clk(clk),
        .RST_O(RST_O),
        .CLK_O(CLK_O)
    );
	*/

    //module prewish_mentor(
    //    input CLK_I,
    //    input RST_I,
    //    output STB_O,
    //    output[7:0] DAT_O
    //);

    prewish_mentor mentor(
        .CLK_I(CLK_O),
        .RST_I(RST_O),
        .STB_O(strobe),
        .DAT_O(data),
        .STB_I(mnt_stb),        //then here is the student that takes direction from testbench
        .DAT_I(mask)
    );

    //module prewish_blinky (
    //    input CLK_I,
    //    input RST_I,
    //    input STB_I,
    //    input[7:0] DAT_I,
    //    output o_led
    //);
    
    prewish_blinky #(.SYSCLK_DIV_BITS(3)) blinky (
        .CLK_I(CLK_O),
        .RST_I(RST_O),
        .STB_I(strobe),
        .DAT_I(data),
        .o_led(led)
    );    
	
	//so ok actual works!
	//say we have a state machine
	//states are:
	//- initial/reset
	//- await load button pressed (may take multiple states or a separate module to debounce)
	//- await load button released (if handling it here)
	//- on exit from whatever of those states is the last does data_reg <= dip_input
	//- propagate data to the blinky mentor and it will ripple along to the blinky student
	// WRITE THAT
	// but first look up how to debounce a button and stuff.
	// maybe here? https://www.fpga4student.com/2017/04/simple-debouncing-verilog-code-for.html
	// and at some point could make a wihsbone (!!!) finsih vansihing point
	// or rather student read buttons and make their state available via read from some mentor
	// assume everything's realtime so the button error isn't going to be more than a tiny fraction of a second
	// FPGA IS ALL ABOUT NOT HAVING YOUR CAMERA TAKE 15 SECONDS TO POWER UP you know
	// so in here I will make a little local modulelet for the debounce and can later refactor it if wanna.
	

	// AFTER THIS IT'S SIMULATION STUFF

	/*
    //bit for creating gtkwave output
    initial begin
        //uncomment the next two for gtkwave?
        $dumpfile("prewish_sim_tb.vcd");
        $dumpvars(0, prewish_sim_tb);
    end

    initial begin
        //see if I can just wait some cycles
        mask = 8'b10101000;
        #21 mnt_stb = 1;
        #1 mnt_stb = 0;
        #637 mask = 8'b11001010;
        #99 mnt_stb = 1;
        #811 mnt_stb = 0;       //test long strobe
        #711 $finish;        
    end
	*/
	
	//so what this needs to do is to accept user input and send the dip switch setting along to the prewish.
	//see prewish_debounce.v about that, it's in progress.
	//For now, we have the reset logic above, and if I were clever I could rope this into prewish_sim_tb and use it a combination syscon/mentor thing there too.
	//so:
	//what if I did a great big dividey clock that drives the initial version, pick a new mask every 5 seconds or so.
	//12MHz / 5Hz = 2,400,000, so could do a 2M divider and be in the hideyallpark.
	//that's 21 bits, yes? that sounds like too few. aha, bc we don't want 5Hz, we want 1/5Hz, so do like 26 bits.
	parameter NEWMASK_CLK_BITS=26;
	reg [NEWMASK_CLK_BITS-1:0] newmask_clk_ct = 0;
	
	always @(posedge CLK_O) begin
		if (~RST_O) begin
			newmask_clk_ct <= newmask_clk_ct + 3;  //was 1, try to stir up
		end else begin
			newmask_clk_ct <= 0;
		end
	end
	
	wire newmask_clk = newmask_clk_ct[NEWMASK_CLK_BITS-1];			//hopework - does! but much too predictable, hits neatly on edges of LED cycle
	//how to fudge it out a bit? Or just make it not a NRN.
	
	
	//some data
	/* doesn't work, just use another counter and case
	byte [0:7] masks = {
		8'b10000000,
		8'b10100000,
		8'b10101000,
		8'b11111111,
		8'b11010100,
		8'b11010101,
		8'b11001100,
		8'b11100000
	};
	*/
	
	//here we're missing the goods, not too much to do. Just need a little state machine!
	//- reset/initial, await... hm.
	// we don't want a state machine running at newmask_clk pace - we want to load a new mask at that pace and then touch off a
	// sysclk-rate state machine.
	//ok I think it works!
	
	reg [1:0] newmask_state = 2'b00;
	reg [2:0] newmask_index = 3'b000;		//kludgy thing to pick a mask via hardcodiness bc just a test and I don't want to dig into language
	
	always @(posedge newmask_clk) begin
		//GENERATE A NEW MASK and touch off the little statey below
		//but we don't want to wait until it starts... or do we?
		//mask <= mask -1;		//FIND A CLEVERER WAY TO MAKE UP NEW MASKS
		// see e.g. https://stackoverflow.com/questions/40657508/declaring-an-array-of-constant-with-verilog
		//nope
		//just do a little counter and case and hardcodey assignment
		case(newmask_index)
			3'b000: begin
				mask <= 8'b10000000;
			end
			3'b001: begin
				mask <= 8'b10100000;
			end
			3'b010: begin
				mask <= 8'b10101000;
			end
			3'b011: begin
				mask <= 8'b11111111;
			end
			3'b100: begin
				mask <= 8'b11010100;
			end
			3'b101: begin
				mask <= 8'b11010101;
			end
			3'b110: begin
				mask <= 8'b11001100;
			end
			3'b111: begin
				mask <= 8'b11100000;
			end
		endcase
		
		newmask_index <= newmask_index + 1;
		newmask_state <= 2'b10;
	end
	
	always @(posedge CLK_O) begin
		if (RST_O) begin
			newmask_state <= 2'b00;
			newmask_index = 3'b000;
			mask <= 0;
		end else begin
			case(newmask_state)
				2'b00: begin
					// do nothing
				end
				
				2'b10: begin
					// raise strobe
					mnt_stb <= 1;
					newmask_state <= 2'b11;
				end

				2'b11: begin
					// lower strobe
					mnt_stb <= 0;
					newmask_state <= 2'b00;
				end

				2'b10: begin
					//currently unused
					mnt_stb <= 0;
					newmask_state <= 2'b00;
				end
			endcase
		end
	end
    
endmodule
