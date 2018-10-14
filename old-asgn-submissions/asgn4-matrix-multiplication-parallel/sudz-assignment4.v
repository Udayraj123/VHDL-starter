module
    assign4try1(
        // FX2 interface -----------------------------------------------------------------------------
        input  wire      fx2Clk_in,     // 48MHz clock from FX2
        output wire[1:0] fx2Addr_out,   // select FIFO: "10" for EP6OUT, "11" for EP8IN
        inout  wire[7:0] fx2Data_io,    // 8-bit data to/from FX2
 
        // When EP6OUT selected:
        output wire      fx2Read_out,   // asserted (active-low) when reading from FX2
        output wire      fx2OE_out,     // asserted (active-low) to tell FX2 to drive bus
        input  wire      fx2GotData_in, // asserted (active-high) when FX2 has data for us
 
        // When EP8IN selected:
        output wire      fx2Write_out,  // asserted (active-low) when writing to FX2
        input  wire      fx2GotRoom_in, // asserted (active-high) when FX2 has room for more data from us
        output wire      fx2PktEnd_out, // asserted (active-low) when a host read needs to be committed early
 
        // Onboard peripherals -----------------------------------------------------------------------
        output wire[7:0] led_out       // eight LEDs
    );
 
    // Channel read/write interface -----------------------------------------------------------------
    wire[6:0]  chanAddr;  // the selected channel (0-127)
 
    // Host >> FPGA pipe:
    wire[7:0]  h2fData;   // data lines used when the host writes to a channel
    wire       h2fValid;  // '1' means "on the next clock rising edge, please accept the data on h2fData_out"
    wire       h2fReady;  // channel logic can drive this low to say "I'm not ready for more data yet"
 
    // Host << FPGA pipe:
    wire[7:0]  f2hData;   // data lines used when the host reads from a channel
    wire       f2hValid;  // channel logic can drive this low to say "I don't have data ready for you"
    wire       f2hReady;  // '1' means "on the next clock rising edge, put your next byte of data on f2hData_in"
    // ----------------------------------------------------------------------------------------------
 
    // Needed so that the comm_fpga_fx2 module can drive both fx2Read_out and fx2OE_out
    wire       fx2Read;
   
    //BEGIN_SNIPPET(registers)
    // hard coding wires for each of the 16 rows
    // if there is a better solution, leave a comment, it will be updated
    reg[7:0] inputData = 8'b00000000;
    reg[7:0] state = 8'b00000000;
    reg[7:0] index = 8'b00000000;
    reg[7:0] inputB = 8'b00000000;
    wire[7:0] doutWire;
   wire[7:0] doutWire1;
   wire[7:0] doutWire2;
   wire[7:0] doutWire3;
   wire[7:0] doutWire4;
    wire[7:0] doutWire10;
   wire[7:0] doutWire11;
   wire[7:0] doutWire12;
   wire[7:0] doutWire13;
   wire[7:0] doutWire14;
    wire[7:0] stateWire3;
   wire[7:0] stateWire4;
   wire[7:0] stateWire5;
   wire[7:0] stateWire6;
   wire[7:0] stateWire7;
   wire[7:0] stateWire8;
   wire[7:0] stateWire9;
   wire[7:0] doutWire15;
   wire[7:0] doutWire16;
    wire[7:0] inputDataNext ;
    wire[7:0] stateNext;
    wire[7:0] indexNext;
    wire[7:0] inputBNext;
   wire[7:0] weWire;
    wire[7:0] inuptWireB;
   wire[7:0] addrWire;
   wire[7:0] dinWire;
   wire[7:0] doutWire5;
   wire[7:0] doutWire6;
   wire[7:0] doutWire7;
   wire[7:0] doutWire8;
   wire[7:0] doutWire9;
   wire[7:0] stateWire;
    wire[7:0] stateWire1;
   wire[7:0] stateWire2;
    wire[7:0] inputWireB;
    wire[7:0] clkWire;
   wire[7:0] stateWire10;
   wire[7:0] stateWire11;
   wire[7:0] stateWire12;
   wire[7:0] stateWire13;
   wire[7:0] stateWire14;
   wire[7:0] stateWire15;
   wire[7:0] stateWire16;
 
    assign clkWire = fx2Clk_in;
    assign dinWire = inputData;
    assign weWire = ( state == 1 ) ? 1 : 0;
    assign addrWire = (index%16);
   
    // all these assignments are hard coded
    assign doutWire = (index < 16)  ? doutWire1
                         : (index < 32)  ? doutWire2
                         : (index < 48)  ? doutWire3
                         : (index < 64)  ? doutWire4
                         : (index < 80)  ? doutWire5
                         : (index < 96)  ? doutWire6
                         : (index < 112) ? doutWire7
                         : (index < 128) ? doutWire8
                         : (index < 144) ? doutWire9
                         : (index < 160) ? doutWire10
                         : (index < 176) ? doutWire11
                         : (index < 192) ? doutWire12
                         : (index < 208) ? doutWire13
                         : (index < 224) ? doutWire14
                         : (index < 240) ? doutWire15
                         :                 doutWire16;
                         
    assign stateWire1 = ( state == 1 && index < 16)   ? 1
                     : ( state == 1 )                 ? 0
                                                            : state;                          
    assign stateWire2 = ( state == 1 && index > 15 && index < 32 ) ? 1
                     : ( state == 1 )                              ? 0
                                                                         : state;                          
    assign stateWire3 = ( state == 1 && index > 31 && index < 48 ) ? 1
                     : ( state == 1 )                              ? 0
                                                                         : state;                          
    assign stateWire4 = ( state == 1 && index > 47 && index < 64 ) ? 1
                     : ( state == 1 )                              ? 0
                                                                         : state;                          
    assign stateWire5 = ( state == 1 && index > 63 && index < 80 ) ? 1
                     : ( state == 1 )                              ? 0
                                                                         : state;                          
    assign stateWire6 = ( state == 1 && index > 79 && index < 96 ) ? 1
                     : ( state == 1 )                              ? 0
                                                                         : state;                          
    assign stateWire7 = ( state == 1 && index > 95 && index < 112 )? 1
                     : ( state == 1 )                              ? 0
                                                                         : state;                          
    assign stateWire8 = ( state == 1 && index > 111 && index < 128 )? 1
                     : ( state == 1 )                               ? 0
                                                                          : state;                          
    assign stateWire9 = ( state == 1 && index > 127 && index < 144 )? 1
                     : ( state == 1 )                               ? 0
                                                                          : state;                          
    assign stateWire10= ( state == 1 && index > 143 && index < 160 )? 1
                     : ( state == 1 )                               ? 0
                                                                          : state;                          
    assign stateWire11= ( state == 1 && index > 159 && index < 176 )? 1
                     : ( state == 1 )                               ? 0
                                                                          : state;                          
    assign stateWire12= ( state == 1 && index > 175 && index < 192 )? 1
                     : ( state == 1 )                               ? 0
                                                                          : state;                          
    assign stateWire13= ( state == 1 && index > 191 && index < 208 )? 1
                     : ( state == 1 )                               ? 0
                                                                          : state;                          
    assign stateWire14= ( state == 1 && index > 207 && index < 224 )? 1
                     : ( state == 1 )                               ? 0
                                                                          : state;                          
    assign stateWire15= ( state == 1 && index > 223 && index < 240 )? 1
                     : ( state == 1 )                               ? 0
                                                                          : state;                          
    assign stateWire16= ( state == 1 && index > 239 && index < 256 )? 1
                     : ( state == 1 )                               ? 0
                                                                          : state;                          
   
    // Infer registers
    always @(posedge fx2Clk_in)
    begin
        state = stateNext;
        index = (state == 0|| state == 1 || state == 2) ? indexNext : index;
        inputData = inputDataNext;
        inputB = inputBNext;
    end
   
    assign inputWireB = inputB;
    assign inputDataNext = (chanAddr == 7'b0000000 && h2fValid == 1'b1) ? h2fData : inputData;
 
    assign stateNext = (chanAddr == 7'b0000001 && h2fValid == 1'b1) ? h2fData : state;
 
    assign indexNext = (chanAddr == 7'b0000010 && h2fValid == 1'b1) ? h2fData : index;
 
    assign inputBNext = (chanAddr == 7'b0000011 && h2fValid == 1'b1) ? h2fData : inputB;
       
    // Select values to return for each channel when the host is reading
    assign f2hData =
        (chanAddr == 7'b0001000 && state==2) ? doutWire : 8'h05;
 
    // Assert that there's always data for reading, and always room for writing
    assign f2hValid = 1'b1;
    assign h2fReady = 1'b1;                                                  //END_SNIPPET(registers)
   
    // CommFPGA module
    assign fx2Read_out = fx2Read;
    assign fx2OE_out = fx2Read;
    assign fx2Addr_out[1] = 1'b1;  // Use EP6OUT/EP8IN, not EP2OUT/EP4IN.
   
   /*communication with host, same as in example*/
    comm_fpga_fx2 comm_fpga_fx2(
        // FX2 interface
        .fx2Clk_in(fx2Clk_in),
        .fx2FifoSel_out(fx2Addr_out[0]),
        .fx2Data_io(fx2Data_io),
        .fx2Read_out(fx2Read),
        .fx2GotData_in(fx2GotData_in),
        .fx2Write_out(fx2Write_out),
        .fx2GotRoom_in(fx2GotRoom_in),
        .fx2PktEnd_out(fx2PktEnd_out),
 
        // Channel read/write interface
        .chanAddr_out(chanAddr),
        .h2fData_out(h2fData),
        .h2fValid_out(h2fValid),
        .h2fReady_in(h2fReady),
        .f2hData_in(f2hData),
        .f2hValid_in(f2hValid),
        .f2hReady_out(f2hReady)
    );
 
    // LEDs and 7-seg display
    assign led_out = doutWire;

/* This module needs to be defined separately and multiple such modules will operate parallely.*/ 
row row1(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire1),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire1)
);
 
row row2(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire2),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire2)
);
 
row row3(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire3),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire3)
);
 
row row4(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire4),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire4)
);
 
row row5(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire5),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire5)
);
 
row row6(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire6),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire6)
);
 
row row7(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire7),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire7)
);
 
row row8(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire8),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire8)
);
 
wire[7:0] garbage;
row row9(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire9),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire9)
);
 
row row10(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire10),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire10)
);
 
row row11(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire11),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire11)
);
 
row row12(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire12),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire12)
);
 
row row13(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire13),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire13)
);
 
row row14(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire14),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire14)
);
 
row row15(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire15),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire15)
);
 
row row16(
    .inpR(dinWire),
    .inpB(inputWireB),
    .opR(doutWire16),
    .clkR(clkWire),
    .addrR(addrWire),
    .stateR(stateWire16)
);
 
endmodule
 
module row
    (
    input wire [7:0] inpR,
    input wire [7:0] inpB, 
   input wire clkR,
    input wire [7:0] stateR,
    input wire [7:0] addrR,
    output wire [7:0] opR
    );
// module row definition, matrixArow1 is bloack ram and used to store data
// calc and stateR help in deciding the finalAns
wire[0:0] weWire;
wire[7:0] ramOutput;
reg[7:0] finalAns;
reg[7:0] regInpB;
reg calc = 0;
assign opR = finalAns;
assign weWire = (stateR == 1) ? 1 : 0;
 
    always @(posedge clkR)
        begin
            regInpB = inpB;
            finalAns = (stateR == 3) ? 0  
                        : (stateR == 4 && calc == 1) ? finalAns + ramOutput * regInpB
                        :                              finalAns;
            calc = ( stateR == 4) ? 0
                 : ( stateR == 0) ? 1
                  :                  calc;
        end
 
matrixArow1 row1(
  .clka(clkR),
  .wea(weWire),
  .addra(addrR),
  .dina(inpR),
  .douta(ramOutput)
);
 
 
endmodule