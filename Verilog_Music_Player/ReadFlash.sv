module ReadFlashController(clk,
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

//parameter
parameter IDLE = 8'b0000_0000;
parameter SEND_READ_REQUEST_0 = 8'b0001_0000;
parameter SEND_READ_REQUEST_1 = 8'b0001_0001;
parameter WAIT_VALID_READ_0 = 8'b0010_0000;
parameter VALID_READ_SAVE = 8'b0011_0000;
parameter WAIT_READ_0 = 8'b0100_0000;


//FLASH IO
output       flash_mem_read;
input      flash_mem_waitrequest, flash_mem_readdatavalid, clk;
output    [22:0]  flash_mem_address;
input    [31:0]  flash_mem_readdata;

//not use in this lab
//write related
input flash_mem_write;
input [6:0] flash_mem_burstcount;
input [31:0] flash_mem_writedata;
input [3:0] flash_mem_byteenable;

//Controller specific IO
input [22:0] MEM_ADDR;
input RST, read;
output busy;
output [31:0] DATA;
output error;

//declear type
logic flash_mem_waitrequest, flash_mem_read, flash_mem_readdatavalid, flash_mem_write, RST, clk, read;
wire [31:0]  flash_mem_readdata, flash_mem_writedata;
logic [31:0]  DATA=32'h0;
logic  [22:0]  flash_mem_address, MEM_ADDR;
logic [6:0] flash_mem_burstcount;
logic [3:0] flash_mem_byteenable;
logic [7:0] state_code=IDLE;
logic busy=0;
logic error=0;
logic [15:0] extra_wait_counter=0;



//FSM start

always_ff @(posedge clk or posedge RST ) begin 
    if(RST) begin 
        error <= 0;
        busy <= 0;
        flash_mem_read <= 0;
        extra_wait_counter <=0;
        state_code = IDLE; //if RST is high, reset this FSM
    end
    else begin
        //stage select
        case(state_code)
        //IDLE stage
        //FSM should stay at this stage when no new read input.
        IDLE:
        //if error signal is high, means something is wrong and debug is required
            if (!error) begin
                //if read is high, start read data from flash
                if(read) begin
                    state_code <= SEND_READ_REQUEST_0;
                    busy <= 1; // FSM is busy now
                end
                else begin
                    busy <= 0; //FSM say it is not busy at all
                end
            end
        //SEND_READ_REQUEST stage.
        //there are two stages
        //In stage 0, if waitrequest is high, wait!
        //if not, send FLASH READ_ADDR and go to next stage
        SEND_READ_REQUEST_0:
            if(!flash_mem_waitrequest) begin
                flash_mem_read <= 1;
                flash_mem_address <= MEM_ADDR;
                DATA <= 32'h0; //reset DATA resgister
                state_code <= SEND_READ_REQUEST_1;
            end
        //in stage 1, mask the flash_mem_read to 0 to avoid unwanted data is read
        //then move to WAIT_VALID_READ_0 stage unconditionally
        SEND_READ_REQUEST_1: begin
            flash_mem_read <= 0;
            state_code <= VALID_READ_SAVE;
        end
        //In VALID_READ_SAVE save the output of flash at flash_mem_readdata
        VALID_READ_SAVE: begin
            
            if (flash_mem_readdatavalid) begin
                DATA <= flash_mem_readdata; //save flash_mem_readdata permenatally
                
                state_code <= WAIT_READ_0;
            end
            else begin
                //if still not receive read data, max wait 200 cycles
                if (extra_wait_counter > 16'd200) begin
                    extra_wait_counter <= 0;
                    error <= 1; //the controller must be manually reset to run again since there is error in operating the FLash.
                    state_code <= IDLE;
                end
                else begin
                    //increament wait counter
                    extra_wait_counter <= extra_wait_counter + 1;
                end
            end
        end
        //Wait read signal to 0 to avoid burst if read
        WAIT_READ_0: begin
            if(!read) begin
                state_code <= IDLE;
                extra_wait_counter <=0;
                busy <= 0; //indicate not busy, so data read complete
            end
        end

        default: state_code <=IDLE;
        endcase
    end          
end
endmodule