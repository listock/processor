/*
 * Normalize numbers in parallel.
 *
 * Author: Aleksandr Novozhilov
 * Creating date: 2018-05-15
 *
 */

module normalize
        #(
                parameter bitness = 32,
                parameter numbers_quantity = 2
        )
(
        input clock,

        //reg [bitness - 1:0][numbers_quantity:0] numbers
        reg [numbers_quantity - 1:0][bitness - 1:0] numbers
);

        bit sum = '0;
        bit [bitness - 1:0] counter = '0;

        always  @(posedge clock) begin
                foreach(numbers[i]) begin
                        numbers[i] = numbers[i] << (numbers[i][bitness - 1] ^ 1'b1);
                        sum = ~(sum & numbers[i][bitness - 1]);
                end
        end

endmodule