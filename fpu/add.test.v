/* Add testing bench
 *
 * Author: Aleksandr Novozhilov
 * Date: 2018-02-09
 */


`define TEST_MESSAGE(condition, name) $display("Test \"%s\": %s", name, (condition? "ok" : "failed"));


module add_tb();

        reg clock, reset;

        reg [31:0] left, right;

        wire [31:0] result;
        wire work_is_done;

        reg [3:0] command;

        fpu DUT (
                .command(command),
                .clock(clock),
                .reset(reset),
                .first(left),
                .second(right),
                .work_is_done(work_is_done),
                .result(result));

        initial begin
                left = 32'b10111111001111111111111111111111;
                right= 32'b10111111001111111111111111111111;
                //`TEST_MESSAGE(result === left, "summ 1")
                reset = 1'b1;
                clock = 1'b0;
                //reset = 1'b0;
                #5;
                //reset <= 1'b0;
                //#5;
                while(1) begin
                        clock = ~clock;
                        #1;
                        reset = 1'b0;
                        #1;
                        $display("Done? %b", work_is_done);
                        if (work_is_done == 1'b1 && clock == 1'b1) begin
                                $display("Done! %b %b %b %b", work_is_done, clock, reset, result);
                        end
                end
        end

        initial begin
                #30 $finish;
        end

endmodule
