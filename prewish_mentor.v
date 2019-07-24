/*
Here's the dummy mentor, let's say it's a state machine that 
00 - reset / initial state, advances to 01 once reset is off
01 - set up data for mask, raise strobe, advance to 11
11 - lower strobe, stay in 11 forever
*/

module prewish_mentor(
    input CLK_I,
    input RST_I,
    output STB_O,
    output[7:0] DAT_O
);
    reg[1:0] state = 2'b00;
    reg strobe_reg = 0;
    reg[7:0] dat_reg = 8'b00000000; 
    
    //write this stuff!!!
    //INCOMPLETE AND PROBABLY WRONG!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    always @(posedge CLK_I) begin
        if(RST_I == 1) begin
            strobe_reg <= 0;
            state <= 2'b00;
        end else begin
            //state machine stuff
            case (state) 
                2'b00 : begin
                    //00 - reset / initial state, advances to 01 once reset is off
                    state[0] <= 1;
                    dat_reg <= 8'b10100000; //arbitrary two-blink mask that looks distinctive and is easy to recognize in outputs - try here to have ready before strobe
                end

                2'b01 : begin
                    //01 - set up data for mask, raise strobe, advance to 11
                    strobe_reg <= 1;
                    state[1] <= 1'b1;
                end

                2'b11 : begin
                    //11 - lower strobe, stay in 11 forever
                    strobe_reg <= 0;
                end

                2'b10 : begin
                    // 10 = nonexistent, just go to state 0? lower strobe just in case. may use as last state and b11 as a wait state if strobe doesn't work.
                    strobe_reg <= 0;
                    state <= 2'b00;
                end
            endcase

        end
    end
    
    assign STB_O = strobe_reg;      //is this how I should do this? Similar seems to work with reset... hm. Well, see what we get
    assign DAT_O = dat_reg;         //and is this how you send data?
    
endmodule

