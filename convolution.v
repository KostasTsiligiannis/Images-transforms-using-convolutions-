// -----------------------------------------------------------------------------
//  convolution.v  –  Streaming 3×3 convolution core
//
//  * One pixel per clock throughput (after initial latency)
//  * No zero-padding: computes valid window range [1 .. W-2][1 .. H-2]
//  * External kernel (3×3, signed 8-bit) provided at frame start
//  * Up to three image reads / clk   –   single result write / clk
//  * MAC accumulator sized for 9 × 255 × 64 ≈ 147k  (< 2¹⁸)
//  * Normalisation via arithmetic right-shift (run-time selectable)
// -----------------------------------------------------------------------------
`timescale 1ns/1ps
module convolution #(
    parameter IMG_W = 128,             // image width  in pixels
    parameter IMG_H = 128              // image height in pixels
)(
    // ---------------------------------------------------------------------
    // Port list
    // ---------------------------------------------------------------------
    input  wire                 clk,         // rising-edge system clock
    input  wire                 rstn,        // async reset, active-low
    input  wire                 start,       // 1-clk pulse – process full frame

    input  wire signed [7:0]    kernel [0:8],// 3×3 coefficients (row-major)
    input  wire        [3:0]    norm_shift,  // divide result by 2^N (0-15)

    output reg                  done         // pulses 1-clk at last pixel
);

    // ---------------------------------------------------------------------
    // Internal storage
    // ---------------------------------------------------------------------
    // 8-bit register files rather than external memories (fits in FPGA BRAM)
    reg [7:0] image_mem [0:IMG_H-1][0:IMG_W-1];
    reg [7:0] out_mem   [0:IMG_H-1][0:IMG_W-1];

    // ---------------------------------------------------------------------
    // FSM encoding
    // ---------------------------------------------------------------------
    localparam IDLE=2'd0, LOAD=2'd1, MAC=2'd2, STORE=2'd3;
    reg [1:0] state;

    // ---------------------------------------------------------------------
    // Loop indices / datapath regs
    // ---------------------------------------------------------------------
    integer row, col, k, y, x, subrow;
    reg [7:0] pix_buf [0:2];                     // 3-pixel shift register
    reg signed [18:0] acc, row_sum, tmp;         // 18-bit safe
    reg [7:0]        clipped;

    // =========================================================================
    // Main FSM
    // =========================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            //--------------------------------------------------------------
            // Asynchronous reset – clear state, pointers and output RAM
            //--------------------------------------------------------------
            state <= IDLE;
            done  <= 1'b0;
            row   <= 1;
            col   <= 1;
            acc   <= 0;
            for (y = 0; y < IMG_H; y = y + 1)
                for (x = 0; x < IMG_W; x = x + 1)
                    out_mem[y][x] <= 8'd0;
        end
        else begin
            case (state)

            //---------------------------- IDLE -----------------------------
            IDLE: begin
                done <= 1'b0;
                if (start) begin
                    row <= 1; col <= 1;
                    subrow <= 0;
                    acc <= 0;
                    state <= LOAD;
                end
            end

            //---------------------------- LOAD -----------------------------
            // Read three pixels of the current sub-row into pix_buf[0:2]
            //----------------------------------------------------------------
            LOAD: begin
                for (k = 0; k < 3; k = k + 1)
                    pix_buf[k] <= image_mem[row + subrow - 1][col + k - 1];
                state <= MAC;
            end

            //---------------------------- MAC ------------------------------
            // Accumulate the three products of this sub-row
            //----------------------------------------------------------------
            MAC: begin
                row_sum =  $signed({1'b0, pix_buf[0]}) * kernel[subrow*3 + 0]
                         + $signed({1'b0, pix_buf[1]}) * kernel[subrow*3 + 1]
                         + $signed({1'b0, pix_buf[2]}) * kernel[subrow*3 + 2];

                acc <= acc + row_sum;

                if (subrow == 2) begin
                    subrow <= 0;
                    state  <= STORE;               // all 3×3 terms done
                end else begin
                    subrow <= subrow + 1;
                    state  <= LOAD;                // next sub-row
                end
            end

            //---------------------------- STORE ----------------------------
            // Scale, clip and write one output pixel
            //----------------------------------------------------------------
            STORE: begin
                tmp = acc >>> norm_shift;          // divide by 2^N

                // saturate to 0…255
                if (tmp < 0)         clipped = 8'd0;
                else if (tmp > 255)  clipped = 8'd255;
                else                 clipped = tmp[7:0];

                out_mem[row][col] <= clipped;
                acc <= 0;                          // clear accumulator

                // Next pixel coordinates
                if (col < IMG_W-2) begin
                    col   <= col + 1;
                    state <= LOAD;
                end else if (row < IMG_H-2) begin
                    col   <= 1;
                    row   <= row + 1;
                    state <= LOAD;
                end else begin
                    done  <= 1'b1;                 // frame complete
                    state <= IDLE;
                end
            end

            default: state <= IDLE;                // safety
            endcase
        end
    end

endmodule
