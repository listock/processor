/*
 * Floating point processing unit.
 *
 * Author: Aleksandr Novozhilov
 * Creating date: 2018-02-12
 *
 */

`define COMMAND_SIZE 1

`define EXP_BINTESS(bintess) bitness == 256? 19: (bitness == 128?: 15: (bitness == 64? 11: (bitness == 32? 8: 5)))
`define MANT_BITNESS(bitness) bitness == 256? 237: (bitness == 128?: 113: (bitness == 64? 53: (bitness == 32? 24: 11)))

module fpu
        #(bitness=64)
(
        input wire[bitness:0] first,
        input wire[bitness:0] second,
        input wire[bitness:0] z,

        input wire[COMMAND_SIZE:0] command,

        output wire[bitness:0] result,
        output wire[bitness:0] z
)

        reg first_sign, second_sign;

        // Numbers unpacking
        reg                          first_sign, second_sig;,
        reg[EXP_BINTESS(bitness):0]  first_exp,  second_exp;
        reg[MANT_BITNESS(bitness):0] fist_mnt,   second_mnt;


endmodule
