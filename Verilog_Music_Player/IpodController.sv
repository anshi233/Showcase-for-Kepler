module IpodController(
    clk,
    kbd_data_ready,
    kbd_code,
    InitialAddress,
    Rst,
    Direction,
    Pause
);

input clk, kbd_data_ready;
input [7:0] kbd_code;
//input SW;
output Rst, Direction, Pause, InitialAddress;
wire clk, kbd_data_ready;
wire kbd_data_ready_synced;
wire [7:0] kbd_code;
reg Rst=1'b0, Direction=1'b1, Pause=1'b1;
reg [22:0] InitialAddress=23'h0;



parameter WaitKeyData = 8'b0000_0000;
parameter ConvKey = 8'b0000_0001;
parameter RstKeyData1 = 8'b1000_0001;
parameter CommandReset= 8'b0001_0000;
parameter CommandResetFinish= 8'b0001_0001;
parameter CommandPause= 8'b0010_0000;
parameter CommandContinue= 8'b0010_0001;
parameter CommandBackward=8'b0011_0000;
parameter CommandForward=8'b0011_0001;

reg [7:0] state = WaitKeyData;

//synchronize the different timedomain kbd_data_ready signal for stability
doublesync kbd_data_ready_doublsync
(.indata(kbd_data_ready),
.outdata(kbd_data_ready_synced),
.clk(clk),
.reset(1'b1));


//Controller FSM begin
always_ff @( posedge clk ) begin 
    case (state)
        WaitKeyData:begin
            //if new keyboard data is ready, next stage
            if(kbd_data_ready_synced)begin
               state<=ConvKey;
            end
            //else stay at this stage
            
        end
        ConvKey:begin
            //multiplexer to select wanted operation from received keyboard data
            case(kbd_code)
                8'h2d: state <= CommandReset;  //R pressed
                8'h23: state <= CommandPause;  //D
                8'h24: state <= CommandContinue;  //E
                8'h32: state <= CommandBackward;  //B
                8'h2b: state <= CommandForward;  //F
                default: state <= RstKeyData1; //no match then do nothing by skip all operation
            endcase
        end
        //perform reset 
        CommandReset:begin
            Rst<=1'b1;
            state<=CommandResetFinish;
        end
        //mask reset back to 0
        CommandResetFinish:begin
            Rst<=1'b0;
            
            state<=RstKeyData1;
        end
        //Pause the music
        CommandPause:begin
            Pause<=1'b1;
            state<=RstKeyData1;
        end
        //Continue the music
        CommandContinue:begin
            Pause<=1'b0;
            state<=RstKeyData1;
            
        end
        //set music direction to backward
        CommandBackward:begin
            Direction<=1'b0; //change direction to backward
            InitialAddress<=23'h7FFFF; //set initial mem addr of music to end of music data
            state<=RstKeyData1;
        end
        //set music direction to forward (default)
        CommandForward:begin
            Direction<=1'b1; //change direction to forward
            InitialAddress<=23'h0; //set initial mem addr of music to start of music data
            state<=RstKeyData1;
        end

        RstKeyData1:begin
            //wait for kbd_data_ready fall back to 0
            if(!kbd_data_ready_synced)begin
                //new cycle of FSM
                state<=WaitKeyData;
            end
        end



        default: state<=WaitKeyData;
    endcase
end
endmodule
