/* Add testing bench
 *
 * Author: Aleksandr Novozhilov
 * Date: 2018-02-09
 */


`define TEST_MESSAGE(result, expectation, name) $display("Test \"%s\": %s WITH value %b", name, ((result == expectation)? "OK" : "FAILED"), result);


module add_tb();

        logic clock, reset, input_rdy, output_rdy;

        logic [31:0] left, right;

        logic [31:0] result;

        logic [3:0] operation;

        logic input_ack;
        logic output_ack;

        fpu DUT (
                .operation(operation),
                .clock(clock),
                .reset(reset),
                .data_a(left),
                .data_b(right),
                .output_rdy(output_rdy),
                .output_ack(output_ack),
                .input_rdy(input_rdy),
                .input_ack(input_ack),
                .result(result));

        initial begin

                // Let's start testing add operation
                operation = 4'b0000;

                /*
                left = 32'b0_01111111_00000000000000000000000;
                right= 32'b0_01111000_01000111101011100001010;
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                output_ack <= 0;
                while(!output_rdy) begin
                        #1;
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE(result, 32'b0_01111111_00000010100011110101110, "summ 1")
                                #1;
                                output_ack = 1;
                        end
                end

                left = 32'b0_10000011_01010000000000000000000;
                right= 32'b0_01111101_00101000111101011100001;
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                output_ack <= 0;
                while(!output_rdy) begin
                        #1;
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE(result, 32'b0_10000011_01010100101000111101011, "summ 2")
                                #1;
                                output_ack = 1;
                        end
                end*/

                left = 32'b1_01111111_00000000000000000000000;
                right= 32'b0_10000010_10000110011001100110011;
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                output_ack <= 0;
                while(!output_rdy) begin
                        #1;
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE(result, 32'b0_10000010_01100110011001100110011, "Addition 1.0 + (-12.2) = -11.2")
                                #1;
                                output_ack = 1;
                        end
                end

                left = 32'b1_01111111_00000000000000000000000;
                right= 32'b1_10000010_10000110011001100110011;
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                output_ack <= 0;
                while(!output_rdy) begin
                        #1;
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE(result, 32'b1_10000010_10100110011001100110011, "Addition -1.0 + (-12.2) = -13.2")
                                #1;
                                output_ack = 1;
                        end
                end

                left = 32'b0_11111101_00101100111011010011001;
                right= 32'b1_01111111_00011001100110011001101;
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                output_ack <= 0;
                while(!output_rdy) begin
                        #1;
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE(result, 32'b0_11111101_00101100111011010011001, "1e38 + (-1.1) = 1e38")
                                #1;
                                output_ack = 1;
                        end
                end

                left = 32'b0_11111111_00000000000000000000000;
                right= 32'b1_01111111_00011001100110011001101;
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                output_ack <= 0;
                while(!output_rdy) begin
                        #1;
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE(result, 32'b11111111100000000000000000000000, "summ 6")
                                #1;
                                output_ack = 1;
                        end
                end

                left = 32'b1_01111111_00011001100110011001101;
                right= 32'b0_11111111_00000000000000000000000;
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                output_ack <= 0;
                while(!output_rdy) begin
                        #1;
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE(result, 32'b11111111100000000000000000000000, "summ 7")
                                #1;
                                output_ack = 1;
                        end
                end

                left = 32'b1_11111111_00011001100110011001101;
                right= 32'b0_11111111_00011001100110011001101;
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                output_ack <= 0;
                while(!output_rdy) begin
                        #1;
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE(result, 32'b11111111111111111111111111111111, "Addition NaN + NaN = NaN")
                                #1;
                                output_ack = 1;
                        end
                end

                left = 32'b0_11111111_00000000000000000000000;
                right= 32'b0_01111111_00000000000000000000000;
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                output_ack <= 0;
                while(!output_rdy) begin
                        #1;
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE(result, 32'b0_11111111_00000000000000000000000, "Addition Inf + 1 = NaN")
                                #1;
                                output_ack = 1;
                        end
                end

                /* Multiply operation test */
                /*operation = 4'b0010;

                left = 32'b0_10000000_00000000000000000000000;
                right= 32'b0_10000000_00000000000000000000000;
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                output_ack <= 0;
                while(!output_rdy) begin
                        #1;
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE(result, 32'b0_10000001_00000000000000000000000, "Multiply 2.0 x 2.0 = 4.0")
                                #1;
                                output_ack = 1;
                        end
                end

                left = 32'b1_10000000_00000000000000000000000;
                right= 32'b0_10000000_00000000000000000000000;
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                output_ack <= 0;
                while(!output_rdy) begin
                        #1;
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE(result, 32'b1_10000001_00000000000000000000000, "Multiply -2.0 x 2.0 = -4.0")
                                #1;
                                output_ack = 1;
                        end
                end

                operation = 4'b0011;

                left = 32'b0_10000001_00000000000000000000000;
                right= 32'b0_10000000_00000000000000000000000;
                reset = 1'b1;
                input_rdy = 1;
                clock = 1;
                #5;
                reset = 0;
                output_ack <= 0;
                while(!output_rdy) begin
                        #1;
                        clock = ~clock;
                        if (output_rdy && input_ack) begin
                                `TEST_MESSAGE(result, 32'b0_10000000_00000000000000000000000, "Division 4.0 / 2.0 = 2.0")
                                #1;
                                output_ack = 1;
                        end
                end
                */
        end

        initial begin
                #500 $finish;
        end

endmodule
