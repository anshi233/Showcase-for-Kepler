module rc4_crack_controller #(
    parameter CORE=1,
    parameter CORE_LEN=4,
    parameter ROM_FILE="../secret_messages/msg_1_for_task2b/message.mif"
) (
    clk,
    crack_core_id,
    secret_key,
    finish,
    reset,
    valid
);

input clk, reset;
output crack_core_id, secret_key, finish, valid;
wire clk, reset;

logic finish=0, valid;
logic [CORE_LEN-1:0] crack_core_id;
logic [23:0]secret_key, secret_key_temp=0;

logic [CORE_LEN-1:0] core_inst = 0;

//internal signal start
logic [CORE-1:0][23:0] try_secret_key_bus ;
logic [CORE-1:0] core_result_bus;
logic [CORE-1:0] core_finish_bus;
logic [CORE-1:0] core_reset_bus, core_reset_bus_temp;

logic [CORE-1:0] one;

parameter check_core_result = 8'b0000_0000;
parameter load_core_new_key = 8'b0001_0000;
parameter reset_core_and_start = 8'b0010_0001;

logic [7:0] state=check_core_result;



genvar i;

//start
integer k;
initial begin
    for (k=0;k<CORE;k++) begin
        try_secret_key_bus[k] = 0;
        core_reset_bus_temp[k] = 0;
        one[k] = 0;
        
    end
    for (k=0;k<CORE_LEN;k++) begin
        crack_core_id[k] = 0;
        
    end


end


//generate crack core
generate
    for (i=0;i<CORE;i++)begin : crack_core_generate
        rc4_crack_core rc4_crack_core_instance(
            .clk(clk),
            .reset(core_reset_bus[i]),
            .secret_key_raw(try_secret_key_bus[i]),
            .finish(core_finish_bus[i]),
            .valid(core_result_bus[i])
        );
        defparam rc4_crack_core_instance.ROM_FILE=ROM_FILE;
    end
endgenerate


always_comb begin
    //used to reset each core
    core_reset_bus = reset ? one : core_reset_bus_temp;
    valid = |core_result_bus;
    
end

always_ff @(posedge clk or posedge reset) begin
    
    if(reset)begin
        //initialize everything
        secret_key_temp<=0;
        core_inst<=0;
        finish <= 0;

        try_secret_key_bus <= 0;
        core_reset_bus_temp <= 0;
        crack_core_id <= 0;

        state <= check_core_result;
    end
    else begin
        if (!finish) begin
            case(state)
                check_core_result:begin
                        //check whether the core is in idle state
                        if(core_finish_bus[core_inst])begin
                            //core is finished, check result;
                            if(core_result_bus[core_inst])begin
                                //result is valid, save correct secret key and mask finish
                                finish <= 1;
                                crack_core_id <= core_inst;
                                secret_key <= try_secret_key_bus[core_inst];
                            end
                            else begin
                                //result is not valid
                                secret_key <= secret_key_temp;
                                state <= load_core_new_key;
                            end
                        end
                        else begin
                            //the core is still busy in calucate result
                            //check next core
                            //if not reach last core
                            if (core_inst < (CORE-1))begin
                                //core_inst++
                                core_inst <= core_inst + 1;
                            end
                            else begin
                                //reach last core
                                core_inst <= 0;
                            end
                        end
                end
                load_core_new_key:begin
                    //check and load core with new key
                    if(secret_key_temp == 24'hFFFFFF)begin
                        //reach end of key and still not found valid result
                        finish <= 1;
                        secret_key <= secret_key_temp;
                    end
                    else begin
                        try_secret_key_bus[core_inst] <= secret_key_temp; //load new key
                        secret_key_temp <= secret_key_temp + 1; //calculate new key
                        core_reset_bus_temp[core_inst] <= 1;
                        state <= reset_core_and_start;
                    end
                end
                reset_core_and_start:begin
                    //reset core == start the core
                    //core_inst++ to check next core
                    //if not reach last core
                    if (core_inst < (CORE-1))begin
                        //core_inst++
                        core_inst <= core_inst + 1;
                    end
                    else begin
                        //reach last core
                        core_inst <= 0;
                    end
                    core_reset_bus_temp[core_inst] <= 0;
                    state <= check_core_result;
                end
                default: state <= check_core_result;

            endcase
        end
    end

    //else the whole decrypted process is finished. do nothing.
end

endmodule

