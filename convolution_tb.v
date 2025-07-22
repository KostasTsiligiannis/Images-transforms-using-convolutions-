// SPDX-License-Identifier: MIT
// -----------------------------------------------------------------------------
//  convolution_tb.v – Memory-based frame test-bench
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module convolution_tb;

    localparam W = 128, H = 128, PIXELS = W*H;

    // -----------------------------------------------------------------
    // Clock / reset
    // -----------------------------------------------------------------
    reg clk = 0; always #5 clk = ~clk;
    reg rstn = 0;

    // -----------------------------------------------------------------
    // DUT
    // -----------------------------------------------------------------
    reg  start = 0;
    wire done;

    // kernel & shift from files
    reg signed [7:0] k [0:8];   initial $readmemh("kernel.hex", k);
    reg       [7:0] sh_mem [0:0]; initial $readmemh("shift.hex", sh_mem);
    wire [3:0] shift = sh_mem[0][3:0];

    convolution #(.IMG_W(W), .IMG_H(H)) dut (
        .clk       (clk),
        .rstn      (rstn),
        .start     (start),
        .kernel    (k),
        .norm_shift(shift),
        .done      (done)
    );

    // flat output buffer
    reg [15:0] out_flat [0:PIXELS-1];
    integer i, j;

    // -----------------------------------------------------------------
    // Test sequence
    // -----------------------------------------------------------------
    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0, convolution_tb);

        // preload full frame into DUT memory
        $readmemh("input.hex", dut.image_mem);

        // de-assert reset and send a single-clock start pulse
        #12 rstn = 1;
        #10 start = 1;
        #10 start = 0;

        // wait until core asserts done
        wait (done);

        // dump result
        for (i = 0; i < H; i = i + 1)
            for (j = 0; j < W; j = j + 1)
                out_flat[i*W + j] = dut.out_mem[i][j];

        $writememh("output.hex", out_flat);
        $display("Convolution finished – filter: %s", `FILTER_NAME);
        #20 $finish;
    end
endmodule
