# 3×3 Image-Convolution Core (Verilog + Python Validation)

A minimal-area, 1-pixel/clk spatial-filter engine for FPGA or ASIC, complete with:

- **Verilog RTL** for a streaming 3×3 convolution core  
- **Self-checking testbench** (memory-based, parameterisable)  
- **Makefile** flow: clean → build → simulate → render PNG  
- **Kernel library** (`kernels/*.hex`) for blur, sharpen, emboss, Sobel, outline…  
- **Python scripts** for PNG↔HEX conversion and SW vs HDL validation (SSIM, heat-map, overlay)

---

## 🎯 Project Goal

Implement classic 3×3 image filters (Gaussian blur, sharpen, Sobel edges…) in hardware with:

- **Maximum throughput**: one output pixel per clock  
- **Minimal area**: single multiplier reused for 9 MACs, three line-buffers only  
- **Runtime flexibility**: swap filters by loading different `*.hex` files—no RTL resynthesis  
- **End-to-end verification**: compare RTL output against Python reference using SSIM and visual overlays  

---

## 🔍 How It Works

1. **Image storage**: your 128×128 grayscale frame is preloaded into `image_mem` (Verilog register file).  
2. **Streaming FSM**: on a one-clk `start` pulse, an FSM (`LOAD → MAC → STORE`) steps through each valid pixel (rows/cols 1…126), reading a 3×3 window via three line-buffers.  
3. **MAC engine**: a single signed-multiplier accumulates 9 tap products into an 18-bit accumulator, then right-shifts by `norm_shift` and clips the result to 0…255.  
4. **Output storage**: each result pixel is written back to `out_mem` at one-pixel/clk.  
5. **Testbench**: loads `input.hex` into `image_mem`, pulses `start`, waits for `done`, dumps `out_mem` to `output.hex`.  
6. **Python validation**: `hex_to_img.py` renders `output.hex` into `output.png`; `validate_overlay.py` runs the same 3×3 filter in software, computes SSIM, heat-map of |SW–HDL|, and an RGB overlay highlighting any mismatches in red.

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

