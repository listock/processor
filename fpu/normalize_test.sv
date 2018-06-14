/* Add testing bench
 *
 * Author: Aleksandr Novozhilov
 * Date: 2018-05-15
 */

`include "normalize.sv"

module add_tb();

        logic clock;
        logic [1:0][4 - 1:0] numbers;

        normalize DUT (
                .clock(clock),
                .numbers(numbers));

        initial begin

            clock = 0;

            numbers[0] = 4'b0001;
            numbers[1] = 4'b0101;

            clock = ~clock;
            clock = ~clock;
            clock = ~clock;
            clock = ~clock;

            $display("%b %b", numbers[0], numbers[1]);

        end

        initial begin
                #50 $finish;
        end

endmodule
