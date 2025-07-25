# 3×3 Image-Convolution Core (Verilog + Python Validation)

A minimal-area, 1-pixel/clk spatial-filter engine for FPGA or ASIC, complete with:

- **Verilog RTL** for a streaming 3×3 convolution core  
- **Self-checking testbench** (memory-based, parameterisable)  
- **Makefile** flow: clean → build → simulate → render PNG  
- **Kernel library** (`kernels/*.hex`) for blur, sharpen, emboss, Sobel, outline…  
- **Python scripts** for PNG↔HEX conversion and SW vs HDL validation (SSIM, heat-map, overlay)

---

## 🎯 Project Goal

Implement classic 3×3 image filters (Gaussian blur, sharpen, Sobel edges, emboss…) in hardware with:

- **Maximum throughput**: one output pixel per clock  
- **Minimal area**: single multiplier reused for 9 MAC operations, only three line-buffers  
- **Runtime flexibility**: swap filters by loading different `*.hex` coefficient files—no RTL re-synthesis required  
- **End-to-end verification**: compare RTL output against a Python reference using SSIM and visual overlays  
  > **Tip:** to test a new filter, simply edit the `kernel` array in validate_filter.py to match your chosen `*.hex` file.

---

## 🔍 How It Works

1. **Image storage**  
   A 128×128 grayscale frame is preloaded into `image_mem` (a Verilog register file).  
2. **Streaming FSM**  
   On a single-clock `start` pulse, the FSM cycles through `LOAD → MAC → STORE` for each valid pixel (rows/cols 1…126), reading a 3×3 window via three line-buffers.  
3. **MAC engine**  
   One signed multiplier computes each tap, accumulates into an 18-bit register, applies an arithmetic right-shift (`norm_shift`) then clips to 0…255.  
4. **Output storage**  
   Each result pixel is written back to `out_mem` at one-pixel/clk.  
5. **Testbench**  
   Loads `input.hex` into `image_mem`, pulses `start`, waits for `done`, then dumps `out_mem` to `output.hex`.  
6. **Python validation**  
   - `hex_to_img.py` renders `output.hex` into `output.png`  
   - `validate_overlay.py` runs the same 3×3 filter in software, computes SSIM, produces a heat-map of |SW–HDL|, and overlays mismatches in red.

---

This lightweight 3×3 convolution core and flow are ideal for:

    Embedded smart cameras—offload simple filters (blur, edge detect) to FPGA fabric

    Pre-processing for machine learning—run Sobel/emboss before feeding a small CNN

    Educational labs—teach line-buffer architectures and MAC pipelines in a single demo

    ASIC prototyping—validate RTL on test silicon, then reuse the same flow for bringing up tape-out

---

🛠 Tool Versions

 1. Icarus Verilog v11.0

 2. Python ≥3.8 with numpy, Pillow, scikit-image, matplotlib

 ---

 🏁 Step-by-Step Usage

Follow these instructions exactly in order to build and run the convolution core:

1. Prepare Your Image

    By default, the Makefile uses cameraman.png in the repo. To use your own picture, copy it into this folder and name it (for example) myphoto.png.

2. Run the Full Flow

    Simply type: make

   This will:

     -Convert cameraman.png → input.hex (128 × 128 grayscale)
  
     -Compile RTL & TB (simv)
  
     -Simulate and produce output.hex
  
     -Render output.hex → output.png

3. View the Result

      Open output.png in your image viewer to see the filtered output.

4. Validate Against Software Reference

      Run the Python validator:
       
      python3 validate_filter.py
   
   A window will pop up showing:
   
      Left: software-computed filter
   
      Center: HDL result
   
      Right: heat-map & red overlay of any pixel mismatches

5. Swap in a different Filter or/and Image

      To use Gaussian blur on the default image: make FILTER=blur
  
      To sharpen your own photo: make FILTER=sharpen IMAGE=myphoto.png
  
      You can also use any combination of filters and images you want.

