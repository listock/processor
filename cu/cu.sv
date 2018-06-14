/** TPU control unit
 *
 * This module representes control unit.
 *
 * Author: Aleksandr Novozhilov
 * Creating date: 2018-06-14
 *
 */

`include "../common/macro.sv"

module cu
        #(
                /** Bitness of single floating number. */
                parameter BITNESS      = 32,
                /** How many numbers can be processed in parallel. */
                parameter DATA_THREADS = 2
        )
(
        input clock,
        input reset
);

endmodule