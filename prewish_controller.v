/*
	prewish controller first version

*/
`default_nettype	none



// MAIN ********************************************************************************************************************************************
module prewish_controller(
    input i_clk,
//    output RST_O,               //wy not use the wishbone name - and maybe even bring these out to pins could be fun for testing with that little logic analyzer
//    output CLK_O                //"
    input the_button,       //pin 44 active LOW button? Pulled up and inverted in here. Pin 119
    input i_bit7, // 119 dip swicth swicths, active low. Will pull up but not debounce.
    input i_bit6, // 118
    input i_bit5, // 117
    input i_bit4, // 116
    input i_bit3, // 115
    input i_bit2, // 114
    input i_bit1, // 113
    input i_bit0, // 112

	output the_led,					//this is THE LED, the green one
	output o_led0,						//these others are just the other LEDs on the board and they go to 0. except perhaps for other status things.
	output o_led1,
	output o_led2,
	output o_led3
);

  /* INPUT BUTTON -
  per
  https://discourse.tinyfpga.com/t/internal-pullup-in-bx/800

  I may need something like this in here:

  wire button;

  SB_IO #(
    .PIN_TYPE(6'b 0000_01),
    .PULLUP(1'b 1)
  ) button_input(
    .PACKAGE_PIN(PIN_1),
    .D_IN_0(button)
  );

  ****************** MAKE SURE THIS IS HOW YOU DO IT WITH HX1K
  // per https://hackaday.io/project/7982-cat-board/log/28499-thats-going-to-be-so-easy
  module top(inout pin);
  		wire outen, dout, din;

  		SB_IO #(
  			.PIN_TYPE(6'b 1010_01),
  			.PULLUP(1'b 1)
  		) io_pin (
  			.PACKAGE_PIN(pin),
  			.OUTPUT_ENABLE(outen),
  			.D_OUT_0(dout),
  			.D_IN_0(din)
  		);
  	endmodule
    Where is that documented?
    TAKE A LOOK IN iCETechnologyLibrary.PDF IN FPGA DROPBOX FOLDER
    Yup, page 70 or so in that has what we need
    and it looks like the original is ok
  */
  /*
  CHECK OUT https://github.com/nesl/ice40_examples/tree/master/buttons_debounce
  / * Numpad pull-up settings for columns:
        PIN_TYPE: <output_type=0>_<input=1>
        PULLUP: <enable=1>
        PACKAGE_PIN: <user pad name>
        D_IN_0: <internal pin wire (data in)>
     * /
     wire keypad_c1_din;
     SB_IO #(
         .PIN_TYPE(6'b0000_01),
         .PULLUP(1'b1)
     ) keypad_c1_config (
         .PACKAGE_PIN(keypad_c1), sean notes module dec parameter
         .D_IN_0(keypad_c1_din)   sean notes variable in here
     );  */

    wire button_internal;
    SB_IO #(
        .PIN_TYPE(6'b 0000_01),     //IS THIS RIGHT? looks like it's PIN_NO_OUTPUT | PIN_INPUT (not latched or registered)
        .PULLUP(1'b 1)
    ) button_input(
        .PACKAGE_PIN(the_button),   //has to be a pin in bank 0,1,2
        .D_IN_0(button_internal)
    );

    //dip switch wires and i/o with pullups
    wire[7:0] dip_swicth;
    //can you do this with a for loop?
    SB_IO #(.PIN_TYPE(6'b 0000_01),.PULLUP(1'b 1)) bit7_input(.PACKAGE_PIN(i_bit7),.D_IN_0(dip_swicth[7]));
    SB_IO #(.PIN_TYPE(6'b 0000_01),.PULLUP(1'b 1)) bit6_input(.PACKAGE_PIN(i_bit6),.D_IN_0(dip_swicth[6]));
    SB_IO #(.PIN_TYPE(6'b 0000_01),.PULLUP(1'b 1)) bit5_input(.PACKAGE_PIN(i_bit5),.D_IN_0(dip_swicth[5]));
    SB_IO #(.PIN_TYPE(6'b 0000_01),.PULLUP(1'b 1)) bit4_input(.PACKAGE_PIN(i_bit4),.D_IN_0(dip_swicth[4]));
    SB_IO #(.PIN_TYPE(6'b 0000_01),.PULLUP(1'b 1)) bit3_input(.PACKAGE_PIN(i_bit3),.D_IN_0(dip_swicth[3]));
    SB_IO #(.PIN_TYPE(6'b 0000_01),.PULLUP(1'b 1)) bit2_input(.PACKAGE_PIN(i_bit2),.D_IN_0(dip_swicth[2]));
    SB_IO #(.PIN_TYPE(6'b 0000_01),.PULLUP(1'b 1)) bit1_input(.PACKAGE_PIN(i_bit1),.D_IN_0(dip_swicth[1]));
    SB_IO #(.PIN_TYPE(6'b 0000_01),.PULLUP(1'b 1)) bit0_input(.PACKAGE_PIN(i_bit0),.D_IN_0(dip_swicth[0]));


	// registers for the non-blinky LED. one of which will be used to do a super simple "I'm Alive" blinky.
	// others need to be driven low, I think.
	reg [3:0] otherLEDs = 0;
	parameter REDBLINKBITS = 23;			//11 = now I'm getting a thing where the red led is on seemingly continuous, 21 is fastish, 23 not bad but still kinda fast

	//super elementary blinky LED, divide clock down by about 4 million = 22 bits? let's mess with it
	reg[REDBLINKBITS-1:0] redblinkct = 0;
	always @(posedge i_clk) begin
		redblinkct <= redblinkct + 1;
	end

	//now let's try alive leds for the modules
	wire blinky_alive;
	wire mentor_alive;
    wire debounce_alive;

	assign o_led3 = debounce_alive; //otherLEDs[3];
	assign o_led2 = mentor_alive;	//otherLEDs[2];
	assign o_led1 = blinky_alive; //otherLEDs[1];
	assign o_led0 = redblinkct[REDBLINKBITS-1];		//controller_alive, basically



	// **************** inputs for dip swicth and load button. Output for the actual blinky LED!


    //from https://electronics.stackexchange.com/questions/405363/is-it-possible-to-generate-internal-RST_O-pulse-in-verilog-with-machxo3lf-fpga
    //tis worky, drops RST_O to 0 at 15 seconds (with the 1 second sim tick.)
    reg [3:0] rst_cnt = 0;
    wire RST_O = ~rst_cnt[3];     // My RST_O is active high, original was active low; I think that's why it was called rst_n
    wire CLK_O;     //avoid default_nettype error
	always @(posedge CLK_O)      // see if I can use the output that way
		if( RST_O )               // active high RST_O
            rst_cnt <= rst_cnt + 1;


	// END SYSCON ========================================================================================================================

    wire strobe;
    wire[7:0] data;
    //wire the_led;         //active high LED
    reg mnt_stb=0;       //STB_I,        //then here is the student that takes direction from testbench
	reg[7:0] mask=0;	//see if can do this. was 8'b00000000;  //DAT_I
	wire[7:0] maskwires = mask;


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
		.DAT_I(mask),		//was mask - maskwires doesn't help
		.o_alive(mentor_alive)
    );

    //module prewish_blinky (
    //    input CLK_I,
    //    input RST_I,
    //    input STB_I,
    //    input[7:0] DAT_I,
    //    output o_led
    //);

	/* ATM the_led is not reaching out to the actual LED
	build emits this:
	Info: constrained 'the_led' to bel 'X13/Y9/io1'
	Info: constrained 'o_led0' to bel 'X13/Y12/io1'
	Info: constrained 'o_led1' to bel 'X13/Y12/io0'
	Info: constrained 'o_led2' to bel 'X13/Y11/io1'
	Info: constrained 'o_led3' to bel 'X13/Y11/io0'
	Info: constrained 'i_clk' to bel 'X0/Y8/io1'

	doesn't seem to be as informative as hoped

	doing this DOES make the green LED blink along with the mask_clk led: assign o_led = ckdiv[SYSCLK_DIV_BITS-1]; so there's nothing wrong with the linkage back.

	Changing this in blinky:
    assign o_alive = ckdiv[SYSCLK_DIV_BITS-1];
	to assigning it to ledreg didn't work, so something is wrong with the ledreg logic somewhere.
	assigning it to mask[7] likewise.
	ASSIGNING MASK TO A CONSTANT ON STROBE INSTEAD OF TO DAT_I DOES WORK, THOUGH!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	so the problem is maybe with DAT_I getting communicated from the mentor
	*/

    //NEWMASK_CLK_BITS is a throwback to when masks were just chosen by a timer instead of USER INPUT!!!!
    //so need to get rid of it
    parameter NEWMASK_CLK_BITS=28;		//default for "build"
	parameter BLINKY_MASK_CLK_BITS = NEWMASK_CLK_BITS - 7;	//default for build, swh //3;			//default for short sim
	//short sim version prewish_blinky #(.SYSCLK_DIV_BITS(3)) blinky (
	prewish_blinky #(.SYSCLK_DIV_BITS(BLINKY_MASK_CLK_BITS)) blinky (		//can I do this to cascade parameterization from controller decl in prewish_tb? looks like!
        .CLK_I(CLK_O),
        .RST_I(RST_O),
        .STB_I(strobe),
		.DAT_I(data),			//should be data - making this mask didn't fix the trouble
		.o_alive(blinky_alive),
		.o_led(the_led)
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
	//see prewish_debounce.v about that

  /*
  module prewish_debounce(
      input CLK_I,
      input RST_I,
      output STB_O,        //mentor/outgoing interface, writes to caller with current status byte
      output[7:0] DAT_O,
      input STB_I,        //then here is the student that takes direction from testbench
      input[7:0] DAT_I,
      input i_button,	// active HIGH input from button, caller presumably just passes this straight along from a pad WILL BE REFACTORED INTO AN ARRAY
      output o_alive      // debug outblinky
  );
  */

  //so ok here we have a debouncer I'm getting put together
  //error atm:
  //Mapping prewish_controller.pre_deb using prewish_debounce.
  //ERROR: Mismatch in directionality for cell port prewish_controller.pre_deb.DAT_O: \debounce_mask <= \pre_deb.DAT_O
  //I think I had DAT_O and DAT_I switched, thinking of DAT_O as outgoing from here, not from it.
  //switching those, tho,
  //ERROR: Mismatch in directionality for cell port prewish_controller.pre_deb.DAT_O: \button_state <= \pre_deb.DAT_O
  //it was right to switch those, but I think the real prob might have been I had button_state here
  //being registers instead of wires, and it's an output. - now do the same switch with strobe
  //and that got it!
  reg debounce_in_strobe = 0;
  reg[7:0] debounce_mask = 0;   // atm debounce doesn't do anything with the input data, may later be a mask
  wire debounce_out_strobe;
  wire[7:0] button_state; // = 0;
  reg[7:0] button_streg = 0;    //for remembering button_state
  prewish_debounce pre_deb(
      .CLK_I(CLK_O),
      .RST_I(RST_O),
      .STB_O(debounce_out_strobe),    //ack? Dunno if I wrote this
      .DAT_O(button_state),
      .STB_I(debounce_in_strobe),
      .DAT_I(debounce_mask),
      .i_button(~button_internal),         //see if I can launder active-low to active-high like this
      .o_alive(debounce_alive)
    );

    // NEW DIP & BUTTON DRIVEN THING ==========================================================================
    // third version: just like the broken no-fetch, but another state machine keeps button state fresh.
    reg [1:0] fetchbuttons_state = 2'b00;

    //can you have multiple alwayses hanging off one clock? Let's find out!
    //if not, canjust move the reset block inside the other always's reset block and the
    //case into the else part alongside the other case, why not.
    //OR clock this on something a little bit slower.
    always @(posedge CLK_O) begin
        if (RST_O) begin
            fetchbuttons_state <= 2'b00;
            button_streg <= 8'b00000000;          //I think it's safe to assign here
            debounce_in_strobe <= 0;
        end else begin
            case(fetchbuttons_state)
                2'b00: begin
                    fetchbuttons_state <= 2'b01;
                end

                2'b01: begin
                    debounce_mask <= 8'b00000001;           //not used atm
                    debounce_in_strobe <= 1;
                    fetchbuttons_state <= 2'b11;
                end

                2'b11: begin
                    debounce_in_strobe <= 0;               //lower strobe, idle here until get ACK
                    if(debounce_out_strobe) begin
                        button_streg <= button_state;       // load button state!
                        fetchbuttons_state <= 2'b10;
                    end
                end

                2'b10: begin
                    //wait state bc why not - future may be clocked on something a bit slower
                    fetchbuttons_state <= 2'b00;
                end

            endcase
        end
    end

    //second state machine for loading the mask on positive button edge.
    reg [1:0] loadmask_state = 2'b00;

    always @(posedge CLK_O) begin
		if (RST_O) begin
			loadmask_state <= 2'b00;
            mask <= 2'b00;          //I think it's safe to assign here
		end else begin
			case(loadmask_state)
				2'b00: begin
					// do nothing unless it's time to go to 10
                    // which is when we have a positive edge on the button.
                    //... what if this state waits for button release, then 10 waits for press?
                    //I think that's a better way to handle it wrt reset too
                    if (button_state[0] == 0) begin
                        loadmask_state <= 2'b10;
                    end
                end

                2'b10: begin
                    // previous state waited for button release, this one waits for press.
                    if (button_state[0] == 1) begin
                        //mask <= dip_swicth; //I think I can assign here bc no other block assigns to it.
                        //oh wait I want to invert bc dips active low
                        mask[0] <= ~dip_swicth[0]; mask[1] <= ~dip_swicth[1];
                        mask[2] <= ~dip_swicth[2]; mask[3] <= ~dip_swicth[3];
                        mask[4] <= ~dip_swicth[4]; mask[5] <= ~dip_swicth[5];
                        mask[6] <= ~dip_swicth[6]; mask[7] <= ~dip_swicth[7];
						//play it safe mnt_stb <=1;		//try earlier strobe raise to communicate data from here to mentor - didn't help
                        loadmask_state <= 2'b11;
					end
				end

				2'b11: begin
					// raise strobe
					mnt_stb <= 1;
					loadmask_state <= 2'b01;
				end

				2'b01: begin
					// lower strobe
					mnt_stb <= 0;
					loadmask_state <= 2'b00;
				end

			endcase
		end
	end



    /* broken single - loop version
    reg [2:0] loadmask_state = 3'b000;

    always @(posedge CLK_O) begin
		if (RST_O) begin
			loadmask_state <= 3'b000;
            mask <= 8'b00000000;          //I think it's safe to assign here, no other block does
            debounce_in_strobe <= 0;        //make sure we're not asking for button state
		end else begin
			case(loadmask_state)
				3'b000: begin
                    //dummy state to sit in and do nothing while reset is active.
                    //once control comes back, segue to 001.
                    loadmask_state <= 3'b001;
                end

                3'b001: begin
                    //start a read of the button state.
                    //I guess here we'd load a button mask, if we were going to do stuff like that.
                    //let's do a dummy. Timing might be bad, need another tick before raising strobe?
                    //or I guess the mask can be steady. Anyway, atm it does nothing.
                    debounce_mask <= 8'b00000001;       //but paying attention only to bottom bit if we want
                    debounce_in_strobe <= 1;
                    loadmask_state <= 3'b011;
                end

                3'b011: begin
                    //bring the debounce strobe down and harvest the button state once we get the ack.
                    debounce_in_strobe <= 0;
                    if(debounce_out_strobe) begin
                        button_streg <= button_state;           //memorize output from button reader
                        loadmask_state <= 3'b111;
                    end
                end


                3'b111: begin
                    //let's say we wait here until the button is released
                    //so if it's pressed, button_streg[0] == 1, so we just go back and read the button
                    //again.
                    // REALLY TIGHT LOOP! but what else to do
                    // I suppose a separate state machine could maintain button_streg
                    //... what if this state waits for button release, then 10 waits for press?
                    //I think that's a better way to handle it wrt reset too
                    if (button_streg[0] == 0) begin
                        loadmask_state <= 3'b110;
                    end else begin
                        loadmask_state <= 3'b001;           //jump back and read again
                    end
                end

                3'b110: begin
                    // previous state waited for button release, this one waits for press.
                    ****************** WAIT THIS WON'T WORK because the state transition will have it
                    ****************** go to the wait-for-release loop ...
                    *** yeah, let's make a loop that just updates button state
                    end
                    if (button_streg[0] == 1) begin
                        mask <= dip_swicth; //I think I can assign here bc no other block assigns to it.
						//play it safe mnt_stb <=1;		//try earlier strobe raise to communicate data from here to mentor - didn't help
                        loadmask_state <= 3'b010;
					end else begin
                        loadmask_state <= 3'b001;           //go read again
                    end
				end

				3'b010: begin
					// raise strobe
					mnt_stb <= 1;
					loadmask_state <= 3'b101;
				end

				3'b101: begin
					// lower strobe
					mnt_stb <= 0;
					loadmask_state <= 3'b001;
				end

			endcase
		end
	end
    */

    // broken no-fetch version
    //ok, this is all fine, but missing some stuff.
    //like, ever fetching the button state. We need more states!
    /*
    reg [1:0] loadmask_state = 2'b00;

    always @(posedge CLK_O) begin
		if (RST_O) begin
			loadmask_state <= 2'b00;
            mask <= 2'b00;          //I think it's safe to assign here
		end else begin
			case(loadmask_state)
				2'b00: begin
					// do nothing unless it's time to go to 10
                    // which is when we have a positive edge on the button.
                    //... what if this state waits for button release, then 10 waits for press?
                    //I think that's a better way to handle it wrt reset too
                    if (button_state[0] == 0) begin
                        loadmask_state <= 2'b10;
                    end
                end

                2'b10: begin
                    // previous state waited for button release, this one waits for press.
                    if (button_state[0] == 1) begin
                        mask <= dip_swicth; //I think I can assign here bc no other block assigns to it.
						//play it safe mnt_stb <=1;		//try earlier strobe raise to communicate data from here to mentor - didn't help
                        loadmask_state <= 2'b11;
					end
				end

				2'b11: begin
					// raise strobe
					mnt_stb <= 1;
					loadmask_state <= 2'b01;
				end

				2'b01: begin
					// lower strobe
					mnt_stb <= 0;
					loadmask_state <= 2'b00;
				end

			endcase
		end
	end
    */
    /*
  // ORIGINAL TIMED MASK THING ================================================================================
	//For now, we have the reset logic above, and if I were clever I could rope this into prewish_sim_tb and use it a combination syscon/mentor thing there too.
	//so:
	//what if I did a great big dividey clock that drives the initial version, pick a new mask every 5 seconds or so.
	//12MHz / 5Hz = 2,400,000, so could do a 2M divider and be in the hideyallpark.
	//that's 21 bits, yes? that sounds like too few. aha, bc we don't want 5Hz, we want 1/5Hz, so do like 26 bits.
	//25 is my latest guess.
	//if 23 is a nice brisk alive-blinky, 25 is way too few for newmask. alive is ~3Hz posedges, we want maybe 1/16th of that, so let's try
	//27
	parameter NEWMASK_CLK_BITS=28;		//default for "build"
	reg [NEWMASK_CLK_BITS-1:0] newmask_clk_ct = 0;
	reg newmask_hi_last = 0;

	always @(posedge CLK_O) begin
		if (~RST_O) begin
			newmask_clk_ct <= newmask_clk_ct + 3;  //was 1, try to stir up
			newmask_hi_last <= newmask_clk_ct[NEWMASK_CLK_BITS-1];		//FOR SPOTTING EDGE IN STATE MACHINE hopework must match the wire assignment below
		end else begin
			newmask_clk_ct <= 0;
		end
	end

	wire newmask_clk = newmask_clk_ct[NEWMASK_CLK_BITS-1];			//hopework - does! but much too predictable,
	//how to fudge it out a bit? Or just make it not a NRN.
  // END ORIGINAL TIMED MASK THING ========================================================================

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
		if(RST_O) begin
			mask <= 0;
		end else begin
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
		end
		//can't assign to stuff in two different clockyblocks!
		//newmask_state <= 2'b10;
		//newmask_flag <= 1;			//does this respond fast enough? Should be no different than assigning the state
	end

	always @(posedge CLK_O) begin
		if (RST_O) begin
			newmask_state <= 2'b00;
			/// should this be here? Kind of a multiple assign.
			//*************************************************************************************************************************************************
			//*************************************************************************************************************************************************
			// HERE IS THE PROBLEM ! multiple assign of 0 doesn't seem to throw an error but it FUCKS THINGS UP
			//mask <= 0;  //THIS MAY BE WHAT BROKE IT
			//similar this:
			//newmask_index = 3'b000;
		end else begin
			case(newmask_state)
				2'b00: begin
					// do nothing unless it's time to go to 10
					if(newmask_hi_last != newmask_clk_ct[NEWMASK_CLK_BITS-1]) begin		//see if that detects a  newmask clk edge
						newmask_state <= 2'b10;
						mnt_stb <=1;		//try earlier strobe raise to communicate data from here to mentor - didn't help
					end
				end

				2'b10: begin
					// lower newmask_flag so we don't dump right back in here from 00
					//oops, multiple drivers. Do we need to do this? newmask_flag <= 0;
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
*/
endmodule
