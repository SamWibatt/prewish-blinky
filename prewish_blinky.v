/*
All right! So here's the blinky part. Do the subset of the wishbone port. Per docs, about STUDENTs, 

CLK_I
The clock input [CLK_I] coordinates all activities for the internal logic within the WISHBONE interconnect. All WISHBONE 
output signals are registered at the rising edge of [CLK_I]. All WISHBONE input signals are stable before the rising edge of [CLK_I].

DAT_I()
The data input array [DAT_I()] is used to pass binary data. The array boundaries are determined by the port size, with a 
maximum port size of 64-bits (e.g. [DAT_I(63..0)]). Also see the [DAT_O()] and [SEL_O()] signal descriptions.

RST_I
The reset input [RST_I] forces the WISHBONE interface to restart. Furthermore, all internal self-starting state machines 
will be forced into an initial state. This signal only resets the WISHBONE interface. It is not required to reset other 
parts of an IP core (although it may be used that way).

STB_I
The strobe input [STB_I], when asserted, indicates that the STUDENT is selected. A STUDENT shall respond to other WISHBONE 
signals only when this [STB_I] is asserted (except for the [RST_I] signal which should always be responded to). The 
STUDENT asserts either the [ACK_O], [ERR_O] or [RTY_O] signals in response to every assertion of the [STB_I] signal.
*/

module prewish_blinky (
    input CLK_I,
    input RST_I,
    input STB_I,
    input[7:0] DAT_I,
    output o_led
);
    //I think inputs are assumed to be wires?    
    
    reg[7:0] mask = 0;          //high bits mean LED on
    // unnecessary reg carry = 0;              //for rotating mask
    
    //ok so now we need a divide-em-down counter so sysclk is the input clock
    //-- Numero de bits del prescaler (por defecto), can override in instantiation 
    parameter SYSCLK_DIV_BITS = 22;

    //-- Registro para implementar contador de SYSCLK_DIV_BITS bits
    reg [SYSCLK_DIV_BITS-1:0] ckdiv = 0;

    //-- El bit más significativo se saca por la salida, this could be the "clock" that advances the mask
    //see if we can avoid lagging by doing it st the clock ... rises when ckdiv is 0 and is just a pulse?
    //SEEMS TO WORK JUST FINE
    assign mask_clk = ckdiv == 1;   //ckdiv[SYSCLK_DIV_BITS-1];       
    reg o_led = 0;     //see if can do *********** possibug

    //ok, adding to sensitivity list. mask_clk doesn't really need to be routed like a clock,
    //and I'm trying to get finer grained response to the strobe and reset, yes?
    //should I just do this in the main loop?
    always @(posedge mask_clk, posedge STB_I, posedge RST_I) begin
        if(~RST_I & ~STB_I) begin
            mask <= mask <<< 1;         // can you do this? you can do this!
            mask[0] <= mask[7]; 
            // *********** possibug, may be laggy (may be unavoidbly so) or worse, skip the first bit of the
            // pattern first time
            // also do I need to assign it to a wire?
            o_led <= mask[7];
            //if we get off by one bit maybe this will work :)
            //o_led <= mask[0];
        end
    end
    
    always @(posedge CLK_I) begin
        if(RST_I == 1) begin            // reset case, just keep the mask pasted down
            ckdiv <= 0;
            mask <= 0;
            o_led <= 0;                 // *********possibug
        end else begin
            if(STB_I == 1) begin   // strobe case, load mask with DAT
                ckdiv <= 0;
                                 // *********possibug
                o_led <= 0;        // shut off active high LED during load
                mask <= DAT_I;
            end else begin
                ckdiv = ckdiv + 1;
                
                //so if I were going to move the mask roll stuff in here, how would it work?
                //could do a reg that is set to 0 during reset and if it's 0 here we ...
                //or maybe strobe, if last cycle was strobe and this is not strobe, then 
                //set the LED to the top of the mask?
                //*************************** think re
                //but I don't think I need to
            end
        end
    end
    
    //pre-sync version assign o_led = mask[7];

    /* non-divided version
    always @(posedge CLK_I) begin
        if(RST_I == 1) begin            // reset case, just keep the mask pasted down
            mask <= 0;
        end else if(STB_I == 1) begin   // strobe case, load mask with DAT
            mask <= DAT_I;
        end else begin                  // main case, rotate mask to the left
            mask <= mask <<< 1;         // can you do this? you can do this!
            mask[0] <= mask[7]; 
        end
    end
    
    assign oN_led = ~mask[7];   //negated bc active low and bits are high = on for ease of reading
    */
    
endmodule

