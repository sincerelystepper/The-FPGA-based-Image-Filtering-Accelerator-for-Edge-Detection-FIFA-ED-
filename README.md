# FIFA-ED: FPGA-based Image Filtering Accelerator for Edge Detection

[![License: LGPL v2.1](https://img.shields.io/badge/License-LGPL_v2.1-blue.svg)](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html)
[![Toolchain: Vivado](https://img.shields.io/badge/Toolchain-Xilinx_Vivado-orange.svg)](https://www.xilinx.com/products/design-tools/vivado.html)
[![Language: SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)](https://ieeexplore.ieee.org/document/8299595)
[![Algorithm: Canny](https://img.shields.io/badge/Algorithm-Canny_%2F_Sobel-green.svg)](https://en.wikipedia.org/wiki/Canny_edge_detector)

> **A high-performance SystemVerilog accelerator designed for real-time edge detection, transitioning from basic Sobel operators to a full Canny-inspired $5 \times 5$ Gaussian-filtered pipeline.**

---

##  Mission
Real-time image processing at the edge is computationally expensive for general-purpose CPUs. **FIFA-ED** solves this by offloading heavy spatial convolutions to FPGA fabric. By implementing a hardware-accelerated Canny edge detection pipeline—complete with a $5 \times 5$ Gaussian kernel—this project achieves significant throughput improvements over software-only solutions, providing smoother, noise-resilient edge maps suitable for industrial automation and computer vision.

##  System Architecture
The accelerator is built as a highly optimized pipeline in SystemVerilog, validated against a Python-based OpenCV "Golden Reference."

* **Preprocessing Subsystem (MATLAB/Python):**
    * **RGB to Grayscale Conversion:** Initial fixed-point conversion scripts to prep raw image data for hardware ingestion.
    * **Golden Reference Models:** Python implementations of Sobel and Canny algorithms used as the ground truth for hardware output verification.
* **FPGA Accelerator Core (SystemVerilog):**
    * **Gaussian Filtering Engine:** Implements a $5 \times 5$ kernel convolution. Unlike standard $3 \times 3$ filters, this provides superior noise suppression before the edge detection stage.
    * **Sobel Operator Core:** Computes the gradient magnitude ($G$) and direction ($\Theta$) using optimized parallel compute units for $G_x$ and $G_y$.
    * **Pipelined Line Buffers:** Efficient use of Block RAM (BRAM) to store pixel rows, enabling sliding window convolutions without redundant memory access.
* **Verification Suite:**
    * **SystemVerilog Testbenches:** Uses automated test vectors derived from Python/MATLAB outputs to ensure bit-perfect hardware implementation.

##  Engineering Highlights
* **Advanced Spatial Filtering:** Transitioning from Sobel to Canny required the implementation of a $5 \times 5$ Gaussian kernel. This increases hardware complexity but significantly reduces false-edge detection caused by high-frequency noise.
* **Hardware-Software Co-Design:** The project utilizes a rigorous validation workflow: **MATLAB/Python (Algorithmic) ➔ SystemVerilog (RTL) ➔ Vivado (Synthesis/Implementation).**
* **Parallel Gradient Computation:** Gradient calculations are unrolled in the hardware fabric, allowing the system to process pixels in a streaming fashion, theoretically limited only by the clock frequency and memory bandwidth.
* **Optimized Resource Utilization:** Focused on minimizing DSP slice usage by leveraging shift-and-add operations for fixed-point kernel coefficients where applicable.

##  Technical Stack
* **Hardware Description:** SystemVerilog (RTL)
* **Design Tools:** Xilinx Vivado
* **Algorithmic Validation:** Python (OpenCV), MATLAB
* **Filtering Kernel:** $5 \times 5$ Gaussian + Sobel Gradient
* **Target:** FPGA-based Edge Computing

##  Getting Started

### Prerequisites
* **Xilinx Vivado** (2020.1 or later recommended)
* **Python 3.x** (with `opencv-python` and `numpy`)
* **MATLAB** (optional, for `.mlx` live script analysis)

### Installation & Simulation
1. **Clone the repository:**
   ```bash
   git clone [https://github.com/sincerelystepper/The-FPGA-based-Image-Filtering-Accelerator-for-Edge-Detection-FIFA-ED-.git](https://github.com/sincerelystepper/The-FPGA-based-Image-Filtering-Accelerator-for-Edge-Detection-FIFA-ED-.git)
   cd The-FPGA-based-Image-Filtering-Accelerator-for-Edge-Detection-FIFA-ED-
