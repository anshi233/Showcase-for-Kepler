module MusicPlayer_tb ;

//Read Controller IO
logic flash_mem_waitrequest, flash_mem_read, flash_mem_readdatavalid, flash_mem_write, RST, clk;
logic [31:0]  flash_mem_readdata, flash_mem_writedata, DATA;
logic  [22:0]  flash_mem_address, MEM_ADDR;
logic [6:0] flash_mem_burstcount;
logic [3:0] flash_mem_byteenable;
logic busy;
logic error;
logic read;

//Flash emulator IO
logic toggle_busy=0;

//MusicPlayer IO

logic CLK_50M, CLK_22K, Direction=1, Rst=0, Pause=0, Busy, Error;
logic [22:0] InitialAddress=23'h0;
//logic [31:0] DATA;

logic Terminate, Read;
logic [15:0] AudioData;
//logic [22:0] MEM_ADDR;

//connect some same signal wires
assign CLK_50M = clk;
assign read = Read;
assign Busy = busy;
assign Error = error;

//module used
ReadFlashController ReadFlashController1(clk,
    flash_mem_write,
    flash_mem_burstcount,
    flash_mem_waitrequest,
    flash_mem_read,
    flash_mem_address,
    flash_mem_writedata,
    flash_mem_readdata,
    flash_mem_readdatavalid,
    flash_mem_byteenable,
    MEM_ADDR,
    DATA,
    RST,
    read,
    busy,
    error
);

flash_emulator emulator(clk, flash_mem_address, flash_mem_read, flash_mem_readdata, flash_mem_readdatavalid, flash_mem_waitrequest, toggle_busy);

MusicPlayer MusicPlayer1(
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


//emulate CLK signal
//50M
initial begin
    clk = 1;
    forever begin
        #1;
        clk = 0;
        #1;
        clk = 1;
    end
end
//44K
initial begin
    CLK_22K = 1;
    forever begin
        #20;
        CLK_22K = 0;
        #20;
        CLK_22K = 1;
    end
end


//test task
//this tset aim to see whether the music player can continuously increament flash address and play audio data
//focus on waveform only
task normalrun();
    #1000; //test 500 cycles time
    $stop;

endtask





//main
initial begin
    //task 1
    normalrun();
end




endmodule