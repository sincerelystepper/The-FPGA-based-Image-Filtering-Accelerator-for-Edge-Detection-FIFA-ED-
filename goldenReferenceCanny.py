import cv2
import numpy as np
import pandas as pd

# === CONFIGURATION ===
INPUT_IMAGE = 'queen4.jpg'
FPGA_CANNY_OUT = 'edge_output.csv'  # Changed to reflect Canny output
IMAGE_SIZE = (128, 128)  # height, width

# Canny thresholds (should match your FPGA implementation)
LOW_THRESHOLD = 75
HIGH_THRESHOLD = 150

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

def generate_reference_canny(image_path):
    """Generate Canny edge detection output from OpenCV."""
    img = cv2.imread(image_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        raise FileNotFoundError(f"Input image not found: {image_path}")

    # Resize to match FPGA output
    img = cv2.resize(img, (IMAGE_SIZE[1], IMAGE_SIZE[0]))

    # Apply Gaussian blur (recommended before Canny)
    img_blur = cv2.GaussianBlur(img, (3, 3), 0) # 3x3 gaussian kernel on the input images for removing the noise

    # Apply Canny edge detection
    canny = cv2.Canny(img_blur, LOW_THRESHOLD, HIGH_THRESHOLD) # takes in the two thresholds 
    
    return canny

def compare_outputs(fpga_csv, golden_image, label="Canny"):
    """Compare FPGA output to golden reference."""
    fpga_output = load_fpga_output(fpga_csv)

    # For Canny, we should compare binary outputs
    fpga_binary = (fpga_output > 0).astype(np.uint8) * 255
    golden_binary = (golden_image > 0).astype(np.uint8) * 255

    # Compute absolute difference
    diff = cv2.absdiff(fpga_binary, golden_binary)
    incorrect_pixels = np.count_nonzero(diff)
    total_pixels = diff.size
    accuracy = 100.0 * (total_pixels - incorrect_pixels) / total_pixels

    print(f"{label} Comparison:")
    print(f"  Total Pixels     : {total_pixels}")
    print(f"  Incorrect Pixels : {incorrect_pixels}")
    print(f"  Accuracy         : {accuracy:.2f}%")

    # Combine the images side-by-side
    combined = np.hstack((golden_binary, fpga_binary, diff))

    # === SHOW side-by-side image directly ===
    cv2.namedWindow("Comparison", cv2.WINDOW_AUTOSIZE)
    cv2.imshow("Comparison:    Golden   |   FPGA   |   Diff", combined)

    cv2.waitKey(0)
    cv2.destroyAllWindows()

    return accuracy, diff

if __name__ == "__main__":
    print("Generating golden reference Canny image using OpenCV...")
    canny_ref = generate_reference_canny(INPUT_IMAGE)

    print("Comparing FPGA output to golden reference...")
    canny_acc, canny_diff = compare_outputs(FPGA_CANNY_OUT, canny_ref, label="Canny")