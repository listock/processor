/*
 * Floating point processing unit.
 *
 * This module can perfomance next tasks with two operands:
 *      - Add
 *      - Subtract
 *      - Multiply
 *      - Division
 *
 * Author: Aleksandr Novozhilov
 * Creating date: 2018-02-12
 *
 */
`include "macro.sv"


/* Operation type.
 */
typedef enum logic[3:0] {
                add_op = 4'b0000  // Sum A and B
        ,       sub_op = 4'b0001  // Subtract A from B
        ,       mul_op = 4'b0010  // Multiply A to B
        ,       div_op = 4'b0011  // Division A by B
                               // Other values are reserved
        } Operation_t;


module fpu
        #(parameter bitness=32)
(
        input clock,
        input reset,

        input  input_rdy,
        output input_ack,

        output output_rdy,
        input  output_ack,

        input [bitness - 1:0] data_a,
        input [bitness - 1:0] data_b,

        input Operation_t operation,

        output [bitness - 1:0] result
);
        enum logic[3:0] {
                        unpack        = 4'b0000
                ,       pack          = 4'b0001
                ,       align         = 4'b0010
                ,       normalize     = 4'b0011
                ,       add_0         = 4'b0100
                ,       add_1         = 4'b0101
                ,       sub           = 4'b0110
                ,       mul           = 4'b0111
                ,       div           = 4'b1000
                ,       put_result    = 4'b1001
                ,       get_input     = 4'b1010
                ,       special       = 4'b1011
                ,       op_handling   = 4'b1100
                ,       bias_out_calc = 4'b1101
        } state;

        typedef struct packed {
                bit                            sign;
                bit [`EXP_SIZE(bitness) - 1:0] exponent;
                bit [`MANT_SIZE(bitness)   :0] significand;
        } Number_t;

        logic [bitness - 1:0]   s_result
                            , s_out_result;
        logic  s_output_rdy
            ,s_input_ack;

        // TODO: DELETE
        logic [bitness - 1:0]   s_data_a
                            , s_data_b;

        // TODO: DELETE
        logic   data_a_sign
            , data_b_sign
            , result_sign;

        Number_t
                        i_data_a
                ,       i_data_b
                ,       i_result;

        // TODO: DELETE
        logic[`EXP_SIZE(bitness) - 1:0]   data_a_exp
                                      , data_b_exp
                                      , result_exp
                                      , exp_difference;

        // Inner mantissa with hidden bit.
        // TODO: DELETE
        logic[`MANT_SIZE(bitness):0]   data_a_mantissa
                                   , data_b_mantissa
                                   , result_mantissa;


        always @(posedge clock) begin
                if (reset) begin
                        state        <= get_input;
                        s_output_rdy <= 0;
                        s_input_ack  <= 0;
                end

                case (state)
                        get_input: begin
                                if (input_rdy) begin
                                        i_data_a.significand <= {1'b1, data_a[`MANT_SIZE(bitness) - 1:0]};
                                        i_data_a.exponent    <= data_a[bitness - 2: `MANT_SIZE(bitness)] - `BIAS_COEFF(bitness);
                                        i_data_a.sign        <= data_a[bitness - 1];

                                        i_data_b.significand <= {1'b1, data_b[`MANT_SIZE(bitness) - 1:0]};
                                        i_data_b.exponent    <= data_b[bitness - 2: `MANT_SIZE(bitness)] - `BIAS_COEFF(bitness);
                                        i_data_b.sign        <= data_b[bitness - 1];

                                        s_input_ack <= 1;

                                        state <= special;
                                end
                        end

                        /* Special cases
                         */
                        special: begin
                                $display("SPECIAL A: %b %b %b", i_data_a.sign, i_data_a.exponent, i_data_a.significand);
                                $display("SPECIAL B: %b %b %b", i_data_b.sign, i_data_b.exponent, i_data_b.significand);
                                // Inf A case
                                if (i_data_a.exponent == `MAX_EXP_VALUE(bitness) && i_data_a.significand[`MANT_SIZE(bitness) - 1:0] == 0) begin
                                        i_result.sign        <= i_data_a.sign || i_data_b.sign;
                                        i_result.exponent    <= '1;
                                        i_result.significand <= '0;
                                        state <= put_result;
                                end
                                else
                                // Inf B case
                                if (i_data_b.exponent == `MAX_EXP_VALUE(bitness) && i_data_b.significand[`MANT_SIZE(bitness) - 1:0] == 0) begin
                                        i_result.sign        <= i_data_a.sign || i_data_b.sign;
                                        i_result.exponent    <= '1;
                                        i_result.significand <= '0;
                                        state <= put_result;
                                end
                                else
                                // Case if A or B is NaN
                                if ((i_data_a.exponent == `MAX_EXP_VALUE(bitness) && i_data_a.significand != 0) ||
                                    (i_data_b.exponent == `MAX_EXP_VALUE(bitness) && i_data_b.significand != 0)) begin

                                        i_result.sign        <= i_data_a.sign || i_data_b.sign;
                                        i_result.exponent    <= '1;
                                        i_result.significand <= '1;
                                        state <= put_result;
                                end
                                else begin
                                    state <= op_handling;
                                end
                        end

                        op_handling: begin
                                           case (operation)
                                                add_op: begin
                                                        state <= align;
                                                end
                                                mul_op: begin
                                                        state <= mul;
                                                end
                                                div_op: begin
                                                        state <= div;
                                                end
                                                default: begin
                                                        state <= put_result;
                                                end
                                        endcase
                        end

                        /* Input numbers aligning
                         */
                        align: begin
                                if ($signed(i_data_a.exponent) > $signed(i_data_b.exponent)) begin
                                        $display("A > B!");
                                        exp_difference = $signed(i_data_a.exponent) - $signed(i_data_b.exponent);

                                        i_data_b.exponent    = i_data_a.exponent;
                                        i_data_b.significand = i_data_b.significand >> exp_difference;
                                end
                                else
                                if ($signed(i_data_a.exponent) < $signed(i_data_b.exponent)) begin
                                        $display("A < B!");
                                        exp_difference = $signed(i_data_b.exponent) - $signed(i_data_a.exponent);

                                        i_data_a.exponent    = i_data_b.exponent;
                                        i_data_a.significand = i_data_a.significand >> exp_difference;
                                end
                                state <= add_0;
                        end

                        add_0: begin
                                $display("A: %b %b %b", i_data_a.sign, i_data_a.exponent, i_data_a.significand);
                                $display("B: %b %b %b", i_data_b.sign, i_data_b.exponent, i_data_b.significand);

                                i_result.exponent <= i_data_a.exponent;
                                if (i_data_a.sign == i_data_b.sign) begin
                                        i_result.sign        <= i_data_a.sign;
                                        i_result.significand <= i_data_a.significand[`MANT_SIZE(bitness) - 1:0] + i_data_b.significand[`MANT_SIZE(bitness) - 1:0];
                                end
                                else
                                if (i_data_a.significand >= i_data_b.significand) begin
                                        i_result.sign        <= i_data_a.sign;
                                        i_result.significand <= i_data_a.significand[`MANT_SIZE(bitness) - 1:0] - i_data_b.significand[`MANT_SIZE(bitness) - 1:0];
                                end
                                else
                                if (i_data_a.significand < i_data_b.significand) begin
                                        i_result.sign        <= i_data_b.sign;
                                        i_result.significand <= i_data_b.significand[`MANT_SIZE(bitness) - 1:0] - i_data_a.significand[`MANT_SIZE(bitness) - 1:0];
                                end
                                state <= add_1;
                        end

                        add_1: begin
                                // Align result to the right if overflow occures.
                                //if (result_mantissa[`MANT_SIZE(bitness)]) begin
                                        //result_exp      <= result_exp + 1;
                                        //result_mantissa <= result_mantissa >> 1;
                                //end

                                if (i_result.significand[`MANT_SIZE(bitness)]) begin
                                        i_result.exponent    <= i_result.exponent + 1;
                                        i_result.significand <= i_result.significand >> 1;
                                end
                                //state <= pack;
                                state <= bias_out_calc;
                        end

                        mul: begin
                                i_result.sign <= i_data_a.sign || i_data_b.sign;
                                i_result.exponent <= i_data_a.exponent + i_data_b.exponent;
                                i_result.significand <= i_data_a.significand * i_data_b.significand;

                                state <= bias_out_calc;
                        end

                        div: begin
                                result_sign     <= data_a_sign || data_b_sign;
                                result_exp      <= data_a_exp - data_b_exp;
                                result_mantissa <= data_a_mantissa / data_b_mantissa;

                                state <= bias_out_calc;
                                //state <= pack;
                        end

                        normalize: begin
                                $display("NORM STEP: %b %b", result_exp, result_mantissa);
                                if (result_mantissa[`MANT_SIZE(bitness)] == 0) begin
                                    result_exp <= result_exp - 1;
                                    result_mantissa <= result_mantissa << 1;
                                end
                                else begin
                                        state <= bias_out_calc;
                                end
                                //$display("%b %b", data_a_exp, data_a_mantissa);
                                //$display("%b %b", data_b_exp, data_b_mantissa);
                                //$display("Normolize %b %b %d", result_exp, result_mantissa, (`MANT_SIZE(bitness) + 1));

                                //if (result_mantissa[`MANT_SIZE(bitness)] == 0 && $signed(result_exp) > -126) begin
                                //        result_exp <= result_exp - 1;
                                //        result_mantissa <= result_mantissa << 1;
                                //end

                                // If hidden bit is not zero after adding
                                //if (result_mantissa[`MANT_SIZE(bitness)] == 0) begin
                                //
                                //end
                                //state <= pack;
                        end

                        // Packing result, work is done.
                        //pack: begin
                                //s_result[bitness - 1]                      <= result_sign;
                                //s_result[bitness - 2: `MANT_SIZE(bitness)] <= result_exp + `BIAS_COEFF(bitness);
                                //s_result[`MANT_SIZE(bitness) - 1:0]        <= result_mantissa[`MANT_SIZE(bitness) - 1:0];

                                //state <= put_result;
                        //end

                        bias_out_calc: begin
                                i_result.exponent <= i_result.exponent + `BIAS_COEFF(bitness);

                                state <= put_result;
                        end

                        put_result: begin
                                // Пакуется криво, добавляется на кой-то хер с
                                // крытый бит
                                $display("RESULT: %b", i_result);
                                //s_out_result <= i_result;
                                s_out_result[bitness - 1]                      <= i_result.sign;
                                s_out_result[bitness - 2: `MANT_SIZE(bitness)] <= i_result.exponent;
                                s_out_result[`MANT_SIZE(bitness) - 1:0]        <= i_result.significand[`MANT_SIZE(bitness) - 1:0];
                                s_output_rdy <= 1;

                                if (s_out_result && output_ack) begin
                                        s_output_rdy <= 0;
                                        state        <= get_input;
                                end

                                /*
                                s_out_result <= s_result;
                                s_output_rdy <= 1;

                                if (s_output_rdy && output_ack) begin
                                        s_output_rdy <= 0;
                                        state        <= get_input;
                                end
                                */
                        end

                endcase
        end

        assign result     = s_out_result;
        assign output_rdy = s_output_rdy;
        assign input_ack  = s_input_ack;

endmodule
