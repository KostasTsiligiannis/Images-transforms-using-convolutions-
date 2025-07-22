# -Ιmages-transforms-using-convolutions-
Streaming image-filter core (Verilog) with self-test bench, Makefile flow and Python SSIM/overlay validation.
> Streaming convolution engine written in **Verilog**,  
> complete test-bench, one-command Makefile flow, and a Python validator
> that visualises differences with SSIM, heat-map and red overlay.

---

## ❓ Why does this project exist?

*Small FPGAs and edge-SoCs still need “old-school” spatial filters*:
Gaussian blur (denoise), sharpen/unsharp (enhance), Sobel or outline
(feature extraction) – and all of them are 3 × 3 convolutions.

Commercial IP usually burns **9 multipliers** or uses a huge line buffer
per coefficient.  The goal here is to show a **minimal-area, one-pixel-per-clock**
pipeline that fits into a tiny iCE40 or a few k gates ASIC block,
yet is parameter-clean and fully self-checked.

---

## ✨ Key features

| • | Description |
|---|-------------|
 **1 px / clk** throughput after pipeline fill |
 External kernel – just swap `kernels/<name>.hex` (signed 8-bit) |
 Run-time normalisation via right-shift (`shift_<name>.hex`) |
 3 image reads / clk · 1 result write / clk – fits in one BRAM port |
 18-bit accumulator (9 × 255 × 64 < 2¹⁸) |
 Makefile: `make FILTER=blur IMAGE=lenna.png` – that’s it |
 Python script → SSIM, heat-map **and** red overlay of differences |
