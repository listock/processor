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
                left = 32'b10111111001111111111111111111111;
                right= 32'b10111111001111111111111111111111;
                //`TEST_MESSAGE(result === left, "summ 1")
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                while(1) begin
                        #1; 
                        clock = ~clock;                        
                        $display("Done? %b", output_rdy);
                        if (output_rdy && input_ack) begin
                                
                                $display("   Done! %b %b %b %b", output_rdy, clock, reset, result);
                                #1;
                                output_ack <= 1;
                                $finish;
                        end
                        $display("------");
                end
        end

        initial begin
                #50 $finish;
        end

endmodule
