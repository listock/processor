/* Add testing bench
 *
 * Author: Aleksandr Novozhilov
 * Date: 2018-02-09
 */


`define TEST_MESSAGE(condition, name) $display("Test \"%s\": %s", name, (condition? "ok" : "failed"));


module add_tb();

        reg clock, reset;

        reg [31:0] left, right, z_in, z_out;

        wire [31:0] result;

        reg [1:0] command;

        fpu DUT (
                .command(command),
                .clock(clock),
                .reset(reset),
                .first(left),
                .second(right),
                .z_in(z_in),
                .z_out(z_out),
                .result(result));

        initial begin
                left = 32'b10111111001111111111111111111111;
                right= 32'b10111111001111111111111111111111;
                //`TEST_MESSAGE(result === left, "summ 1")
                #5
                reset <= 1'b1;
                while(1) begin
                        #5 clock <= ~clock;
                        reset <= 1'b0;
                        $display("%b %b %b", clock, reset, result);
                end
        end

        initial begin
                #50 $finish;
        end

endmodule
