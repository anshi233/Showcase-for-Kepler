`default_nettype none
module rc4_crack_core
#(
    ROM_FILE="../secret_messages/msg_1_for_task2b/message.mif" //default rom file
)
(
     clk,
     reset,
     secret_key_raw,
     finish,
     valid
);
input clk, reset, secret_key_raw;
output finish, valid;
logic clk, reset, finish;
reg valid=0;
logic [23:0] secret_key_raw;
logic [7:0] secret_key;
logic [7:0] secret_key_sel;
parameter key_length = 8'd3;
parameter message_length = 8'd32;

//working memory S
logic [7:0] address, data, q;
logic wren;
logic [7:0] q_temp;

//Decryped Message RAM 
logic [7:0] address_d, data_d, q_d;
logic wren_d;
//Encryped Message ROM
logic [7:0] address_m, q_m;

//FSM state

parameter idle = 12'b000_0000_00100;
//loop one initialize array
parameter loop1_init = 12'b001_0000_00000;
parameter loop1_write_mem = 12'b001_0001_00001;
parameter loop1_wait_mem = 12'b001_0010_00000;
parameter loop1_next_value = 12'b001_0011_00000;

//loop two 
parameter loop2_init = 12'b010_0000_00000;
parameter loop2_read_mem_i = 12'b010_0001_00000;
parameter loop2_wait_mem_i = 12'b010_0010_00000;
parameter loop2_save_mem_i_get_j = 12'b010_0011_00000;
parameter loop2_read_mem_j = 12'b010_0100_00000;
parameter loop2_wait_mem_j = 12'b010_0101_00000;
parameter loop2_save_mem_j = 12'b010_0110_00000;
parameter loop2_swap_mem_i = 12'b010_0111_00001;
parameter loop2_swap_mem_j = 12'b010_1000_00001;
parameter loop2_next_value = 12'b010_1001_00000;

//loop three
parameter loop3_init = 12'b011_0000_00000;
parameter loop3_inc_i = 12'b011_0001_00000;
parameter loop3_read_mem_i = 12'b011_0010_00000;
parameter loop3_wait_mem_i = 12'b011_0011_00000;
parameter loop3_save_mem_i = 12'b011_0100_00000;
parameter loop3_read_mem_j = 12'b011_0101_00000;
parameter loop3_wait_mem_j = 12'b011_0110_00000;
parameter loop3_save_mem_j = 12'b011_0111_00000;
parameter loop3_swap_mem_i = 12'b011_1000_00001;
parameter loop3_swap_mem_j = 12'b011_1001_00001;
parameter loop3_swap_wait_mem_j = 12'b011_1010_00000;
parameter loop3_read_mem_f_and_enc_m = 12'b011_1011_00000;
parameter loop3_wait_mem_f_and_enc_m = 12'b011_1100_00000;
parameter loop3_save_mem_f_and_enc_m = 12'b011_1101_00000;
parameter loop3_write_dec_m = 12'b011_1110_00010;
parameter loop3_next_k_val = 12'b011_1111_00000;


logic [11:0] state=loop1_init;
logic [7:0] counter_i=0, counter_j=0, counter_k=0, f_temp=0;




//s memory instance
s_memory s_mem_instance (
	.address(address),
	.clock(~clk),
	.data(data),
	.wren(wren),
	.q(q));

//decrupted message (result) memory instance
decrypted_message_ram decrypted_message_ram_instance (
	.address(address_d),
	.clock(~clk),
	.data(data_d),
	.wren(wren_d),
	.q(q_d));


//encrypted message rom instance t2b1 = task 2b message 1 (not important) 
t2b1_rom encryped_rom_instance (
    .address(address_m),
	.clock(~clk),
	.q(q_m)
);
defparam encryped_rom_instance.ROM_FILE = ROM_FILE; //edit the rom file path of the module.


always_comb begin
    //FSM operation combinational logic
    //memory write part
    wren=state[0];
    wren_d=state[1];
    //finish signal
    finish=state[2];
    //multiplexier to select correct part of secret key
    secret_key_sel = counter_i % key_length;
    case(secret_key_sel)
        0: secret_key=secret_key_raw[23:16];
        1: secret_key=secret_key_raw[15:8];
        2: secret_key=secret_key_raw[7:0];
        default:begin
            secret_key=8'bz;//do nothing
        end
    endcase
end



always_ff @(posedge clk or posedge reset) begin

    if(reset) begin
        state<=loop1_init;
        counter_i<=0;
        counter_j<=0;
        counter_k<=0;

        //reset S mem related reg
        address<=0;
        data<=0;

        //reset other reg
        address_d<=0;
        data_d<=0;
        address_m<=0;
        q_temp<=0;
        f_temp<=0;
        valid<=0;

    end
    else begin

        case(state) 
            //fsm with logic
            /*
            //idle state do nothing
            //only way to rerun the fsm is reset it
            */
            idle:begin
                state <= idle;
            end


/*======================================loop1 start======================================//
            for i=0, i<255, i++
            s[i]=i;
            */
            loop1_init:begin
                counter_i<=0;
                address<=0;
                data<=0;
                state <= loop1_write_mem;
            end

            loop1_write_mem:begin
                state <= loop1_wait_mem;
            end

            loop1_wait_mem: begin
                state <= loop1_next_value;
            end

            loop1_next_value:begin
                if(counter_i < 255)begin
                    counter_i <= counter_i + 1;
                    address <= counter_i + 1;
                    data <= counter_i + 1;
                    state <= loop1_write_mem;
                end
                else begin
                    state <= loop2_init; //go to loop2
                end
            end
//============================loop1 end=================================================//
            
            //loop 2 start
            /*
            // shuffle the array based on the secret key. You will build this in Task 2
            j = 0
            for i = 0 to 255 {
                j = (j + s[i] + secret_key[i mod keylength] ) //keylength is 3 in our impl.
                swap values of s[i] and s[j]
            }
            */
            loop2_init:begin
                //reset counter and mem control registers for loop2
                counter_i <= 0;
                counter_j <= 0;
                data <= 0;
                address <= 0;
                state <= loop2_read_mem_i;
            end
            loop2_read_mem_i:begin
                state <= loop2_wait_mem_i;
            end
            loop2_wait_mem_i:begin
                state <= loop2_save_mem_i_get_j;
            end
            loop2_save_mem_i_get_j:begin
                //q = s[i]
                //get j here
                // j = (j + s[i] + secret_key[i mod keylength] )
                counter_j <= counter_j + q + secret_key;
                //address of s[j]
                address <= counter_j + q + secret_key;
                //cache q (s[i]) output for future use
                q_temp <= q;

                state <= loop2_read_mem_j;
            end
            loop2_read_mem_j: begin
                //get s[j]
                state <= loop2_wait_mem_j;
            end
            loop2_wait_mem_j:begin   
                state <= loop2_save_mem_j;
            end

            loop2_save_mem_j:begin
                //now q=s[j]
                //write s[j] into s[i] in next state
                data<=q;
                address<=counter_i;
                state<=loop2_swap_mem_i;
            end

            loop2_swap_mem_i:begin //swap = write
                //write s[i] (q_temp) into s[j] in next state
                data<=q_temp;
                address<=counter_j;
                state<=loop2_swap_mem_j;
            end
            loop2_swap_mem_j:begin
                //writing s[j]
                state <= loop2_next_value;
            end
            loop2_next_value:begin
                if(counter_i < 255) begin
                    counter_i <= counter_i + 1; //i++
                    address <= counter_i + 1; // read s[i] in loop new round
                    state <= loop2_read_mem_i;
                end
                else begin
                    //go to loop3
                    state <= loop3_init;
                end
            end
//==========================================loop 3 start====================================//
            /*
            i = 0, j=0
            for k = 0 to message_length-1 { // message_length is 32 in our implementation
                i = i+1
                j = j+s[i]
                swap values of s[i] and s[j]
                f = s[ (s[i]+s[j]) ]
                decrypted_output[k] = f xor encrypted_input[k] // 8 bit wide XOR function
            }
            */
            loop3_init:begin

                counter_i<=0;   //i = 0
                counter_j<=0;   //j = 0
                counter_k<=0;   //k = 0
                //s[0]
                address<=0;
                data<=0;
                //encrypted_input[]
                address_m<=0;   //encrypted_input[k] and k=0
                //decrypted_output[]
                address_d<=0;   //just init to 0
                f_temp<=0;
                state<=loop3_inc_i; //start loop 3 logic
            end
            loop3_inc_i:begin
                counter_i <= counter_i + 1;
                address <= counter_i + 1; //s[i]
                state <= loop3_read_mem_i;
            end
            loop3_read_mem_i:begin
                state<=loop3_wait_mem_i;
            end
            loop3_wait_mem_i:begin
                state <= loop3_save_mem_i;
            end
            loop3_save_mem_i:begin
                counter_j <= counter_j + q; //j=j+s[i]
                address <= counter_j + q; //read s[j]
                q_temp <= q;    //save a backup of s[i] 
                state <= loop3_read_mem_j;
            end
            loop3_read_mem_j:begin
                state<=loop3_wait_mem_j;
            end
            loop3_wait_mem_j:begin
                state <= loop3_save_mem_j;
            end
            loop3_save_mem_j:begin
                q_temp <= q;  //now q_temp save backup of s[j]
                f_temp <= q_temp + q; //f_temp is now save address of f[s[i]+s[j]]

                data <= q_temp; //next write data s[i] into s[j]
                address <= counter_j; //s[j]

                state<=loop3_swap_mem_i;
            end

            loop3_swap_mem_i:begin
                data <= q_temp; //now write backup data s[j] into s[i]
                address <= counter_i;   //address of s[i]
                state <= loop3_swap_mem_j;
            end
            loop3_swap_mem_j:begin
                state <= loop3_swap_wait_mem_j;
            end
           loop3_swap_wait_mem_j:begin
               //finish swap s[i] and s[j]
                //prepare for read of s[f]
                address <= f_temp;
                data <= 0;

                //prepare for read of encrypted_input[k]
                address_m <= counter_k;
    
                state <= loop3_read_mem_f_and_enc_m;

           end
           loop3_read_mem_f_and_enc_m:begin
               state<=loop3_wait_mem_f_and_enc_m;
           end
           loop3_wait_mem_f_and_enc_m:begin
               state<=loop3_save_mem_f_and_enc_m;
           end
           loop3_save_mem_f_and_enc_m:begin
               //q = f
               //q_m = encrypted_input[k]
               //data_d = f xor(^) encrypted_input[k]
               data_d <= q ^ q_m;  
               address_d <= counter_k;  //address of decrypted_output[k]
                
               state <= loop3_write_dec_m;
           end
            loop3_write_dec_m:begin
                //check whether the result is a valid ASCII lowever case char or space (32)
                if( ((data_d < 8'd123) & (data_d > 8'd96)) | (data_d == 8'h20) ) begin
                    state<=loop3_next_k_val; //data is valid, check pass
                end
                else begin
                    //here the output data is invalid, just stop decryption because 
                    //the key is not correct
                    valid <= 0; //result is invalid due to incorrect key
                    state <= idle;
                end


                
            end

            loop3_next_k_val:begin
                if(counter_k < (message_length-1) )begin
                    counter_k <= counter_k + 1;
                    state <= loop3_inc_i;
                end
                else begin
                    valid <= 1; //result is valid
                    state <= idle;
                end
            end

//========================================loop 3 end=======================================//


            default: state <= loop1_init;
        endcase
    end
end





endmodule