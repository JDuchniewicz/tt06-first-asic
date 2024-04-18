/*
 * Copyright (c) 2024 Jakub Duchniewicz
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_jduchniewicz_prng (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // Will go high when the design is enabled
    input  wire       clk,      // Clock
    input  wire       rst_n     // Reset, active low
);

    // Set bidir pins all to output mode
    assign uio_oe = 8'hFF;

    // Set bidir output to always be equal to input
    assign uio_out = uio_in;

    // 8-bit LFSR with internal state of 16-bits where output is a XOR of
    // left-shifted lower 8-bits and right-shifted 8-bits basing on https:
    // //stackoverflow.com/questions/14497877/how-to-implement-a-pseudo-hardware-random-number-generator
    reg [15:0] lfsr;  // 16-bit internal state for the LFSR
    reg [7:0] out;    // 8-bit output
    assign uo_out = out;  // Assign the internal 'out' to the module's output

    //wire feedback = lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3];  // Feedback tap for LFSR

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr <= {ui_in, ui_in};  // Initialize LFSR with the input when reset
        end else if (ena) begin
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[14] ^ lfsr[12] ^ lfsr[3]};  // Update LFSR only if enabled
        end else begin
            lfsr <= lfsr;
        end
        // No else part here; we hold the state of 'lfsr' when not enabled
    end

    // Update the output 'out' based on the current state of 'lfsr', but only if enabled
    always @(posedge clk) begin
        if (ena) begin
            out <= (lfsr[15:8] << 1 | lfsr[15:8] >> 7) ^ (lfsr[7:0] >> 1 | lfsr[7:0] << 7);
        end
    end

endmodule
