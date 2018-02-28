/* Add testing bench
 *
 * Author: Aleksandr Novozhilov
 * Date: 2018-02-09
 */


`define TEST_MESSAGE(condition, name) $display("Test \"%s\": %s", name, (condition? "ok" : "failed"));


module add_tb();

        reg clock, reset, input_rdy, output_rdy;

        reg [31:0] left, right;

        wire [31:0] result;

        reg [3:0] command;

        wire input_ack;
        reg output_ack;

        fpu DUT (
                .command(command),
                .clock(clock),
                .reset(reset),
                .data_a(left),
                .data_b(right),
                .output_rdy(output_rdy),
                .output_ack(output_ack),
                .input_rdy(input_rdy),
                .input_ack(input_ack),
                .result(result));

        
        initial begin
                left = 32'b0_01111111_00000000000000000000000;
                right= 32'b0_01111000_01000111101011100001010;
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                while(!output_rdy) begin
                        #1; 
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE((result == 32'b0_01111111_00000010100011110101110), "summ 1")
                                #1;
                                output_ack <= 1;
                                //$finish;
                        end
                end
        //end

        
        //initial begin
                left = 32'b0_10000011_10100000000000000000000;
                right= 32'b0_10000011_11010000000000000000000;
                reset = 1'b1;
                //input_rdy = 1;
                clock = 0;
                #5;
                reset = 0;
                clock = ~clock;
                #5;
                while(!output_rdy) begin
                        #1; 
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE((result == 32'b0_10000100_10111000000000000000000), "summ 2 with normolize")
                                #1;
                                output_ack <= 1;
                                //$finish;
                        end
                end
                //$display("Output ready: %d", output_rdy);
        end
        

        initial begin
                #100 $finish;
        end

endmodule
