/* Floating point unpacking module.
 *
 * Author: Aleksandr Novozhilov <alex.newlifer@gmail.com>
 *
 * Creating date: 2018-02-12
 *
 */ 

`define EXP_BINTESS(bintess) bitness == 256? 19: (bitness == 128?: 15: (bitness == 64? 11: (bitness == 32? 8: 5)))
`define MANT_BITNESS(bitness) bitness == 256? 237: (bitness == 128?: 113: (bitness == 64? 53: (bitness == 32? 24: 11)))

module unpack
        #(parameter bitness=64)
(
        input wire[bitness:0] number,

        output wire                           sign,
        output wire[EXP_BINTESS(bitness):0]   exp,
        output wire[MANT_BITNESS(bitness):0]  mant
)

endmodule
