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
        #(
                parameter bitness      = 32
        ,       parameter data_threads = 1
        )
(
        input clock,
        input reset,

        input  input_rdy,
        output input_ack,

        output output_rdy,
        input  output_ack,

        // input [bitness - 1:0][data_threads] data_a,
        // input [bitness - 1:0][data_threads] data_b,
        input [bitness - 1:0] data_a,
        input [bitness - 1:0] data_b,

        input Operation_t operation,

        // output [bitness - 1:0][data_threads] result
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

        /** Input unpacking function.
         * Unpacks data from vector into structured input data storage.
         */
        function Number_t get_input_data(input [bitness - 1:0] data);
                get_input_data.significand = {1'b1, data[`MANT_SIZE(bitness) - 1:0]};
                get_input_data.exponent    = data[bitness - 2: `MANT_SIZE(bitness)] - `BIAS_COEFF(bitness);
                get_input_data.sign        = data[bitness - 1];
        endfunction

        logic [bitness - 1:0]
                        s_result
                ,       s_out_result;

        logic
                        s_output_rdy
                ,       s_input_ack;

        Number_t
                        i_data_a
                ,       i_data_b
                ,       i_result;

        logic[`EXP_SIZE(bitness) - 1:0] exp_difference;

        always @(posedge clock) begin
                if (reset) begin
                        state        <= get_input;
                        s_output_rdy <= 0;
                        s_input_ack  <= 0;
                end

                case (state)
                        get_input: begin
                                if (input_rdy) begin
                                        i_data_a = get_input_data(data_a);
                                        i_data_b = get_input_data(data_b);

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
                                if (i_result.significand[`MANT_SIZE(bitness)]) begin
                                        i_result.exponent    <= i_result.exponent + 1;
                                        i_result.significand <= i_result.significand >> 1;
                                end
                                state <= bias_out_calc;
                        end

                        mul: begin
                                i_result.sign <= i_data_a.sign || i_data_b.sign;
                                i_result.exponent <= i_data_a.exponent + i_data_b.exponent;
                                i_result.significand <= i_data_a.significand * i_data_b.significand;

                                state <= bias_out_calc;
                        end

                        div: begin
                                i_result.sign <= i_data_a.sign || i_data_b.sign;
                                i_result.exponent <= i_data_a.exponent - i_data_b.exponent;
                                i_result.significand <= i_data_a.significand / i_data_b.significand;

                                state <= bias_out_calc;
                        end

                        normalize: begin
                        end

                        bias_out_calc: begin
                                i_result.exponent <= i_result.exponent + `BIAS_COEFF(bitness);

                                state <= put_result;
                        end

                        put_result: begin
                                // Пакуется криво, добавляется на кой-то хер с
                                // крытый бит
                                $display("RESULT: %b", i_result);
                                s_out_result[bitness - 1]                      <= i_result.sign;
                                s_out_result[bitness - 2: `MANT_SIZE(bitness)] <= i_result.exponent;
                                s_out_result[`MANT_SIZE(bitness) - 1:0]        <= i_result.significand[`MANT_SIZE(bitness) - 1:0];
                                s_output_rdy <= 1;

                                if (s_out_result && output_ack) begin
                                        s_output_rdy <= 0;
                                        state        <= get_input;
                                end
                        end

                endcase
        end

        assign result     = s_out_result;
        assign output_rdy = s_output_rdy;
        assign input_ack  = s_input_ack;

endmodule
