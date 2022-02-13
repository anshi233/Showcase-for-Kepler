module ReadFlash_tb;

logic flash_mem_waitrequest, flash_mem_read, flash_mem_readdatavalid, flash_mem_write, RST, clk;
logic [31:0]  flash_mem_readdata, flash_mem_writedata, DATA;
logic  [22:0]  flash_mem_address, MEM_ADDR;
logic [6:0] flash_mem_burstcount;
logic [3:0] flash_mem_byteenable;
logic busy=0;
logic error=0;
logic read=0;

logic toggle_busy=0;

logic [3:0] task_number=0;

ReadFlashController test(clk,
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


//task to wait one cycle of clk
task wait_one_cycle();
    #2;
endtask
//test the flash emulator to make sure it can work correctly
task test_flash_emulator();
//give a MEM_ADDR and READ=1
    flash_mem_address=23'hA;
    flash_mem_read=1;
    //To perform a complete read, the controller use minimal cycles of
    //IDLE + SEND_READ_REQUEST_0 + SEND_READ_REQUEST_1 + WAIT_VALID_READ_0 + VALID_READ_SAVE = 5 cycles
    //wait five cycles
    wait_one_cycle();
    flash_mem_read=0;
    wait_one_cycle();    
    wait_one_cycle();
    #1;
    //detect whether correct data recieved from the emulator
    if((flash_mem_readdata=={9'b0,flash_mem_address}) && flash_mem_readdatavalid) begin
        $display("TEST_FLASH_EMULATOR OK");
    end
    else $display("TEST_FLASH_EMULATOR FAILLED!!!");
    #1; //use to make the task finished at full cycle timing than half cycle

    //$stop;
endtask


task test_one_read();
    //give a MEM_ADDR and READ=1
    MEM_ADDR=23'hA;
    read=1;
    //To perform a complete read, the controller use minimal cycles of
    //IDLE + SEND_READ_REQUEST_0 + SEND_READ_REQUEST_1 + WAIT_VALID_READ_0 + VALID_READ_SAVE = 5 cycles
    //wait five cycles
    wait_one_cycle();
    read=0;
    wait_one_cycle();    
    wait_one_cycle();
    wait_one_cycle();
    wait_one_cycle();
    wait_one_cycle();
    #1;
    //test the data read from flash emulator
    if(DATA=={9'b0,MEM_ADDR}) begin
        $display("TEST_ONE_READ DATA OK!");
    end
    else $display("TEST_ONE_READ DATA FAILED!");
    #10;
    //test whether the controller can back to default state and wait for next test
    if(test.state_code==8'b0000_0000) begin
        $display("TEST_ONE_READ RETURN TO IDLE STAGE OK!");
    end
    else $display("TEST_ONE_READ RETURN TO IDLE STAGE FAILED!");

    //$stop;
    



endtask

task test_busy_read();
//simulate flash waitresponse by setting toggle_busy to 1

//give a MEM_ADDR and READ=1
    MEM_ADDR=23'hA;
    read=1;
    toggle_busy=1;
    //To perform a complete read, the controller use minimal cycles of
    //IDLE + SEND_READ_REQUEST_0 + SEND_READ_REQUEST_1 + WAIT_VALID_READ_0 + VALID_READ_SAVE = 5 cycles
    //wait five cycles
    wait_one_cycle();
    read=0;

    //wait extra 8 cycles to emulate busy flash
    wait_one_cycle();    
    wait_one_cycle();
    wait_one_cycle();
    wait_one_cycle();
    wait_one_cycle();    
    wait_one_cycle();
    wait_one_cycle();
    wait_one_cycle();

    //continue the FSM
    toggle_busy=0;
    wait_one_cycle();    
    wait_one_cycle();
    wait_one_cycle();
    wait_one_cycle();
    wait_one_cycle();
    #1;
     //test the data read from flash emulator
    if(DATA=={9'b0,MEM_ADDR}) begin
        $display("TEST_BUSY_READ OK!");
    end
    else $display("TEST_BUSY_READ FAILED!");
    #1;
    //$stop;
endtask


initial begin
    clk = 1;
    forever begin
        #1
        clk = 0;
        #1
        clk = 1;
    end
end


initial begin
    test_flash_emulator();
    test_one_read();
    test_busy_read();
    $stop;
end


endmodule

//a very simple flash emulator, only emulate wavform response of read
module flash_emulator(clk, addr, read, readdata, read_data_valid, flash_mem_waitrequest, toggle_busy);
    input logic clk, read, toggle_busy;
    input logic [22:0] addr;
    output logic [31:0] readdata=32'h0;
    output logic read_data_valid=0;
    output wire flash_mem_waitrequest;
    logic [3:0] state=4'd0;

    assign flash_mem_waitrequest = toggle_busy;

    always_ff @(posedge clk) begin
        case(state) 
        4'd0: begin
            if (read && !toggle_busy) begin
                state <= 4'd3;
            end 
        end
        //4'd1: state <= 4'd3;
        //4'd2: state <= 4'd3;
        4'd3: begin
            if(!toggle_busy) begin
                readdata <= {9'b0,addr};
                read_data_valid <=1;
                state <= 4'd4;
            end
        end 
        4'd4: begin
            readdata <= 32'h0;
            read_data_valid <=0;
            state <= 4'd0;
        end
        default: state <= 4'd0;
        endcase
    end

endmodule