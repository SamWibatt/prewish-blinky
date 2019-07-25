/*
Here's the dummy mentor, let's say it's a state machine that 
Student interface can receive data from testbench, which touches off the state machine.
state
any - if RST_I is 1, zero everything out incl state
00 - reset/initial, send all the outgoing signals low, load data advance to 01 if STB_I goes high
01 - if STB_I is low, advance to 11 and raise STB_O
11 - lower STB_O, go to 00
10 - currently meaningless, zero out STB_O and go to 00 

old state machine
00 - reset / initial state, advances to 01 once reset is off
01 - set up data for mask, raise strobe, advance to 11
11 - lower strobe, stay in 11 forever

*/

module prewish_mentor(
    input CLK_I,        //mentor/outgoing interface, writes to blinky
    input RST_I,
    output STB_O,
    output[7:0] DAT_O,
    input STB_I,        //then here is the student that takes direction from testbench
    input[7:0] DAT_I
);
    reg[1:0] state = 2'b00;
    reg strobe_reg = 0;
    reg[7:0] dat_reg = 8'b00000000; 
    
    //HERE IS THERE SOME WAY FOR ME TO LAUNDER THE POSSIBLY ASYNC INPUTS?
    //OR SINCE WE'RE BEING WISHBONEY SHOULD I ASSUME THEY'RE SYNCHRONIZED?
    //If async, or in any case to get in the habit? I should do the flipflop thing, per
    //http://zipcpu.com/blog/2017/05/24/serial-port.html, looks something like
    //always @(posedge i_clk)
	//  r_uart <= i_uart;
    //always @(posedge i_clk)
	//  ck_uart <= r_uart;

    //state machine
    always @(posedge CLK_I) begin
        if(RST_I == 1) begin
            strobe_reg <= 0;
            state <= 2'b00;
        end else begin
            //state machine stuff
            case (state) 
                2'b00 : begin
                    //00 - reset/initial, send all the outgoing signals low, load data advance to 01 if STB_I goes high
                    //otherwise just stay here
                    strobe_reg <= 0;
                    if(STB_I == 1) begin
                        dat_reg <= DAT_I;   //load data from input pins to output register
                        state <= 2'b01;      //advance to 01
                    end
                end

                2'b01 : begin
                    //01 - if STB_I is low, advance to 11 and raise STB_O
                    if(~STB_I) begin
                        strobe_reg <= 1;
                        state <= 2'b11;
                    end
                end

                2'b11 : begin
                    //11 - lower STB_O, go to 00
                    strobe_reg <= 0;
                    state <= 2'b00;
                end

                2'b10 : begin
                    //10 - currently meaningless, zero out stb_o and go to 00
                    strobe_reg <= 0;
                    state <= 2'b00;
                end
            endcase

        end
    end
    
    assign STB_O = strobe_reg;      //is this how I should do this? Similar seems to work with reset... hm. Well, see what we get
    assign DAT_O = dat_reg;         //and is this how you send data?
    
endmodule

