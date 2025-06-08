`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: EEE4120F
// Engineer: KOPANO MAKETEKETE
// 
// Create Date: 13.05.2025
// Design Name: Sobel Filter Testbench (CSV Input)
// Module Name: sobel_filter_tb
//////////////////////////////////////////////////////////////////////////////////

module sobel_filter_tb;

    // Clock and reset
    logic clk = 0;
    logic rst;

    // Pixel I/O
    logic [7:0] pixel_data;
    logic [7:0] edge_pixel;
    logic       edge_valid;

    // Instantiate the DUT
    sobel_filter uut (
        .clk(clk),
        .rst(rst),
        .pixel_data(pixel_data),
        .edge_pixel(edge_pixel),
        .edge_valid(edge_valid)
    );

    // Clock generation: 10ns period
    always #5 clk = ~clk;

    // Memory for image data (8-bit pixels)
    integer num_pixels = 0;
    byte pixel_mem[];

    // File reading/writing vars
    integer file, r, i;
    integer output_file;
    integer dummy;

    // Track progress
    integer write_count = 0;

    initial begin
        $display("=== Starting Sobel Filter Testbench ===");

        // Open the CSV file for reading
        file = $fopen("C:/Users/Sincerely Stepper/Desktop/EEE4120F/YODA_Edge_Detection/flattened_image_128x128.csv", "r");
        if (file == 0) begin
            $display("ERROR: Could not open flattened_image_128x128.csv");
            $finish;
        end

        // First Pass: Count pixels
        while (!$feof(file)) begin
            r = $fscanf(file, "%d,", dummy);
            if (r != 0) num_pixels++;
        end
        $rewind(file);

        // Allocate memory
        pixel_mem = new[num_pixels];
        $display("[%0t] Allocated dynamic array with %0d pixels", $time, num_pixels);

        // Second Pass: Load data
        i = 0;
        while (!$feof(file) && i < num_pixels) begin
            r = $fscanf(file, "%d,", dummy);
            if (r != 0) begin
                pixel_mem[i] = dummy;
                i++;
            end
        end
        $fclose(file);

        $display("[%0t] Loaded %0d pixels from CSV", $time, num_pixels);

        // Debug: print first few pixels
        for (i = 0; i < (num_pixels < 10 ? num_pixels : 10); i++) begin
            $display("pixel_mem[%0d] = %0d", i, pixel_mem[i]);
        end

        // Open output file
        output_file = $fopen("C:/Users/Sincerely Stepper/Desktop/EEE4120F/YODA_Edge_Detection/edge_output.csv", "w"); //output here
        if (output_file == 0) begin
            $display("ERROR: Could not open edge_output.csv");
            $finish;
        end
        $fwrite(output_file, "Edge Pixels\n");

        // Reset and initialization
        clk = 0;
        rst = 1;
        pixel_data = 0;
        #20;
        rst = 0;
        repeat (5) @(posedge clk);
        $display("[%0t] Reset deasserted", $time);

        // Sequentially feed pixels and collect outputs
        write_count = 0;
        for (i = 0; i < num_pixels; i++) begin
            @(posedge clk);
            pixel_data = pixel_mem[i];
            $display("[%0t] Feeding pixel[%0d] = %0d", $time, i, pixel_data);

            // Wait until valid output is ready
            wait (edge_valid == 1);
            $display("[%0t] edge_valid asserted, writing output: %0d", $time, edge_pixel);

            // Write to file
            $fwrite(output_file, "%d\n", edge_pixel);
            $fflush(output_file);
            write_count++;
        end

        // Stop feeding
        @(posedge clk);
        pixel_data = 0;

        // Allow final output to flush
        repeat (10) @(posedge clk);

        // Wrap up
        $display("[%0t] All pixels processed. Total written: %0d", $time, write_count);
        $fclose(output_file);
        $display("=== Finished Writing to edge_output.csv ===");
        $finish;
    end

endmodule
