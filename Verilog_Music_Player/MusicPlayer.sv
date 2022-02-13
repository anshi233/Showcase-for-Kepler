module MusicPlayer(
    //IO
    CLK_50M,
    CLK_22K,
    InitialAddress,
    AudioData,
    Direction,
    Rst,
    Pause,
    Terminate,
    //ReadController part IO
    MEM_ADDR,
    DATA,
    Read,
    Error,
    Busy
);

input CLK_50M, CLK_22K, InitialAddress, Direction, Rst, Pause, Busy, DATA, Error;
output AudioData, Terminate, MEM_ADDR, Read;

parameter Idle = 8'b0000_0000;
parameter Wait22KNegedge = 8'b0001_0000;
parameter SendFlashReadAddr = 8'b0011_0000;
parameter WaitSaveFlashRead1 = 8'b0011_0001;
parameter WaitSaveFlashRead2 = 8'b0011_0010;
parameter Wait22KPosedge = 8'b0010_0000;
parameter Wait22KNegedge2 = 8'b0010_0001;
parameter CheckCalculateNextAddr = 8'b0100_0001;

//external signal declear

wire CLK_50M, CLK_22K, Direction, Rst, Pause, Busy, Error;
wire [22:0] InitialAddress;
wire [31:0] DATA;

logic Terminate, Read;
logic [7:0] AudioData;
logic [22:0] MEM_ADDR;


//internal signal declare
logic [7:0] state = 8'b0000_0000;
logic [22:0] CurrentAddress = 23'b0;
logic [31:0] TempData = 32'b0;
logic [7:0] DataCounter=8'b0;
//speedup/down placeholder


always_ff @( posedge CLK_50M or posedge Rst ) begin 
    //if reset signal is received, reset the fsm
    if(Rst) begin
        //reset all registers to default value
        state <= Idle;
        Terminate <= 1'b1;
        Read <= 1'b0;
        DataCounter <= 8'b0;
        CurrentAddress <= 23'b0;
    end
    else begin
        case(state)
        //IDLE stage
            Idle: begin
                //if music is not at pause status, start playing
                if(!Pause) begin
                    state <= Wait22KNegedge;
                    CurrentAddress <= InitialAddress;
                    Terminate <= 0; //indicate audio is playing
                end
                //else remain at same stage
            end
            //make sure CLK_22K is low which is best time to read new data for next few cycle's music data
            Wait22KNegedge: begin
                //if not pause and  CLK_22K is low
                if(!Pause && (!CLK_22K)) begin
                    //start read data stage
                    state <= SendFlashReadAddr;
                end
                //else remain at same stage
            end
            SendFlashReadAddr: begin
                //if flash read controller is not in busy status
                if(!Busy) begin
                    //load new mem address
                    MEM_ADDR <= CurrentAddress;
                    //set read to 1 to inform the flash read controller start reading
                    Read <= 1;
                    state <= WaitSaveFlashRead1;
                end
            end
            WaitSaveFlashRead1: begin
                //This stage is to wait for controller to mask busy to 1 So one more extra stage waited
                Read<=0; //set to 0 to allow readcontoller keep running
                state <= WaitSaveFlashRead2;
                
                
            end

            WaitSaveFlashRead2: begin
                //wait for read controller to finish reading
                //if finished, signal "busy" should be set to 0
                if(!Busy) begin
                    //save read music data
                    TempData <= DATA;
                    state <= Wait22KPosedge;
                end
            end

            Wait22KPosedge: begin
                if(CLK_22K) begin
                    //wait for high of clk_22k
                    //save flash read content accoriding to DataCounter
                    //Datacounter indicate that which part of data should be read into AudioData
                    case(DataCounter) 
                        8'd0: AudioData <= TempData[7:0];
                        8'd1: AudioData <= TempData[15:8];
                        8'd2: AudioData <= TempData[23:16];
                        8'd3: AudioData <= TempData[31:24];
                        default: ;//do nothing
                    endcase
                    state <= Wait22KNegedge2;
                end
                //else stage at same stage until posedge of clk_22k
                
            end
            Wait22KNegedge2: begin
                //wait for low of CLK_22K
                if(!CLK_22K) begin
                    //at low of CLK_22K, calculate new data position sequence counter value
                    
                    if(DataCounter<3)begin //3 because unblocking assignment as a delay of 1 cycle, so 3 = 4-1 cycles
                        DataCounter <= DataCounter + 8'd1; //takes effect at next times reach this stage
                        state <= Wait22KPosedge;
                    end
                    else begin
                        //finish write all music data
                        //reset data position counter
                        DataCounter <= 8'd0;
                        state <= CheckCalculateNextAddr;
                    end
                end
            end
            CheckCalculateNextAddr: begin
                //Fist thing to do is checkh whether the mem address reach end
                //forward is 0x7FFFF
                //backward is 0x00000;
                //if play forward reach end of music
                if( (Direction == 1) && (CurrentAddress == 23'h7FFFF) ) begin
                    //back to IDLE and mask Terminate to 1
                    Terminate <= 1;
                    state <= Idle;
                end
                else begin 
                    //if play backward reach end of music
                    if((Direction == 0) && (CurrentAddress == 23'h0)) begin
                        //back to IDLE and mask Terminate to 1
                        Terminate <= 1;
                        state <= Idle;
                    end
                    else begin
                        // calculate next addr according to direction then go to 
                        //Wait_22K_negedge stage to read and play next audio data
                        if(Direction) begin
                            //forward so +1
                            CurrentAddress <= CurrentAddress + 23'b1;
                            state <= Wait22KNegedge;
                        end
                        else begin
                            //backward so -1
                            CurrentAddress <= CurrentAddress - 23'b1;
                            state <= Wait22KNegedge;
                        end
                    end
                end

            end
            default: begin 
                state <= Idle;
                Terminate <= 1;
            end
        endcase
    end

end

endmodule