`default_nettype none
module rc4(

    //////////// CLOCK //////////
    CLOCK_50,

    //////////// LED //////////
    LEDR,

    //////////// KEY //////////
    KEY,

    //////////// SW //////////
    SW,

    //////////// SEG7 //////////
    HEX0,
    HEX1,
    HEX2,
    HEX3,
    HEX4,
    HEX5
);

//=======================================================
//  PORT declarations
//=======================================================

//////////// CLOCK //////////
input   CLOCK_50;


//////////// LED //////////
output           [9:0]      LEDR;

//////////// KEY //////////
input            [3:0]      KEY;

//////////// SW //////////
input            [9:0]      SW;

//////////// SEG7 //////////
output           [6:0]      HEX0;
output           [6:0]      HEX1;
output           [6:0]      HEX2;
output           [6:0]      HEX3;
output           [6:0]      HEX4;
output           [6:0]      HEX5;



//wire declarations
wire CLOCK_50;
wire [3:0] KEY;
wire [9:0] SW;
wire [9:0] LEDR;
wire [6:0] HEX0;
wire [6:0] HEX1;
wire [6:0] HEX2;
wire [6:0] HEX3;
wire [6:0] HEX4;
wire [6:0] HEX5;

wire [23:0] secret_key;

parameter ROM_FILE = "../secret_messages/msg_1_for_task2b/message.mif";
parameter CORE = 1; //max core number is 85
parameter CORE_LEN=8;   //minimal bits required to represent "CORE" 

/*
rc4_crack_core task2(
    .clk(CLOCK_50),
    .reset(),
    .secret_key_raw({14'b0,SW}),
    .finish(~LEDR[0]),
    .valid(LEDR[1])
);
*/


//initialize the crack controller
//LEDR[9:6] indicate which core in the controller get correct answer. Not valid for more than 16 core
//LEDR[1] indicate whether the crack process finished.
//LEDR[0] indicate whether the crack process get correct result
//KEY[0] is reset (Only for debug usage)
rc4_crack_controller #(.CORE(CORE), .CORE_LEN(CORE_LEN), .ROM_FILE(ROM_FILE)) cracker (
    .clk(CLOCK_50),
    .crack_core_id(LEDR[9:6]),
    .secret_key(secret_key),
    .finish(LEDR[1]),
    .reset(~KEY[0]),
    .valid(LEDR[0]));


//display hex output
SevenSegmentDisplayDecoder hex0_conv(.nIn(secret_key[3:0]), .ssOut(HEX0));
SevenSegmentDisplayDecoder hex1_conv(.nIn(secret_key[7:4]), .ssOut(HEX1));
SevenSegmentDisplayDecoder hex2_conv(.nIn(secret_key[11:8]), .ssOut(HEX2));
SevenSegmentDisplayDecoder hex3_conv(.nIn(secret_key[15:12]), .ssOut(HEX3));
SevenSegmentDisplayDecoder hex4_conv(.nIn(secret_key[19:16]), .ssOut(HEX4));
SevenSegmentDisplayDecoder hex5_conv(.nIn(secret_key[23:20]), .ssOut(HEX5));

endmodule
