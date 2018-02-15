/* Add testing bench
 *
 * Author: Aleksandr Novozhilov
 * Date: 2018-02-09
 */


`define TEST_MESSAGE(condition, name) $display("Test \"%s\": %s", name, (condition? "ok" : "failed"));


module add_tb();

        reg clock, reset;

        reg [31:0] left, right, z_in, z_out;

        reg [31:0] result;

        reg [1:0] command;
        reg done;

        fpu DUT (
                .command(command),
                .clock(clock),
                .reset(reset),
                .first(left),
                .second(right),
                .z_in(z_in),
                .z_out(z_out),
                .work_is_done(done),
                .result(result));

        initial begin
                left = 32'b10111111001111111111111111111111;
                right= 32'b10111111001111111111111111111111;
                //`TEST_MESSAGE(result === left, "summ 1")
                #5
                reset <= 1'b1;
                clock <= 1'b0;
                #5;
                while(1) begin
                        clock <= ~clock;
                        #1;
                        reset <= 1'b0;
                        if (done) begin
                                $display("Done! %b %b %b", clock, reset, result);
                        end
                end
        end

        initial begin
                #20 $finish;
        end

endmodule
