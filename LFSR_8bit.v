`timescale 1ns / 1ps

module LFSR_8bit #(
    parameter SEED = 8'b00010011
)(
    input clk,
    input rst,
    output [7:0] random_out
);

    reg [7:0] lfsr_reg;
    wire feedback;

    // Feedback using taps at positions 8, 6, 5, 4 (maximal length LFSR)
    assign feedback = lfsr_reg[7] ^ lfsr_reg[5] ^ lfsr_reg[4] ^ lfsr_reg[3];

    always @(posedge clk) begin
        if (rst) begin
            lfsr_reg <= SEED;
        end
        else begin
            lfsr_reg <= {lfsr_reg[6:0], feedback};
        end
    end

    assign random_out = lfsr_reg;

endmodule
