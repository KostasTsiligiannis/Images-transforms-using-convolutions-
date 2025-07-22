#!/usr/bin/python3
from PIL import Image
import numpy as np
import sys

def hex_to_image(hex_file, output_image, size=(128, 128)):
    with open(hex_file, 'r') as f:
        lines = f.readlines()
        data = [int(line.strip(), 16) for line in lines if not line.strip().startswith('//')]
        img = np.array(data, dtype=np.uint8).reshape(size)
        Image.fromarray(img).save(output_image)

def read_hex_image_signed(filename, height, width):
    with open(filename, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]
    flat = []
    for x in lines:
        val = int(x, 16)
        if val >= 32768:
            val -= 65536
        flat.append(np.clip(val, 0, 255))  # safe clipping
    return np.array(flat, dtype=np.uint8).reshape((height, width))

if __name__ == "__main__":
    hex_to_image(sys.argv[1], sys.argv[2])
