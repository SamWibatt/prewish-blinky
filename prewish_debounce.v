// debouncer for the buttons and swicths that input our mask and stuff.
// per https://www.fpga4student.com/2017/04/simple-debouncing-verilog-code-for.html
`default_nettype	none

// here's their way of doing async laundering through two dffs:

/* THIS VERSION DUNT WORK
//first this:
// D-flip-flop for debouncing module
// sean adds reset - and init; ffs were showing red in the simulator until a couple clocks came along
module my_dff(input reset, input DFF_CLOCK, D, output Q);
    reg Q = 0;      //can I initialize like this?
    always @ (posedge DFF_CLOCK) begin
        if(~reset) begin
            Q <= D;
        end else begin
            Q <= 1;         //try this for reset logic w/active low button
        end
    end
endmodule

//one-signal debouncing modulelet
//is there any reason not to just have one of these per button?
//the clock divider gets wasteful. I will pull it out and make it a parameter, and after that we should be fine.
//the rest of this is a 2ff debouncer in the classic style and should be nice and lean.
// I MAY NEED TO ADD A RESET
// also may need to clock this faster than typical MCU debouncer, bc it advances the signal through a couple rounds of flip-flop.
// sean adds reset
module debounce(input reset, input pb_1,slow_clk,output pb_out);
	//wire slow_clk;
	//clock_div u1(clk,slow_clk);		//caller will supply slow clock.
	wire Q1,Q2,Q2_bar;

	//I suspect I'll need a chunk like these 4 lines for every input.
	//also instead of assigning wires at the end, stick these in registers
	//for polling to pick up on
	//can do an interrupty one later that has like direct reset button input or wev
	//is that a good choice for a for loop, verilog-style? LOOK INTO IT!
    my_dff d1(reset, slow_clk, pb_1,Q1 );
    my_dff d2(reset, slow_clk, Q1,Q2 );
	assign Q2_bar = ~Q2;
	assign pb_out = Q1 & Q2_bar;            //so... what does this do? if it is an edge detector. ???
	//end need a chunk like these 4
endmodule
*/

//instead try the Gisselquist version from his tutorial's lesson 7 "bouncing"
// - on new Takkubuntu /home/sean/dev/FPGA/ex-07-bouncing
// here is Gisselquist's debouncer.v hacked up to have the slowed down clock be a parameter
// only... it doesn't really work like that.
// you have to be able to reset the timer.
// and every thing that gets debounced needs its own timer!
// gross!
// I guess you could use a somewhat divided down system clock

module	debouncer(i_clk, i_btn, o_debounced);
	//parameter	TIME_PERIOD = 75000; //...does this fit in 16 bits?
  //I will do my own, where the time period divides down to like 120Hz,
  //assuming 12 Mhz sys clk, so 100,000 ?
  //have adjustable # bits strobe_o_reg
  parameter TIME_PERIOD = 100000;
  parameter TIME_BITS = 17;
	input	wire	i_clk, i_btn;
	output	reg	o_debounced;

	reg	r_btn, r_aux;
	reg	[TIME_BITS-1:0]	timer;

	// Our 2FF synchronizer
	initial	{ r_btn, r_aux } = 2'b00;
	always @(posedge i_clk)
		{ r_btn, r_aux } <= { r_aux, i_btn };

	// The count-down timer
	initial	timer = 0;
	always @(posedge i_clk)
	if (timer != 0)
		timer <= timer - 1;
	else if (r_btn != o_debounced)
		timer <= TIME_PERIOD[TIME_BITS-1:0] - 1;

	// Finally, set our output value
	initial	o_debounced = 0;
	always @(posedge i_clk)
	if (timer == 0)
		o_debounced <= r_btn;

`ifdef	FORMAL
	//
	// What properties would you place here?
	//
`endif	// FORMAL
endmodule



// MY OWN MODULE ============================================================================================----
module prewish_debounce(
    input CLK_I,
    input RST_I,
    output STB_O,        //mentor/outgoing interface, writes to caller with current status byte
    output[7:0] DAT_O,
    input STB_I,        //then here is the student that takes direction from testbench
    input[7:0] DAT_I,
    input i_button,	// active HIGH input from button, caller presumably just passes this straight along from a pad WILL BE REFACTORED INTO AN ARRAY
    //input i_dbclock,	// debounce (slow) clock
	  //output ACK_O,		// do I need this? let's say not, for the moment; I think it's for stuff that might not work right away and will ping back later with results?
    output o_alive      // debug outblinky
);

    /*
    So what does this do? It purely just grabs what's in the status byte and throws that back.
    First version, status byte is always 00000
    The interface is pretty confused. Should I take out the write part? No,
    this module will always exist on the chip and be running, it's not a function. So the fast and slow clock lines will come in and
    advance the debounce modules & stuff.
    Interface is like if caller writes *anything* to data, you get back the state. First cut. Strobe is really the only input signal that matters.
    Later could have DAT_I be a mask and just AND it with the the state (being sure to correct for active low/high.)
    */
    reg[1:0] state = 2'b00;		//state machine state
    reg strobe_o_reg = 0;		//for letting state machine send STB_O
    reg alivereg = 0;           //debug thing to toggle alive-LED when strobes happen?
    reg [7:0] dat_reg = 8'b0;   //for saving the switch state for return to caller

    reg[7:0] button_state = 8'b0;	// button state (not to be confused with state machine state) - ACTIVE HIGH even though inputs are active low

   //here are the little mechanisms that make a single input work, WILL BE REFACTORED INTO AN ARRAY OR FOR LOOP OR SOMETHING
    wire button_debounced;
    //old  debounce db(RST_I,i_button,i_dbclock,button_wire);			//so this makes it so button_wire always has the "current" bit, synched through 2 layers of ff.
    //here's the Gisselquist way, and is this a good place to switch on the sim_step def?
    //this works. use iverilog -D SIM_STEP in build
    `ifdef SIM_STEP
      debouncer #(.TIME_PERIOD(37),.TIME_BITS(6)) deb(.i_clk(CLK_I), .i_btn(i_button), .o_debounced(button_debounced));
    `else
      debouncer deb(CLK_I, i_button, button_debounced);
    `endif

   //so here shift button wire into the status register!
   //THIS IS GOING TO LOOK A LOT LIKE PREWISH_MENTOR!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   always @(posedge CLK_I) begin
      if(RST_I == 1) begin
          strobe_o_reg <= 0;
          state <= 2'b00;
		      button_state <= 0;
      end else begin
		  //IS THIS WHERE TO SHIFT STUFF INTO STATE?
  		//HARDCODE STATE 0 IS BUTTON.
  		// remember we're doing active low inputs so invert.
  		//button_state[0] <= ~button_wire;
      //button_state[0] <= button_wire;     //not not negating at this point bc it happens on the dat_reg assignment
      //might need to do it below in the dat reg thing - though this seems to be getting there
      button_state[0] <= button_debounced;

      //integer ii=0;       //for for loop below

      //state machine stuff
      case (state)
          2'b00 : begin
              //00 - reset/initial, send all the outgoing signals low, load data advance to 01 if STB_I goes high
              //otherwise just stay here
              //I think the nice thing about separate state is waiting for STB_I to be let off, so let's stay with it for now.
              strobe_o_reg <= 0;
              if(STB_I == 1) begin
                  alivereg <= ~alivereg;  //toggle alive-reg for debug. this works for one register
                  //THIS FIXED IT dat_reg <= 8'b10110100;	//DEBUG TEST WAS
                  //temp test outcomment see @posedge clk_i above
                  //dat_reg <= ~button_state;       //load data from button state to output register - this doesn't work, see https://stackoverflow.com/questions/29459696/verilog-how-to-negate-an-array
                  //that doesn't work either, see instead https://www.nandland.com/vhdl/examples/example-for-loop.html - the rare synthesizable FOR!
                  //for(ii=0; ii<7; ii=ii+1) begin
                      //r_Shift_With_For[ii+1] <= r_Shift_With_For[ii];
                      //dat_reg[ii] <= ~button_state[ii];
                  //end
                  //feh, that didn't work either, gets errors about ii whether I call it integer or reg or whatever so for now let's just do it dumb
                  //this doesn't appear to be communicating anything to button_state OR dat_reg. Let's move it to the next state...? Would that make it too late for data to be ready when strobe goes high?
                  //OH WAIT I WAS NEVER ADVANCING STATES
                  // actually, I think it IS working, it's just my testbench case isn't very interesting.
                  // NOT ACTIVE LOW ANYMORE these used to be ~button_state[n]
                  dat_reg[0] <= button_state[0];
                  dat_reg[1] <= button_state[1];
                  dat_reg[2] <= button_state[2];
                  dat_reg[3] <= button_state[3];
                  dat_reg[4] <= button_state[4];
                  dat_reg[5] <= button_state[5];
                  dat_reg[6] <= button_state[6];
                  dat_reg[7] <= button_state[7];

                  state <= 2'b01;                     //forgot this wrinkle
              end
          end

          2'b01 : begin
              //01 - if STB_I is low, advance to 11 and raise STB_O
              if(~STB_I) begin
                  strobe_o_reg <= 1;
                  state <= 2'b11;
              end
          end

          2'b11 : begin
              //11 - lower STB_O, go to 00
              strobe_o_reg <= 0;
              state <= 2'b00;
          end

          2'b10 : begin
              //10 - currently meaningless, zero out stb_o and go to 00
              strobe_o_reg <= 0;
              state <= 2'b00;
          end
      endcase

    end
  end

  assign STB_O = strobe_o_reg;      //is this how I should do this? Similar seems to work with reset... hm. Well, see what we get
  assign DAT_O = dat_reg;         //and is this how you send data? seems to have an extra assign (state -> dat_reg), but who knows when state might have changed... let's keep an eye on

  assign o_alive = ~alivereg;      // debug LED should toggle when strobe happens - the ~ should make it start out on 1, yes?


endmodule
