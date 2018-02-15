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
        #(parameter bitness=32, command_size=2)
(
        input clock,
        input reset,

        input [bitness - 1:0] first,
        input [bitness - 1:0] second,
        input [bitness - 1:0] z_in,

        input [command_size - 1:0] command,

        output [bitness - 1:0] result,

        output work_is_done

);
        enum reg[3:0] { unpack    = 4'b0000
                      , pack      = 4'b0001
                      , align     = 4'b0010
                      , normalize = 4'b0011
                      , sum       = 4'b0100
                      , sub       = 4'b0101
                      , mul       = 4'b0110
                      , div       = 4'b1000
              } state;

        reg [bitness - 1:0] result_internal;
        reg work_is_done_internal;

        reg first_sign;
        reg second_sign;
        reg result_sign;

        reg[`EXP_BINTESS(bitness) - 1:0] first_exp;
        reg[`EXP_BINTESS(bitness) - 1:0] second_exp;
        reg[`EXP_BINTESS(bitness) - 1:0] result_exp;

        reg[`MANT_BITNESS(bitness) - 1:0] first_mantissa;
        reg[`MANT_BITNESS(bitness) - 1:0] second_mantissa;
        reg[`MANT_BITNESS(bitness) - 1:0] result_mantissa;


        always @(posedge clock, negedge reset) begin
                $display("State %b and first %b", state, first);
                case(state)
                        unpack: begin
                                first_mantissa <= first[`MANT_BITNESS(bitness) - 1:0];
                                first_exp      <= first[bitness - 2: `MANT_BITNESS(bitness) - 1];
                                first_sign     <= first[bitness - 1];

                                second_mantissa <= second[`MANT_BITNESS(bitness) - 1:0];
                                second_exp      <= second[bitness - 2: `MANT_BITNESS(bitness) - 1];
                                second_sign     <= second[bitness - 1];

                                // TODO use another state!
                                state <= pack;
                        end

                        pack: begin
                                result_sign     <= first_sign;
                                result_exp      <= first_exp;
                                result_mantissa <= first_mantissa;

                                // Packing result, work is done
                                result_internal[bitness - 1]                             = result_sign;
                                result_internal[bitness - 2: `MANT_BITNESS(bitness) - 1] = result_exp;
                                result_internal[`MANT_BITNESS(bitness) - 1:0]            = result_mantissa;

                                work_is_done_internal <= 1'b1;
                        end
                endcase

                if (reset == 1) begin
                        state <= unpack;
                        work_is_done_internal <= 0;
                end
        end

        assign result = result_internal;
        assign work_is_done = work_is_done_internal;

endmodule
