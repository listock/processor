/** Floating point processing unit.
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
        typedef enum logic[3:0] {
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
        } Sate_t;

        Sate_t state;

        typedef struct packed {
                bit                            sign;
                bit [`EXP_SIZE(bitness) - 1:0] exponent;
                bit [`MANT_SIZE(bitness)   :0] significand;
        } Number_t;

        /** Input unpacking function.
         * Unpacks data from vector into structured input data storage.
         *
         * @param data Bit vector containing one number.
         *
         * @returns Unpacked into structure number.
         */
        function Number_t get_input_data(input [bitness - 1:0] data);
                get_input_data.significand = {1'b1, data[`MANT_SIZE(bitness) - 1:0]};
                get_input_data.exponent    = data[bitness - 2: `MANT_SIZE(bitness)] - `BIAS_COEFF(bitness);
                get_input_data.sign        = data[bitness - 1];
        endfunction

        /** Adds two numbers.
         *
         * @param left Left summand.
         * @param right Right summand.
         *
         * @returns Summ on two numbers.
         */
        function Number_t add_numbers(input Number_t left, input Number_t right);
                add_numbers.exponent = left.exponent;
                if (left.sign == right.sign) begin
                        add_numbers.sign        = left.sign;
                        add_numbers.significand = left.significand[`MANT_SIZE(bitness) - 1:0] + right.significand[`MANT_SIZE(bitness) - 1:0];
                end
                else
                if (left.significand >= right.significand) begin
                        add_numbers.sign        = left.sign;
                        add_numbers.significand = left.significand[`MANT_SIZE(bitness) - 1:0] - i_data_b.significand[`MANT_SIZE(bitness) - 1:0];
                end
                else
                if (left.significand < right.significand) begin
                        add_numbers.sign        = right.sign;
                        add_numbers.significand = right.significand[`MANT_SIZE(bitness) - 1:0] - left.significand[`MANT_SIZE(bitness) - 1:0];
                end
        endfunction

        /** Hadle special input cases: infinity on both arguments, NaN.
         * If any of them is inf or NaN it stops machine and prepare
         * result according to IEEE 754.
         *
         * @param left Left operand.
         * @param right Right operand.
         * @param result Result number.
         *
         * @returns Next state of fpu machine.
         */
        function automatic Sate_t handle_special_cases(input Number_t left, input Number_t right, ref Number_t result);
                // Inf A case
                if (left.exponent == `MAX_EXP_VALUE(bitness) && left.significand[`MANT_SIZE(bitness) - 1:0] == 0) begin
                        result.sign        = left.sign || right.sign;
                        result.exponent    = '1;
                        result.significand = '0;
                        handle_special_cases = put_result;
                end
                else
                // Inf B case
                if (right.exponent == `MAX_EXP_VALUE(bitness) && right.significand[`MANT_SIZE(bitness) - 1:0] == 0) begin
                        result.sign        = left.sign || right.sign;
                        result.exponent    = '1;
                        result.significand = '0;
                        handle_special_cases = put_result;
                end
                else
                // Case if A or B is NaN
                if ((left.exponent == `MAX_EXP_VALUE(bitness) && left.significand != 0) ||
                        (right.exponent == `MAX_EXP_VALUE(bitness) && right.significand != 0)) begin

                        result.sign        = left.sign || right.sign;
                        result.exponent    = '1;
                        result.significand = '1;
                        handle_special_cases = put_result;
                end
                // Normal calculating cases
                else begin
                        handle_special_cases = op_handling;
                end
        endfunction

        /** Aligns operands for add.
         * Shifts right the operand whose exponent smaller.
         *
         * @param left Left summand.
         * @param right Right summand.
         */
        function automatic void align_numbers(ref Number_t left, ref Number_t right);
                logic[`EXP_SIZE(bitness) - 1:0] exp_difference;

                if ($signed(left.exponent) > $signed(right.exponent)) begin
                        exp_difference = $signed(left.exponent) - $signed(right.exponent);

                        right.exponent    = left.exponent;
                        right.significand = right.significand >> exp_difference;
                end
                else
                if ($signed(left.exponent) < $signed(right.exponent)) begin
                        exp_difference = $signed(right.exponent) - $signed(left.exponent);

                        left.exponent    = right.exponent;
                        left.significand = left.significand >> exp_difference;
                end
        endfunction

        /** Multiplies two numbers.
         *
         * @param left Left operand.
         * @oaram right Right operand.
         *
         * @returns Result of multiplication.
         */
        function Number_t multiply_numbers(input Number_t left, input Number_t right);
                multiply_numbers.sign = i_data_a.sign || i_data_b.sign;
                multiply_numbers.exponent = i_data_a.exponent + i_data_b.exponent;
                multiply_numbers.significand = i_data_a.significand * i_data_b.significand;
        endfunction

        /** Divides twi numbers.
         *
         * @param left Divinded.
         * @params right Divider.
         *
         * @returns The result of division.
         */
        function Number_t divide_numbers(input Number_t left, input Number_t right);
                divide_numbers.sign <= left.sign || right.sign;
                divide_numbers.exponent <= left.exponent - right.exponent;
                divide_numbers.significand <= left.significand / right.significand;
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
                                state = handle_special_cases(i_data_a, i_data_b, i_result);
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
                                align_numbers(i_data_a, i_data_b);
                                state <= add_0;
                        end

                        add_0: begin
                                i_result = add_numbers(i_data_a, i_data_b);
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
                                i_result = multiply_numbers(i_data_a, i_data_b);
                                state <= bias_out_calc;
                        end

                        div: begin
                                i_result = divide_numbers(i_data_a, i_data_b);
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
