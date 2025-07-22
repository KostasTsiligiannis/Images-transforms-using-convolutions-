#!/usr/bin/python3

from PIL import Image
import numpy as np
import sys

def image_to_hex(image_path, output_file, size=(128, 128)):
    img = Image.open(image_path).convert('L')  # Grayscale
    img = img.resize(size)
    arr = np.array(img)

    with open(output_file, 'w') as f:
        for row in arr:
            for pixel in row:
                f.write(f"{pixel:02X}\n")

if __name__ == "__main__":
    image_to_hex(sys.argv[1], "input.hex")
