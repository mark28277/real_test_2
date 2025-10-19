// Neural Network Hardware Implementation
// Auto-generated from PyTorch model
// Model: SimpleCNN
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

    // Internal signals
    wire reset;
    assign reset = ~rst_n;

    // Neural network input/output signals
    wire [31:0] input_data [3071:0];
    wire [31:0] output_data [9:0];

    // Input data assignment from 8-bit ports
    // Note: This is a simplified interface - in practice you'd need
    // a more sophisticated data loading mechanism
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

    // FIXED Output assignment to 8-bit ports
    reg [7:0] uo_out_reg;
    reg [7:0] uio_out_reg;
    reg [7:0] uio_oe_reg;

    // Connect layer_3_out to output_data using generate loop
    genvar out_idx;
    generate
        for (out_idx = 0; out_idx < 10; out_idx = out_idx + 1) begin : output_assign
            assign output_data[out_idx] = layer_3_out[out_idx];
        end
    endgenerate

    always @(posedge clk) begin
        if (reset) begin
            uo_out_reg <= 8'b0;
            uio_out_reg <= 8'b0;
            uio_oe_reg <= 8'b0;
        end else if (ena) begin
            // Add safety check to avoid Z states
            if (layer_3_out[0] === 32'bz) begin
                uo_out_reg <= 8'hAA;  // Fallback value
            end else begin
                uo_out_reg <= layer_3_out[0][7:0];  // Use direct connection
            end
            
            if (layer_3_out[1] === 32'bz) begin
                uio_out_reg <= 8'h55;  // Fallback value  
            end else begin
                uio_out_reg <= layer_3_out[1][7:0];  // Use direct connection
            end
            
            uio_oe_reg <= 8'hFF; // Set all IOs as outputs
        end
    end

    assign uo_out = uo_out_reg;
    assign uio_out = uio_out_reg;
    assign uio_oe = uio_oe_reg;

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
    input wire [8191:0] input_data,    // Single dimension only for Tiny Tapeout
    output wire [1023:0] output_data     // Single dimension only for Tiny Tapeout
);

    // Internal signals
    reg [31:0] output_reg [CHANNELS*(INPUT_SIZE/KERNEL_SIZE)*(INPUT_SIZE/KERNEL_SIZE)-1:0];
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
    input wire [8191:0] input_data,    // Single dimension only for Tiny Tapeout
    output wire [8191:0] output_data     // Single dimension only for Tiny Tapeout
);

    // Weight and bias storage with actual trained weights
    reg [31:0] weights [0:OUT_CHANNELS-1][0:IN_CHANNELS-1][0:KERNEL_SIZE-1][0:KERNEL_SIZE-1];
    reg [31:0] biases [0:OUT_CHANNELS-1];

    // Weight initialization from trained model
    initial begin
        weights[0][0][0][0] = 32'h000018be;
        weights[0][0][0][1] = 32'h00002425;
        weights[0][0][0][2] = 32'h00002b04;
        weights[0][0][1][0] = 32'h000024c3;
        weights[0][0][1][1] = 32'h00001b87;
        weights[0][0][1][2] = 32'h000011e5;
        weights[0][0][2][0] = 32'hffffd9dc;
        weights[0][0][2][1] = 32'hfffff6d0;
        weights[0][0][2][2] = 32'h000011c8;
        weights[0][1][0][0] = 32'h000021ab;
        weights[0][1][0][1] = 32'hfffffd8f;
        weights[0][1][0][2] = 32'hffffd700;
        weights[0][1][1][0] = 32'h00002139;
        weights[0][1][1][1] = 32'hffffe634;
        weights[0][1][1][2] = 32'hffffda05;
        weights[0][1][2][0] = 32'h00001e9d;
        weights[0][1][2][1] = 32'h0000282e;
        weights[0][1][2][2] = 32'h000028c6;
        weights[0][2][0][0] = 32'h00002679;
        weights[0][2][0][1] = 32'hffffe384;
        weights[0][2][0][2] = 32'hffffded3;
        weights[0][2][1][0] = 32'hffffec87;
        weights[0][2][1][1] = 32'hfffffdc7;
        weights[0][2][1][2] = 32'h00002894;
        weights[0][2][2][0] = 32'hfffffe3c;
        weights[0][2][2][1] = 32'hffffd1c1;
        weights[0][2][2][2] = 32'h000018f4;
        weights[1][0][0][0] = 32'hfffff929;
        weights[1][0][0][1] = 32'h00001962;
        weights[1][0][0][2] = 32'h00001a5c;
        weights[1][0][1][0] = 32'hfffff1e7;
        weights[1][0][1][1] = 32'hffffe696;
        weights[1][0][1][2] = 32'hffffd259;
        weights[1][0][2][0] = 32'hfffff3a8;
        weights[1][0][2][1] = 32'h00000172;
        weights[1][0][2][2] = 32'hffffddba;
        weights[1][1][0][0] = 32'h000011f4;
        weights[1][1][0][1] = 32'h000006a1;
        weights[1][1][0][2] = 32'h000014ad;
        weights[1][1][1][0] = 32'h00002a06;
        weights[1][1][1][1] = 32'hfffffdb2;
        weights[1][1][1][2] = 32'hffffe873;
        weights[1][1][2][0] = 32'hffffda79;
        weights[1][1][2][1] = 32'h0000177e;
        weights[1][1][2][2] = 32'hfffff8e2;
        weights[1][2][0][0] = 32'hfffff360;
        weights[1][2][0][1] = 32'hffffe092;
        weights[1][2][0][2] = 32'h00001ab8;
        weights[1][2][1][0] = 32'h00001579;
        weights[1][2][1][1] = 32'hffffebb1;
        weights[1][2][1][2] = 32'hffffe6bd;
        weights[1][2][2][0] = 32'hfffffad0;
        weights[1][2][2][1] = 32'hfffff030;
        weights[1][2][2][2] = 32'h000000ac;
    end

    // Bias initialization from trained model
    initial begin
        biases[0] = 32'h000023d4;
        biases[1] = 32'hffffefd8;
    end

    // Internal signals
    reg [31:0] output_reg [OUT_CHANNELS*INPUT_HEIGHT*INPUT_WIDTH-1:0];
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
    input wire [1023:0] input_data,    // Single dimension only for Tiny Tapeout
    output wire [63:0] output_data     // Single dimension only for Tiny Tapeout
);

    // Weight and bias storage with actual trained weights
    reg [31:0] weights [0:OUT_FEATURES-1][0:IN_FEATURES-1];
    reg [31:0] biases [0:OUT_FEATURES-1];

    // Weight initialization from trained model
    initial begin
        weights[0][0] = 32'hffffecfc;
        weights[0][1] = 32'h000014f5;
        weights[0][2] = 32'h000027cd;
        weights[0][3] = 32'hffffdc8e;
        weights[0][4] = 32'hffffe099;
        weights[0][5] = 32'hffffd961;
        weights[0][6] = 32'hffffd43d;
        weights[0][7] = 32'hfffff113;
        weights[0][8] = 32'h0000122b;
        weights[0][9] = 32'h0000161e;
        weights[0][10] = 32'h00000388;
        weights[0][11] = 32'h00002cdd;
        weights[0][12] = 32'h000004fd;
        weights[0][13] = 32'h0000102e;
        weights[0][14] = 32'hffffebd1;
        weights[0][15] = 32'hffffda61;
        weights[0][16] = 32'h000003a3;
        weights[0][17] = 32'h00000ac7;
        weights[0][18] = 32'h00002a51;
        weights[0][19] = 32'hffffe1a1;
        weights[0][20] = 32'hfffffae5;
        weights[0][21] = 32'h00001ff0;
        weights[0][22] = 32'hfffff439;
        weights[0][23] = 32'hfffffbb0;
        weights[0][24] = 32'hffffd35f;
        weights[0][25] = 32'hffffe489;
        weights[0][26] = 32'h00000f3b;
        weights[0][27] = 32'h00002c08;
        weights[0][28] = 32'hffffe84c;
        weights[0][29] = 32'h00001eb8;
        weights[0][30] = 32'hffffda14;
        weights[0][31] = 32'hffffee1e;
        weights[1][0] = 32'h000012a8;
        weights[1][1] = 32'hfffff902;
        weights[1][2] = 32'hffffe624;
        weights[1][3] = 32'h00000038;
        weights[1][4] = 32'h000016b4;
        weights[1][5] = 32'hffffe2f0;
        weights[1][6] = 32'hffffe759;
        weights[1][7] = 32'hffffecbd;
        weights[1][8] = 32'h000014e0;
        weights[1][9] = 32'h00002979;
        weights[1][10] = 32'h0000191e;
        weights[1][11] = 32'hffffff12;
        weights[1][12] = 32'hffffe018;
        weights[1][13] = 32'h00001b04;
        weights[1][14] = 32'h00000a9e;
        weights[1][15] = 32'hffffd59e;
        weights[1][16] = 32'hffffd66c;
        weights[1][17] = 32'hffffdd6f;
        weights[1][18] = 32'hffffebb7;
        weights[1][19] = 32'hffffe8d0;
        weights[1][20] = 32'hffffd451;
        weights[1][21] = 32'h00001824;
        weights[1][22] = 32'h00001270;
        weights[1][23] = 32'h0000207e;
        weights[1][24] = 32'hfffff3fe;
        weights[1][25] = 32'h00001aeb;
        weights[1][26] = 32'hffffd8c7;
        weights[1][27] = 32'h000001c3;
        weights[1][28] = 32'hfffff6e9;
        weights[1][29] = 32'hffffd901;
        weights[1][30] = 32'hfffffc4b;
        weights[1][31] = 32'hffffeb15;
        weights[2][0] = 32'h0000045d;
        weights[2][1] = 32'h0000015c;
        weights[2][2] = 32'hfffff1f6;
        weights[2][3] = 32'hfffff9ab;
        weights[2][4] = 32'h000025e6;
        weights[2][5] = 32'h000008f7;
        weights[2][6] = 32'hffffe40d;
        weights[2][7] = 32'h00001a6d;
        weights[2][8] = 32'h000020c1;
        weights[2][9] = 32'hfffff5f1;
        weights[2][10] = 32'h00000b88;
        weights[2][11] = 32'h000000b0;
        weights[2][12] = 32'h0000289f;
        weights[2][13] = 32'hffffe7cc;
        weights[2][14] = 32'h00000d71;
        weights[2][15] = 32'h000022ee;
        weights[2][16] = 32'h000023a3;
        weights[2][17] = 32'hffffdd74;
        weights[2][18] = 32'hfffff419;
        weights[2][19] = 32'hffffe9ea;
        weights[2][20] = 32'hfffffba6;
        weights[2][21] = 32'hfffff688;
        weights[2][22] = 32'hffffec3d;
        weights[2][23] = 32'hfffff2e0;
        weights[2][24] = 32'hffffd375;
        weights[2][25] = 32'hfffff06a;
        weights[2][26] = 32'h0000046e;
        weights[2][27] = 32'hffffe82d;
        weights[2][28] = 32'hfffff925;
        weights[2][29] = 32'hffffe7e3;
        weights[2][30] = 32'h00000b39;
        weights[2][31] = 32'hfffff84c;
        weights[3][0] = 32'h0000234d;
        weights[3][1] = 32'h00001c08;
        weights[3][2] = 32'hfffff019;
        weights[3][3] = 32'hffffff47;
        weights[3][4] = 32'h00000015;
        weights[3][5] = 32'h00002594;
        weights[3][6] = 32'hfffff3a2;
        weights[3][7] = 32'h00000944;
        weights[3][8] = 32'h00001dcf;
        weights[3][9] = 32'h00002cd2;
        weights[3][10] = 32'h00001485;
        weights[3][11] = 32'hfffff0ea;
        weights[3][12] = 32'h0000121a;
        weights[3][13] = 32'h00002865;
        weights[3][14] = 32'hffffeddc;
        weights[3][15] = 32'hffffee35;
        weights[3][16] = 32'h000016ba;
        weights[3][17] = 32'h000000b7;
        weights[3][18] = 32'h000001aa;
        weights[3][19] = 32'h00000e8c;
        weights[3][20] = 32'hffffefbb;
        weights[3][21] = 32'hffffe438;
        weights[3][22] = 32'hffffe04b;
        weights[3][23] = 32'h0000190e;
        weights[3][24] = 32'hffffe963;
        weights[3][25] = 32'h00001bef;
        weights[3][26] = 32'hffffe6a1;
        weights[3][27] = 32'h0000219c;
        weights[3][28] = 32'hfffff008;
        weights[3][29] = 32'h0000105a;
        weights[3][30] = 32'h0000166c;
        weights[3][31] = 32'hfffffc6b;
        weights[4][0] = 32'h00000207;
        weights[4][1] = 32'hffffdc82;
        weights[4][2] = 32'h00002bad;
        weights[4][3] = 32'h00001a09;
        weights[4][4] = 32'hffffe538;
        weights[4][5] = 32'h00000d71;
        weights[4][6] = 32'hffffeaff;
        weights[4][7] = 32'h000026e2;
        weights[4][8] = 32'h00000394;
        weights[4][9] = 32'hffffe32f;
        weights[4][10] = 32'h00000574;
        weights[4][11] = 32'hfffffd5b;
        weights[4][12] = 32'h0000219f;
        weights[4][13] = 32'hfffffea6;
        weights[4][14] = 32'hffffd53d;
        weights[4][15] = 32'hffffd459;
        weights[4][16] = 32'h00000518;
        weights[4][17] = 32'h0000289a;
        weights[4][18] = 32'h0000131b;
        weights[4][19] = 32'h0000138b;
        weights[4][20] = 32'hffffe7e0;
        weights[4][21] = 32'hffffd606;
        weights[4][22] = 32'hfffffebb;
        weights[4][23] = 32'hffffed0a;
        weights[4][24] = 32'hffffdbaa;
        weights[4][25] = 32'h00001c92;
        weights[4][26] = 32'h00001de5;
        weights[4][27] = 32'hffffeba1;
        weights[4][28] = 32'h0000130c;
        weights[4][29] = 32'h00000716;
        weights[4][30] = 32'hfffff42c;
        weights[4][31] = 32'h00000bc0;
        weights[5][0] = 32'h000007d9;
        weights[5][1] = 32'hffffef41;
        weights[5][2] = 32'h00001f13;
        weights[5][3] = 32'h000027de;
        weights[5][4] = 32'hfffff828;
        weights[5][5] = 32'hfffff810;
        weights[5][6] = 32'h000013f5;
        weights[5][7] = 32'h00000d95;
        weights[5][8] = 32'hffffe558;
        weights[5][9] = 32'h0000100b;
        weights[5][10] = 32'hffffe02e;
        weights[5][11] = 32'h00001895;
        weights[5][12] = 32'h0000098f;
        weights[5][13] = 32'h00000e0a;
        weights[5][14] = 32'h00001f22;
        weights[5][15] = 32'h00002a48;
        weights[5][16] = 32'hffffd91b;
        weights[5][17] = 32'h00002cd7;
        weights[5][18] = 32'hffffd898;
        weights[5][19] = 32'hfffffed2;
        weights[5][20] = 32'hfffff373;
        weights[5][21] = 32'hfffff316;
        weights[5][22] = 32'h00000c30;
        weights[5][23] = 32'hffffec79;
        weights[5][24] = 32'h000000f0;
        weights[5][25] = 32'hfffffee9;
        weights[5][26] = 32'h0000264e;
        weights[5][27] = 32'hfffff4bf;
        weights[5][28] = 32'h0000152b;
        weights[5][29] = 32'hffffd7d8;
        weights[5][30] = 32'hfffffd93;
        weights[5][31] = 32'hffffd3d4;
        weights[6][0] = 32'h000003b7;
        weights[6][1] = 32'h000015c4;
        weights[6][2] = 32'h00000548;
        weights[6][3] = 32'h00001948;
        weights[6][4] = 32'h00002bff;
        weights[6][5] = 32'hffffd46c;
        weights[6][6] = 32'h00001ebe;
        weights[6][7] = 32'hffffef2d;
        weights[6][8] = 32'hffffd57c;
        weights[6][9] = 32'h000018c7;
        weights[6][10] = 32'hffffee62;
        weights[6][11] = 32'h00002ba1;
        weights[6][12] = 32'h00000b68;
        weights[6][13] = 32'h000019e6;
        weights[6][14] = 32'h00000a5f;
        weights[6][15] = 32'hffffe4a9;
        weights[6][16] = 32'h0000217d;
        weights[6][17] = 32'hffffd47f;
        weights[6][18] = 32'hffffef17;
        weights[6][19] = 32'h0000021e;
        weights[6][20] = 32'h00002681;
        weights[6][21] = 32'hffffeb39;
        weights[6][22] = 32'h00000a3e;
        weights[6][23] = 32'hfffff83e;
        weights[6][24] = 32'hffffe4fe;
        weights[6][25] = 32'h00002c7c;
        weights[6][26] = 32'hffffe9a9;
        weights[6][27] = 32'hffffde1d;
        weights[6][28] = 32'h000002f3;
        weights[6][29] = 32'hfffffad9;
        weights[6][30] = 32'hffffe01d;
        weights[6][31] = 32'h00000eed;
        weights[7][0] = 32'h000016f8;
        weights[7][1] = 32'hfffffc03;
        weights[7][2] = 32'hffffdb5c;
        weights[7][3] = 32'hffffde94;
        weights[7][4] = 32'h00001f9d;
        weights[7][5] = 32'hffffd4ac;
        weights[7][6] = 32'h00002566;
        weights[7][7] = 32'hffffe51d;
        weights[7][8] = 32'h00001f8b;
        weights[7][9] = 32'h00000ebe;
        weights[7][10] = 32'hffffe6f5;
        weights[7][11] = 32'h0000165a;
        weights[7][12] = 32'h00002b9a;
        weights[7][13] = 32'h00002299;
        weights[7][14] = 32'h0000121f;
        weights[7][15] = 32'h00002224;
        weights[7][16] = 32'hffffd605;
        weights[7][17] = 32'h00000410;
        weights[7][18] = 32'hffffe476;
        weights[7][19] = 32'hfffff059;
        weights[7][20] = 32'hffffe2a9;
        weights[7][21] = 32'h00001719;
        weights[7][22] = 32'h00001d5e;
        weights[7][23] = 32'h00001ee3;
        weights[7][24] = 32'h000014c8;
        weights[7][25] = 32'hffffff29;
        weights[7][26] = 32'hfffff565;
        weights[7][27] = 32'h00000520;
        weights[7][28] = 32'hffffe345;
        weights[7][29] = 32'h00000b9f;
        weights[7][30] = 32'h000009e1;
        weights[7][31] = 32'hffffd4ce;
        weights[8][0] = 32'h0000084c;
        weights[8][1] = 32'h000026c5;
        weights[8][2] = 32'hffffd5ac;
        weights[8][3] = 32'h00000972;
        weights[8][4] = 32'h00000338;
        weights[8][5] = 32'h00000b56;
        weights[8][6] = 32'hffffe987;
        weights[8][7] = 32'h00002888;
        weights[8][8] = 32'h00001437;
        weights[8][9] = 32'h000018ad;
        weights[8][10] = 32'hffffde1e;
        weights[8][11] = 32'hffffdead;
        weights[8][12] = 32'hffffe2d9;
        weights[8][13] = 32'h000022b5;
        weights[8][14] = 32'hfffffbbd;
        weights[8][15] = 32'h00000533;
        weights[8][16] = 32'h00001dde;
        weights[8][17] = 32'hffffd468;
        weights[8][18] = 32'h00002333;
        weights[8][19] = 32'hffffe4c8;
        weights[8][20] = 32'hffffe6ab;
        weights[8][21] = 32'hfffff459;
        weights[8][22] = 32'hffffd83c;
        weights[8][23] = 32'hffffdb5f;
        weights[8][24] = 32'hfffffd42;
        weights[8][25] = 32'hffffe5ba;
        weights[8][26] = 32'h000015cb;
        weights[8][27] = 32'hfffff38c;
        weights[8][28] = 32'h00000d3d;
        weights[8][29] = 32'h000006a6;
        weights[8][30] = 32'hfffff0a6;
        weights[8][31] = 32'h00002138;
        weights[9][0] = 32'h00000621;
        weights[9][1] = 32'h00002698;
        weights[9][2] = 32'h00002bb7;
        weights[9][3] = 32'hffffd604;
        weights[9][4] = 32'h00002c93;
        weights[9][5] = 32'h0000122a;
        weights[9][6] = 32'hffffde49;
        weights[9][7] = 32'hffffde23;
        weights[9][8] = 32'h0000030b;
        weights[9][9] = 32'h000003d7;
        weights[9][10] = 32'h0000208a;
        weights[9][11] = 32'hfffff7b7;
        weights[9][12] = 32'hffffdb65;
        weights[9][13] = 32'h000018dc;
        weights[9][14] = 32'hfffffab3;
        weights[9][15] = 32'hffffec00;
        weights[9][16] = 32'h00001d68;
        weights[9][17] = 32'hffffe7cd;
        weights[9][18] = 32'h000007c0;
        weights[9][19] = 32'hffffd375;
        weights[9][20] = 32'hffffd691;
        weights[9][21] = 32'hffffd4fa;
        weights[9][22] = 32'hffffe0d8;
        weights[9][23] = 32'hffffd7c6;
        weights[9][24] = 32'hffffdd4b;
        weights[9][25] = 32'h00001dac;
        weights[9][26] = 32'h00002714;
        weights[9][27] = 32'hfffffc20;
        weights[9][28] = 32'hffffded2;
        weights[9][29] = 32'h00002acd;
        weights[9][30] = 32'h00001eb0;
        weights[9][31] = 32'h00000820;
    end

    // Bias initialization from trained model
    initial begin
        biases[0] = 32'hffffd7d7;
        biases[1] = 32'h00001c05;
        biases[2] = 32'hffffe1c4;
        biases[3] = 32'h00002123;
        biases[4] = 32'hfffff21c;
        biases[5] = 32'h00002a58;
        biases[6] = 32'h000025e1;
        biases[7] = 32'hfffffabf;
        biases[8] = 32'h0000192e;
        biases[9] = 32'hffffe523;
    end

    // Internal signals
    reg [31:0] output_reg [OUT_FEATURES-1:0];
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

// ReLU Activation Implementation
module relu_layer #(
    parameter DATA_SIZE
)(
    input wire clk,
    input wire reset,
    input wire [4095:0] input_data,    // Single dimension only for Tiny Tapeout
    output wire [4095:0] output_data     // Single dimension only for Tiny Tapeout
);

    // Internal signals
    reg [31:0] output_reg [DATA_SIZE-1:0];
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
