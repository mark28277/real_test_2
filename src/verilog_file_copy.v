// Neural Network Hardware Implementation
// Auto-generated from PyTorch TorchScript model
// Tiny Tapeout Compatible - Packed Arrays Only
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

    // Neural network input (8-bit for Tiny Tapeout)
    wire [7:0] input_data;
    assign input_data = ui_in; // Use dedicated input directly

    // Conv2d Layer 0
    wire [7:0] conv_0_out;
    conv2d_layer conv_inst_0 (
        .clk(clk),
        .reset(reset),
        .input_data(input_data),
        .output_data(conv_0_out)
    );

    // ReLU Layer 1
    wire [7:0] relu_1_out;
    relu_layer relu_inst_1 (
        .clk(clk),
        .reset(reset),
        .input_data(conv_0_out),
        .output_data(relu_1_out)
    );

    // MaxPool2d Layer 2
    wire [7:0] maxpool_2_out;
    maxpool_layer maxpool_inst_2 (
        .clk(clk),
        .reset(reset),
        .input_data(relu_1_out),
        .output_data(maxpool_2_out)
    );

    // Linear Layer 3
    wire [7:0] linear_3_out;
    linear_layer linear_inst_3 (
        .clk(clk),
        .reset(reset),
        .input_data(maxpool_2_out),
        .output_data(linear_3_out)
    );

    // Final output signal
    wire [7:0] final_output;
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
            // Output final result to dedicated output
            uo_out_reg <= final_output;
            // Output inverted result to bidirectional output
            uio_out_reg <= ~final_output;
            // Set all IOs as outputs
            uio_oe_reg <= 8'hFF;
        end
    end

    assign uo_out = uo_out_reg;
    assign uio_out = uio_out_reg;
    assign uio_oe = uio_oe_reg;

endmodule

// Simplified Conv2d Layer for Tiny Tapeout
module conv2d_layer (
    input wire clk,
    input wire reset,
    input wire [7:0] input_data,
    output wire [7:0] output_data
);

    // Simplified convolution for Tiny Tapeout
    reg [7:0] output_reg;

    always @(posedge clk) begin
        if (reset) begin
            output_reg <= 8'b0;
        end else begin
            // Simplified convolution operation
            output_reg <= input_data + 8'h10;
        end
    end

    assign output_data = output_reg;

endmodule

// Simplified Linear Layer for Tiny Tapeout
module linear_layer (
    input wire clk,
    input wire reset,
    input wire [7:0] input_data,
    output wire [7:0] output_data
);

    // Simplified linear layer for Tiny Tapeout
    reg [7:0] output_reg;

    always @(posedge clk) begin
        if (reset) begin
            output_reg <= 8'b0;
        end else begin
            // Simplified linear operation
            output_reg <= input_data + 8'h20;
        end
    end

    assign output_data = output_reg;

endmodule

// Simplified ReLU Layer for Tiny Tapeout
module relu_layer (
    input wire clk,
    input wire reset,
    input wire [7:0] input_data,
    output wire [7:0] output_data
);

    // Simplified ReLU for Tiny Tapeout
    reg [7:0] output_reg;

    always @(posedge clk) begin
        if (reset) begin
            output_reg <= 8'b0;
        end else begin
            // Simplified ReLU operation
            if (input_data[7] == 1'b0) begin
                output_reg <= input_data;
            end else begin
                output_reg <= 8'b0;
            end
        end
    end

    assign output_data = output_reg;

endmodule

// Simplified MaxPool Layer for Tiny Tapeout
module maxpool_layer (
    input wire clk,
    input wire reset,
    input wire [7:0] input_data,
    output wire [7:0] output_data
);

    // Simplified maxpool for Tiny Tapeout
    reg [7:0] output_reg;

    always @(posedge clk) begin
        if (reset) begin
            output_reg <= 8'b0;
        end else begin
            // Simplified maxpool operation
            output_reg <= input_data; // Pass through for simplicity
        end
    end

    assign output_data = output_reg;

endmodule
