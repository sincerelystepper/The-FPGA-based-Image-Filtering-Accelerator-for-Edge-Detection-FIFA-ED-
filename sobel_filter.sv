`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EEE4120F
// Engineer: KOPANO MAKETEKETE
// 
// Create Date: 13.05.2025
// Design Name: Canny Filter Design, with a Sobel moduel
// Module Name: sobel_filter
// Description: 2D Sobel filter for 1D stream input (128-pixel-wide image)
//              Includes Non-Maximum Suppression (NMS) logic and Hysteresis Thresholding
//////////////////////////////////////////////////////////////////////////////////

module sobel_filter(
    input  logic        clk,
    input  logic        rst,
    input  logic [7:0]  pixel_data,
    output logic [7:0]  edge_pixel,
    output logic        edge_valid
);
    parameter IMG_WIDTH = 128;

    // Thresholds
    parameter logic [10:0] HIGH_THRESHOLD = 11'd150;
    parameter logic [10:0] LOW_THRESHOLD  = 11'd75;

    // Buffers
    logic [7:0]  line_buf0 [0:IMG_WIDTH-1];
    logic [7:0]  line_buf1 [0:IMG_WIDTH-1];
    logic [7:0]  line_buf2 [0:IMG_WIDTH-1];

    logic [10:0] grad_buf0 [0:IMG_WIDTH-1];
    logic [10:0] grad_buf1 [0:IMG_WIDTH-1];

    logic [1:0] edge_class_buf0 [0:IMG_WIDTH-1];  // 0=none, 1=weak, 2=strong
    logic [1:0] edge_class_buf1 [0:IMG_WIDTH-1];

    // Loop variables
    integer i;
    logic [6:0] col_idx;
    integer col, row;

    // Window and gradients
    logic [7:0] window[0:8];
    logic [7:0] left, mid, right;
    logic signed [10:0] grad_x, grad_y;
    logic signed [10:0] gx_abs, gy_abs;
    logic [10:0] grad_abs;

    logic [1:0] dir;
    logic [10:0] mag1, mag2;

    logic [1:0] edge_class; // 0=none, 1=weak, 2=strong

    assign edge_valid = (row >= 2 && col >= 2);
    assign edge_pixel = (edge_class == 2'd2 || edge_class == 2'd1) ? 
                        ((grad_abs > 11'd255) ? 8'd255 : grad_abs[7:0]) : 
                        8'd0;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            col <= 0;
            row <= 0;
            for (i = 0; i < IMG_WIDTH; i++) begin
                line_buf0[i] <= 0;
                line_buf1[i] <= 0;
                line_buf2[i] <= 0;
                grad_buf0[i] <= 0;
                grad_buf1[i] <= 0;
                edge_class_buf0[i] <= 0;
                edge_class_buf1[i] <= 0;
            end
        end else begin
            line_buf2[col] <= pixel_data;
            grad_buf1[col] <= grad_abs;
            edge_class_buf1[col] <= edge_class;

            if (col == IMG_WIDTH - 1) begin
                for (i = 0; i < IMG_WIDTH; i++) begin
                    line_buf0[i] <= line_buf1[i];
                    line_buf1[i] <= line_buf2[i];

                    grad_buf0[i] <= grad_buf1[i];
                    grad_buf1[i] <= 0;

                    edge_class_buf0[i] <= edge_class_buf1[i];
                    edge_class_buf1[i] <= 0;
                end
                row <= row + 1;
            end
            col <= (col == IMG_WIDTH - 1) ? 0 : col + 1;
        end
    end

    always_comb begin
        grad_x = 0; grad_y = 0; grad_abs = 0;
        gx_abs = 0; gy_abs = 0;
        mag1 = 0; mag2 = 0; dir = 0;
        edge_class = 0;

        if (row >= 2 && col >= 2) begin
            col_idx = col;
            left  = (col_idx > 1)             ? col_idx - 2 : 0;
            mid   = (col_idx > 0)             ? col_idx - 1 : 0;
            right = (col_idx < IMG_WIDTH - 1) ? col_idx     : IMG_WIDTH - 1;

            window[0] = line_buf0[left];
            window[1] = line_buf0[mid];
            window[2] = line_buf0[right];
            window[3] = line_buf1[left];
            window[4] = line_buf1[mid];
            window[5] = line_buf1[right];
            window[6] = line_buf2[left];
            window[7] = line_buf2[mid];
            window[8] = line_buf2[right];

            grad_x = (
                -$signed(window[0]) + $signed(window[2])
              - 2*$signed(window[3]) + 2*$signed(window[5])
              - $signed(window[6]) + $signed(window[8])
            );

            grad_y = (
                $signed(window[0]) + 2*$signed(window[1]) + $signed(window[2])
              - $signed(window[6]) - 2*$signed(window[7]) - $signed(window[8])
            );

            gx_abs = (grad_x < 0) ? -grad_x : grad_x;
            gy_abs = (grad_y < 0) ? -grad_y : grad_y;
            grad_abs = gx_abs + gy_abs;

            if (gy_abs <= gx_abs >>> 1)         dir = 2'd0;
            else if (gx_abs <= gy_abs >>> 1)    dir = 2'd1;
            else if ((grad_x * grad_y) > 0)     dir = 2'd2;
            else                                dir = 2'd3;

            case (dir)
                2'd0: begin mag1 = grad_buf1[(mid > 0) ? mid - 1 : 0];
                            mag2 = grad_buf1[(mid < IMG_WIDTH - 1) ? mid + 1 : IMG_WIDTH - 1]; end
                2'd1: begin mag1 = grad_buf0[mid]; mag2 = 0; end
                2'd2: begin mag1 = grad_buf0[(mid < IMG_WIDTH - 1) ? mid + 1 : IMG_WIDTH - 1]; mag2 = 0; end
                2'd3: begin mag1 = grad_buf0[(mid > 0) ? mid - 1 : 0]; mag2 = 0; end
            endcase

            // NMS logic (Non-Maximum Suppression) 
            if (grad_abs >= mag1 && grad_abs >= mag2) begin
                // Hysteresis classification
                if (grad_abs >= HIGH_THRESHOLD) begin
                    edge_class = 2; // strong
                end else if (grad_abs >= LOW_THRESHOLD) begin
                    // check if any neighbor is strong
                    if (edge_class_buf0[(mid > 0) ? mid - 1 : 0] == 2 ||
                        edge_class_buf0[mid] == 2 ||
                        edge_class_buf0[(mid < IMG_WIDTH - 1) ? mid + 1 : IMG_WIDTH - 1] == 2) begin
                        edge_class = 1; // weak but connected to strong
                    end else begin
                        edge_class = 0; // weak and isolated
                    end
                end else begin
                    edge_class = 0; // below low threshold
                end
            end
        end
    end
endmodule
