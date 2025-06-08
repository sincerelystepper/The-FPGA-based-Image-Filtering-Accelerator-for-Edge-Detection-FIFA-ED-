import cv2
import numpy as np
import pandas as pd

# === CONFIGURATION ===
INPUT_IMAGE = 'queen4.jpg'
FPGA_SOBEL_OUT = 'sobel_output_fixed.csv'  # Output from your Sobel testbench
IMAGE_SIZE = (128, 128)  # height, width

def load_fpga_output(fpga_csv):
    """Load and reshape FPGA output from CSV."""
    # Skip header, load data
    data = pd.read_csv(fpga_csv, header=0).values.astype(np.uint8)

    # Flattened to 1D? Reshape to image
    if data.shape[0] == IMAGE_SIZE[0] * IMAGE_SIZE[1]:
        image = data.reshape(IMAGE_SIZE)
    elif data.shape[1] == 1 and data.shape[0] == IMAGE_SIZE[0] * IMAGE_SIZE[1]:
        image = data.reshape(IMAGE_SIZE)
    else:
        raise ValueError(f"Unexpected data shape {data.shape} for FPGA output.")

    # === FIX ROTATION HERE ===
    image = np.rot90(image, k=3)  # Rotate 90° clockwise

    return image

def generate_reference_sobel(image_path):
    """Generate Sobel edge detection output from OpenCV."""
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        raise FileNotFoundError(f"Input image not found: {image_path}")

    # Resize to match FPGA output
    img = cv2.resize(img, (IMAGE_SIZE[1], IMAGE_SIZE[0]))

    # Apply Sobel operators (X and Y directions)
    sobel_x = cv2.Sobel(img, cv2.CV_16S, 1, 0, ksize=3)
    sobel_y = cv2.Sobel(img, cv2.CV_16S, 0, 1, ksize=3)

    # Convert to absolute values and combine
    abs_sobel_x = cv2.convertScaleAbs(sobel_x)
    abs_sobel_y = cv2.convertScaleAbs(sobel_y)
    
    # Combine both directions (approximate magnitude)
    sobel_combined = cv2.addWeighted(abs_sobel_x, 0.5, abs_sobel_y, 0.5, 0)
    
    return sobel_combined

def compare_outputs(fpga_csv, golden_image, label="Sobel"):
    """Compare FPGA output to golden reference."""
    fpga_output = load_fpga_output(fpga_csv)

    # Compute absolute difference (for gradient magnitudes)
    diff = cv2.absdiff(fpga_output, golden_image)
    
    # Calculate accuracy metrics
    incorrect_pixels = np.count_nonzero(diff > 10)  # Using threshold of 10 for gradient differences
    total_pixels = diff.size
    accuracy = 100.0 * (total_pixels - incorrect_pixels) / total_pixels

    print(f"{label} Comparison:")
    print(f"  Total Pixels     : {total_pixels}")
    print(f"  Incorrect Pixels : {incorrect_pixels} (difference > 10)")
    print(f"  Accuracy         : {accuracy:.2f}%")

    # Normalize images for display
    fpga_norm = cv2.normalize(fpga_output, None, 0, 255, cv2.NORM_MINMAX)
    golden_norm = cv2.normalize(golden_image, None, 0, 255, cv2.NORM_MINMAX)
    diff_norm = cv2.normalize(diff, None, 0, 255, cv2.NORM_MINMAX)

    # Combine the images side-by-side
    combined = np.hstack((golden_norm, fpga_norm, diff_norm))

    # === SHOW side-by-side image directly ===
    cv2.namedWindow("Comparison", cv2.WINDOW_AUTOSIZE)
    cv2.imshow(f"Comparison:    Golden {label}   |   FPGA {label}   |   Diff", combined)

    cv2.waitKey(0)
    cv2.destroyAllWindows()

    return accuracy, diff

if __name__ == "__main__":
    print("Generating golden reference Sobel image using OpenCV...")
    sobel_ref = generate_reference_sobel(INPUT_IMAGE)

    print("Comparing FPGA output to golden reference...")
    sobel_acc, sobel_diff = compare_outputs(FPGA_SOBEL_OUT, sobel_ref, label="Sobel")