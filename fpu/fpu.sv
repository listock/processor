/*
 * Floating point processing unit.
 *
 * Author: Aleksandr Novozhilov
 * Creating date: 2018-02-12
 *
 */

`define COMMAND_SIZE 1

`define EXP_BINTESS(bintess) bitness == 256? 19: bitness == 128? 15: bitness == 64? 11: bitness == 32? 8: 5
`define MANT_BITNESS(bitness) bitness == 256? 237: bitness == 128? 113: bitness == 64? 53: bitness == 32? 24: 11

module fpu
        #(parameter bitness=64, command_size=2)
(
        input wire[bitness:0] first,
        input wire[bitness:0] second,
        input wire[bitness:0] z_in,

        input wire[command_size:0] command,

        output wire[bitness:0] result,
        output wire[bitness:0] z_out

);
        enum reg[3:0] {unpack    = 4'b0000,
                       pack      = 4'b0001,
                       align     = 4'b0010,
                       normalize = 4'b0011,
                       sum       = 4'b0100,
                       sub       = 4'b0101,
                       mul       = 4'b0110,
                       div       = 4'b1000} state;


        reg first_sign;
        reg second_sign;

        reg[`EXP_BINTESS(bitness):0] first_exp;
        reg[`EXP_BINTESS(bitness):0] second_exp;

        reg[`MANT_BITNESS(bitness):0] first_mantissa;
        reg[`MANT_BITNESS(bitness):0] second_mantissa;

endmodule
