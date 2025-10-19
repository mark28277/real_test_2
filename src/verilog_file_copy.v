// Neural Network Hardware Implementation
// Auto-generated from PyTorch TorchScript model
// Tiny Tapeout Compatible
`timescale 1ns / 1ps

module tt_um_mark28277 (
    input wire [7:0] ui_in, //(dedicated inputs - connected to the input switches)
    output wire [7:0] uo_out, //(dedicated outputs - connected to the 7 segment display)
    input wire [7:0] uio_in, //(IOs: Bidirectional input path)
    output wire [7:0] uio_out, //(IOs: Bidirectional output path)
    output wire [7:0] uio_oe, //(IOs: Bidirectional enable path (active high: 0=input, 1=output))
    input wire           ena, //(will go high when the design is enabled)
    input wire           clk, //(clock)
    input wire           rst_n //(reset_n - low to reset)
);

    // Input interface for Tiny Tapeout limited I/O
    wire reset;
    assign reset = ~rst_n;

    // Neural network input (simplified for Tiny Tapeout)
    wire [31:0] input_data [0:3071];

    // Simplified input assignment
    // Note: In practice, you'd need a data loading state machine
    genvar i;
    generate
        for (i = 0; i < 3072; i = i + 1) begin : input_assign
            if (i < 8) begin
                assign input_data[i] = {24'b0, ui_in};
            end else if (i < 16) begin
                assign input_data[i] = {24'b0, uio_in};
            end else begin
                assign input_data[i] = 32'b0;
            end
        end
    endgenerate

    // Conv2d Layer 0
    wire [31:0] conv_0_out [0:1];
    conv2d_0 conv_inst_0 (
        .clk(clk),
        .reset(reset),
        .input_data(input_data),
        .output_data(conv_0_out)
    );

    // ReLU Layer 1
    wire [31:0] relu_1_out [0:31];
    relu_1 relu_inst_1 (
        .clk(clk),
        .reset(reset),
        .input_data(conv_0_out),
        .output_data(relu_1_out)
    );

    // MaxPool2d Layer 2
    wire [31:0] maxpool_2_out [0:7];
    maxpool_2 maxpool_inst_2 (
        .clk(clk),
        .reset(reset),
        .input_data(relu_1_out),
        .output_data(maxpool_2_out)
    );

    // Linear Layer 3
    wire [31:0] linear_3_out [0:9];
    linear_3 linear_inst_3 (
        .clk(clk),
        .reset(reset),
        .input_data(maxpool_2_out),
        .output_data(linear_3_out)
    );

    // Final output signal
    wire [31:0] final_output [0:9];
    assign final_output = linear_3_out;

    // Output interface for Tiny Tapeout limited I/O
    reg [7:0] uo_out_reg;
    reg [7:0] uio_out_reg;
    reg [7:0] uio_oe_reg;

    always @(posedge clk) begin
        if (reset) begin
            uo_out_reg <= 8'b0;
            uio_out_reg <= 8'b0;
            uio_oe_reg <= 8'b0;
        end else if (ena) begin
            // Output first element to dedicated output
            uo_out_reg <= final_output[0][7:0];
            // Output second element to bidirectional output
            uio_out_reg <= final_output[1][7:0];
            // Set all IOs as outputs
            uio_oe_reg <= 8'hFF;
        end
    end

    assign uo_out = uo_out_reg;
    assign uio_out = uio_out_reg;
    assign uio_oe = uio_oe_reg;

endmodule

// Simplified ReLU Layer for Tiny Tapeout
module relu_layer #(
    parameter DATA_SIZE = 32
)(
    input wire clk,
    input wire reset,
    input wire [31:0] input_data [0:DATA_SIZE-1],
    output wire [31:0] output_data [0:DATA_SIZE-1]
);

    // Simplified ReLU for Tiny Tapeout
    reg [31:0] output_reg [0:DATA_SIZE-1];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < DATA_SIZE; i = i + 1) begin
                output_reg[i] <= 32'b0;
            end
        end else begin
            // Simplified ReLU operation
            for (i = 0; i < DATA_SIZE; i = i + 1) begin
                if (input_data[i][31] == 1'b0) begin
                    output_reg[i] <= input_data[i];
                end else begin
                    output_reg[i] <= 32'b0;
                end
            end
        end
    end

    // Assign outputs
    genvar k;
    generate
        for (k = 0; k < DATA_SIZE; k = k + 1) begin : output_assign
            assign output_data[k] = output_reg[k];
        end
    endgenerate

endmodule

// Simplified MaxPool Layer for Tiny Tapeout
module maxpool_layer #(
    parameter CHANNELS = 2,
    parameter INPUT_SIZE = 32,
    parameter KERNEL_SIZE = 8
)(
    input wire clk,
    input wire reset,
    input wire [31:0] input_data [0:CHANNELS*INPUT_SIZE*INPUT_SIZE-1],
    output wire [31:0] output_data [0:CHANNELS*(INPUT_SIZE/KERNEL_SIZE)*(INPUT_SIZE/KERNEL_SIZE)-1]
);

    // Simplified maxpool for Tiny Tapeout
    reg [31:0] output_reg [0:CHANNELS*(INPUT_SIZE/KERNEL_SIZE)*(INPUT_SIZE/KERNEL_SIZE)-1];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < CHANNELS*(INPUT_SIZE/KERNEL_SIZE)*(INPUT_SIZE/KERNEL_SIZE); i = i + 1) begin
                output_reg[i] <= 32'b0;
            end
        end else begin
            // Simplified maxpool operation
            for (i = 0; i < CHANNELS*(INPUT_SIZE/KERNEL_SIZE)*(INPUT_SIZE/KERNEL_SIZE); i = i + 1) begin
                output_reg[i] <= input_data[i * KERNEL_SIZE];
            end
        end
    end

    // Assign outputs
    genvar k;
    generate
        for (k = 0; k < CHANNELS*(INPUT_SIZE/KERNEL_SIZE)*(INPUT_SIZE/KERNEL_SIZE); k = k + 1) begin : output_assign
            assign output_data[k] = output_reg[k];
        end
    endgenerate

endmodule

// Simplified Linear Layer for Tiny Tapeout
module linear_layer #(
    parameter IN_FEATURES = 32,
    parameter OUT_FEATURES = 10
)(
    input wire clk,
    input wire reset,
    input wire [31:0] input_data [0:IN_FEATURES-1],
    output wire [31:0] output_data [0:OUT_FEATURES-1]
);

    // Simplified linear layer for Tiny Tapeout
    reg [31:0] output_reg [0:OUT_FEATURES-1];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < OUT_FEATURES; i = i + 1) begin
                output_reg[i] <= 32'b0;
            end
        end else begin
            // Simplified linear operation
            for (i = 0; i < OUT_FEATURES; i = i + 1) begin
                output_reg[i] <= input_data[i % IN_FEATURES] + 32'h00020000;
            end
        end
    end

    // Assign outputs
    genvar k;
    generate
        for (k = 0; k < OUT_FEATURES; k = k + 1) begin : output_assign
            assign output_data[k] = output_reg[k];
        end
    endgenerate

endmodule

// Simplified Conv2d Layer for Tiny Tapeout
module conv2d_layer #(
    parameter IN_CHANNELS = 3,
    parameter OUT_CHANNELS = 2,
    parameter KERNEL_SIZE = 3,
    parameter STRIDE = 1,
    parameter PADDING = 1
)(
    input wire clk,
    input wire reset,
    input wire [31:0] input_data [0:IN_CHANNELS*32*32-1],
    output wire [31:0] output_data [0:OUT_CHANNELS-1]
);

    // Simplified convolution for Tiny Tapeout
    reg [31:0] output_reg [0:OUT_CHANNELS-1];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < OUT_CHANNELS; i = i + 1) begin
                output_reg[i] <= 32'b0;
            end
        end else begin
            // Simplified convolution operation
            for (i = 0; i < OUT_CHANNELS; i = i + 1) begin
                output_reg[i] <= input_data[i % IN_CHANNELS] + 32'h00010000;
            end
        end
    end

    // Assign outputs
    genvar k;
    generate
        for (k = 0; k < OUT_CHANNELS; k = k + 1) begin : output_assign
            assign output_data[k] = output_reg[k];
        end
    endgenerate

endmodule
