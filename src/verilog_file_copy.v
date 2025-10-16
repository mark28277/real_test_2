// Neural Network Hardware Implementation
// Auto-generated from PyTorch model
// Model: SimpleCNN
`timescale 1ns / 1ps

module tt_um_mark28277 (
    input wire clk,
    input wire reset,
    input wire [31:0] input_data [0:3071],
    output wire [31:0] output_data [0:9]
);

    // Internal signals
    // Convolutional Layer 0 signals
    wire [31:0] layer_0_out [0:2047];

    // ReLU Layer 1 signals
    wire [31:0] layer_1_out [0:2047];

    // MaxPool Layer 2 signals
    wire [31:0] layer_2_out [0:2*4*4-1];

    // Linear Layer 3 signals
    wire [31:0] layer_3_out [0:9];


    // Convolutional Layer 0
    conv2d_layer #(
        .IN_CHANNELS(3),
        .OUT_CHANNELS(2),
        .INPUT_HEIGHT(32),
        .INPUT_WIDTH(32),
        .KERNEL_SIZE(3),
        .STRIDE(1),
        .PADDING(1)
    ) conv_0 (
        .clk(clk),
        .reset(reset),
        .input_data(input_data),
        .output_data(layer_0_out)
    );

    // ReLU Activation Layer 1
    relu_layer #(
        .DATA_SIZE(2048)
    ) relu_1 (
        .clk(clk),
        .reset(reset),
        .input_data(layer_0_out),
        .output_data(layer_1_out)
    );

    // MaxPool Layer 2
    maxpool2d_layer #(
        .KERNEL_SIZE(8),
        .STRIDE(8),
        .INPUT_SIZE(32),
        .CHANNELS(2)
    ) maxpool_2 (
        .clk(clk),
        .reset(reset),
        .input_data(layer_1_out),
        .output_data(layer_2_out)
    );

    // Linear Layer 3
    linear_layer #(
        .IN_FEATURES(32),
        .OUT_FEATURES(10)
    ) fc_3 (
        .clk(clk),
        .reset(reset),
        .input_data(layer_2_out),
        .output_data(layer_3_out)
    );

    // Output assignment
    assign output_data = layer_3_out;

endmodule

// ReLU Activation Implementation
module relu_layer #(
    parameter DATA_SIZE
)(
    input wire clk,
    input wire reset,
    input wire [31:0] input_data [0:DATA_SIZE-1],
    output wire [31:0] output_data [0:DATA_SIZE-1]
);

    // Internal signals
    reg [31:0] output_reg [0:DATA_SIZE-1];
    integer i;

    // ReLU computation
    always @(posedge clk) begin
        if (reset) begin
            // Reset output data
            for (i = 0; i < DATA_SIZE; i = i + 1) begin
                output_reg[i] <= 32'b0;
            end
        end else begin
            // Apply ReLU activation element-wise
            for (i = 0; i < DATA_SIZE; i = i + 1) begin
                // ReLU: output = max(0, input)
                if (input_data[i][31] == 1'b0) begin
                    // Positive number - pass through
                    output_reg[i] <= input_data[i];
                end else begin
                    // Negative number - output zero
                    output_reg[i] <= 32'b0;
                end
            end
        end
    end

    // Continuous assignment from internal register to output wire
    genvar k;
    generate
        for (k = 0; k < DATA_SIZE; k = k + 1) begin : output_assign
            assign output_data[k] = output_reg[k];
        end
    endgenerate

endmodule

// Convolutional Layer Implementation
module conv2d_layer #(
    parameter IN_CHANNELS,
    parameter OUT_CHANNELS,
    parameter INPUT_HEIGHT,
    parameter INPUT_WIDTH,
    parameter KERNEL_SIZE,
    parameter STRIDE,
    parameter PADDING
)(
    input wire clk,
    input wire reset,
    input wire [31:0] input_data [0:IN_CHANNELS*INPUT_HEIGHT*INPUT_WIDTH-1],
    output wire [31:0] output_data [0:OUT_CHANNELS*INPUT_HEIGHT*INPUT_WIDTH-1]
);

    // Weight and bias storage (would be loaded from model parameters)
    reg [31:0] weights [0:OUT_CHANNELS-1][0:IN_CHANNELS-1][0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];
    reg [31:0] biases [0:OUT_CHANNELS-1];

    // Internal signals
    reg [31:0] output_reg [0:OUT_CHANNELS*INPUT_HEIGHT*INPUT_WIDTH-1];
    integer oc, ic, i, j, ki, kj;
    integer input_i, input_j;
    reg [31:0] conv_result;

    // Convolution computation
    always @(posedge clk) begin
        if (reset) begin
            // Reset output data
            for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
                for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
                    for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                        output_reg[oc * INPUT_HEIGHT * INPUT_WIDTH + i * INPUT_WIDTH + j] <= 32'b0;
                    end
                end
            end
        end else begin
            // Perform convolution for each output channel
            for (oc = 0; oc < OUT_CHANNELS; oc = oc + 1) begin
                for (i = 0; i < INPUT_HEIGHT; i = i + 1) begin
                    for (j = 0; j < INPUT_WIDTH; j = j + 1) begin
                        conv_result = 32'b0;
                        
                        // Convolution operation
                        for (ic = 0; ic < IN_CHANNELS; ic = ic + 1) begin
                            for (ki = 0; ki < KERNEL_SIZE; ki = ki + 1) begin
                                for (kj = 0; kj < KERNEL_SIZE; kj = kj + 1) begin
                                    // Calculate input indices with padding and stride
                                    input_i = i * STRIDE + ki - PADDING;
                                    input_j = j * STRIDE + kj - PADDING;
                                    
                                    // Check bounds
                                    if (input_i >= 0 && input_i < INPUT_HEIGHT && input_j >= 0 && input_j < INPUT_WIDTH) begin
                                        conv_result = conv_result + 
                                            (input_data[ic * INPUT_HEIGHT * INPUT_WIDTH + input_i * INPUT_WIDTH + input_j] * weights[oc][ic][ki][kj]);
                                    end
                                end
                            end
                        end
                        
                        // Add bias
                        output_reg[oc * INPUT_HEIGHT * INPUT_WIDTH + i * INPUT_WIDTH + j] <= conv_result + biases[oc];
                    end
                end
            end
        end
    end

    // Continuous assignment from internal register to output wire
    genvar k;
    generate
        for (k = 0; k < OUT_CHANNELS*INPUT_HEIGHT*INPUT_WIDTH; k = k + 1) begin : output_assign
            assign output_data[k] = output_reg[k];
        end
    endgenerate

endmodule

// Linear Layer Implementation
module linear_layer #(
    parameter IN_FEATURES,
    parameter OUT_FEATURES
)(
    input wire clk,
    input wire reset,
    input wire [31:0] input_data [0:IN_FEATURES-1],
    output wire [31:0] output_data [0:OUT_FEATURES-1]
);

    // Weight and bias storage
    reg [31:0] weights [0:OUT_FEATURES-1][0:IN_FEATURES-1];
    reg [31:0] biases [0:OUT_FEATURES-1];

    // Internal signals
    reg [31:0] output_reg [0:OUT_FEATURES-1];
    integer i, j;
    reg [31:0] dot_product;

    // Matrix multiplication computation
    always @(posedge clk) begin
        if (reset) begin
            // Reset output data
            for (i = 0; i < OUT_FEATURES; i = i + 1) begin
                output_reg[i] <= 32'b0;
            end
        end else begin
            // Perform matrix multiplication
            for (i = 0; i < OUT_FEATURES; i = i + 1) begin
                dot_product = 32'b0;
                
                // Dot product of weights and input
                for (j = 0; j < IN_FEATURES; j = j + 1) begin
                    dot_product = dot_product + (input_data[j] * weights[i][j]);
                end
                
                // Add bias
                output_reg[i] <= dot_product + biases[i];
            end
        end
    end

    // Continuous assignment from internal register to output wire
    genvar k;
    generate
        for (k = 0; k < OUT_FEATURES; k = k + 1) begin : output_assign
            assign output_data[k] = output_reg[k];
        end
    endgenerate

endmodule

// MaxPooling Layer Implementation
module maxpool2d_layer #(
    parameter KERNEL_SIZE,
    parameter STRIDE,
    parameter INPUT_SIZE,
    parameter CHANNELS
)(
    input wire clk,
    input wire reset,
    input wire [31:0] input_data [0:CHANNELS*INPUT_SIZE*INPUT_SIZE-1],
    output wire [31:0] output_data [0:CHANNELS*(INPUT_SIZE/KERNEL_SIZE)*(INPUT_SIZE/KERNEL_SIZE)-1]
);

    // Internal signals
    reg [31:0] output_reg [0:CHANNELS*(INPUT_SIZE/KERNEL_SIZE)*(INPUT_SIZE/KERNEL_SIZE)-1];
    integer c, i, j, ki, kj;
    integer input_i, input_j, output_i, output_j;
    integer index;
    reg [31:0] max_val;
    reg first_value_found;

    // Max pooling computation
    always @(posedge clk) begin
        if (reset) begin
            // Reset output data
            for (c = 0; c < CHANNELS; c = c + 1) begin
                for (output_i = 0; output_i < INPUT_SIZE/KERNEL_SIZE; output_i = output_i + 1) begin
                    for (output_j = 0; output_j < INPUT_SIZE/KERNEL_SIZE; output_j = output_j + 1) begin
                        output_reg[c * (INPUT_SIZE/KERNEL_SIZE) * (INPUT_SIZE/KERNEL_SIZE) + output_i * (INPUT_SIZE/KERNEL_SIZE) + output_j] <= 32'b0;
                    end
                end
            end
        end else begin
            // Perform max pooling for each channel
            for (c = 0; c < CHANNELS; c = c + 1) begin
                for (output_i = 0; output_i < INPUT_SIZE/KERNEL_SIZE; output_i = output_i + 1) begin
                    for (output_j = 0; output_j < INPUT_SIZE/KERNEL_SIZE; output_j = output_j + 1) begin
                        max_val = 32'h00000000; // Start with zero instead of minimum signed integer
                        first_value_found = 1'b0;
                        
                        // Find maximum value in kernel window
                        for (ki = 0; ki < KERNEL_SIZE; ki = ki + 1) begin
                            for (kj = 0; kj < KERNEL_SIZE; kj = kj + 1) begin
                                input_i = output_i * STRIDE + ki;
                                input_j = output_j * STRIDE + kj;
                                
                                // Check bounds
                                if (input_i < INPUT_SIZE && input_j < INPUT_SIZE) begin
                                    index = c * INPUT_SIZE * INPUT_SIZE + input_i * INPUT_SIZE + input_j;
                                    if (!first_value_found) begin
                                        max_val = input_data[index];
                                        first_value_found = 1'b1;
                                    end else if (input_data[index] > max_val) begin
                                        max_val = input_data[index];
                                    end
                                end
                            end
                        end
                        
                        // If no valid values found, use zero
                        if (!first_value_found) begin
                            max_val = 32'h00000000;
                        end
                        
                        output_reg[c * (INPUT_SIZE/KERNEL_SIZE) * (INPUT_SIZE/KERNEL_SIZE) + output_i * (INPUT_SIZE/KERNEL_SIZE) + output_j] <= max_val;
                    end
                end
            end
        end
    end

    // Continuous assignment from internal register to output wire
    genvar k;
    generate
        for (k = 0; k < CHANNELS*(INPUT_SIZE/KERNEL_SIZE)*(INPUT_SIZE/KERNEL_SIZE); k = k + 1) begin : output_assign
            assign output_data[k] = output_reg[k];
        end
    endgenerate

endmodule
