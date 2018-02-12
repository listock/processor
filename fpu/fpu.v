/*
 * Floating point processing unit.
 *
 * Author: Aleksandr Novozhilov
 * Creating date: 2018-02-12
 *
 */


module fpu
        #(bitness=64)
(
        input wire[bitness:0] first,
        input wire[bitness:0] second,
        input wire[bitness:0] z,

        output wire[bitness:0] result,
        output wire[bitness:0] z
        // TODO: need to add command input (add, subsr, mul, div)
)

        reg first_sign, second_sign;

        // Numbers unpacking
        // ...goes here


endmodule
