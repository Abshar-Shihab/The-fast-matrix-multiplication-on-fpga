`timescale 1ns / 1ps
module Uart8_Matrix #(
    parameter CLOCK_RATE = 100000000,
    parameter BAUD_RATE = 9600,
    parameter MAX_SIZE = 10  // Maximum matrix size 10x10
)(
    input wire clk,
    input wire rx,
    input wire rxEn,
    output wire [7:0] out,
    output wire rxDone,
    output wire rxBusy,
    output wire rxErr,
    output wire tx,
    input wire txEn,
    output wire txDone,
    output wire txBusy,
    output reg [7:0] led
);
    // Constants
    localparam MAX_ELEMENTS = MAX_SIZE * MAX_SIZE;
    
    // Internal signals
    wire rxClk, txClk;
    reg [7:0] in = 8'd0;
    reg txStart;
    
    // Matrix storage
    reg [7:0] matrix_A [0:MAX_ELEMENTS-1];
    reg [7:0] matrix_B [0:MAX_ELEMENTS-1];
    reg [15:0] matrix_R [0:MAX_ELEMENTS-1];
    
    // Control registers
    reg [7:0] matrix_size = 0;  // Size N for NxN matrix
    reg [7:0] total_elements = 0;  // N^2
    reg [$clog2(MAX_ELEMENTS)-1:0] index = 0;
    reg [2:0] state = 3'd0;
    reg [32:0] delay_counter = 0;
    reg [$clog2(MAX_ELEMENTS)-1:0] tx_count = 0;
    
    // Matrix multiplication indices
    reg [7:0] i = 0, j = 0, k = 0;
    reg [15:0] temp_sum;
    
    // Edge detection
    reg prev_rxDone = 0;
    always @(posedge clk) begin
        prev_rxDone <= rxDone;
    end
    wire rxDoneEdge = rxDone & ~prev_rxDone;

    // Module instantiations
    BaudRateGenerator #(
        .CLOCK_RATE(CLOCK_RATE),
        .BAUD_RATE(BAUD_RATE)
    ) generatorInst (
        .clk(clk),
        .rxClk(rxClk),
        .txClk(txClk)
    );

    Uart8Receiver rxInst (
        .clk(rxClk),
        .en(1'b1),
        .in(rx),
        .out(out),
        .done(rxDone),
        .busy(rxBusy),
        .err(rxErr)
    );

    Uart8Transmitter txInst (
        .clk(txClk),
        .en(txEn),
        .start(txStart),
        .in(in),
        .out(tx),
        .done(txDone),
        .busy(txBusy)
    );

    always @(posedge clk) begin
        case (state)
            3'd0: begin // Wait for size selection
                txStart <= 1'b0;
                if (rxDoneEdge) begin
                    matrix_size <= out;
                    if (out >= 2 && out <= MAX_SIZE) begin
                        total_elements <= out * out;
                        state <= 3'd1;
                        index <= 0;
                    end
                end
            end

            3'd1: begin // Receive matrix A
                if (rxDoneEdge) begin
                    matrix_A[index] <= out;
                    led <= out;
                    if (index == total_elements - 1) begin
                        state <= 3'd2;
                        index <= 0;
                    end else begin
                        index <= index + 1;
                    end
                end
            end

            3'd2: begin // Receive matrix B
                if (rxDoneEdge) begin
                    matrix_B[index] <= out;
                    led <= out;
                    if (index == total_elements - 1) begin
                        state <= 3'd3;
                        i <= 0;
                        j <= 0;
                        k <= 0;
                    end else begin
                        index <= index + 1;
                    end
                end
            end

            3'd3: begin // Matrix multiplication
                temp_sum = (k == 0) ? 0 : matrix_R[i * matrix_size + j];
                matrix_R[i * matrix_size + j] <= temp_sum + 
                    (matrix_A[i * matrix_size + k] * matrix_B[k * matrix_size + j]);
                
                if (k == matrix_size - 1) begin
                    k <= 0;
                    if (j == matrix_size - 1) begin
                        j <= 0;
                        if (i == matrix_size - 1) begin
                            state <= 3'd4;
                            tx_count <= 0;
                            delay_counter <= 32'd12500; // creating a small delay before going to the transmitter
                        end else begin
                            i <= i + 1;
                        end
                    end else begin
                        j <= j + 1;
                    end
                end else begin
                    k <= k + 1;
                end
            end

            3'd4: begin // Transmit results
                if (delay_counter > 0) begin
                    delay_counter <= delay_counter - 1;
                    txStart <= 1'b0;
                end else if (tx_count < total_elements) begin
                    if (!txBusy) begin
                        in <= matrix_R[tx_count];
                        txStart <= 1'b1;
                        if (txDone) begin
                            tx_count <= tx_count + 1;
                            delay_counter <= 32'd12500; // needed here a delay for better transmission ( we put this value after several try)
                            txStart <= 1'b0;
                        end
                    end
                end else begin
                    state <= 3'd0;
                    matrix_size <= 0;
                    total_elements <= 0;
                end
            end
        endcase
    end
endmodule
