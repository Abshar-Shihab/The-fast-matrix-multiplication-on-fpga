`timescale 1ns / 1ps

module Uart8_pip #(
    parameter CLOCK_RATE = 100000000,
    parameter BAUD_RATE  = 9600,
    parameter MAX_SIZE   = 10  // Maximum matrix size 10x10
)(
    input  wire         clk,
    input  wire         rx,
    input  wire         rxEn,
    output wire [7:0]   out,
    output wire         rxDone,
    output wire         rxBusy,
    output wire         rxErr,
    output wire         tx,
    input  wire         txEn,
    output wire         txDone,
    output wire         txBusy,
    output reg  [7:0]   led
);
    // ----------------------------------------------------
    // Constants and Signals
    // ----------------------------------------------------
    localparam MAX_ELEMENTS = MAX_SIZE * MAX_SIZE;

    wire rxClk, txClk;
    reg  [7:0] in = 8'd0;
    reg        txStart;

    // Matrix storages
    reg [7:0]  matrix_A [0:MAX_ELEMENTS-1];
    reg [7:0]  matrix_B [0:MAX_ELEMENTS-1];
    reg [15:0] matrix_R [0:MAX_ELEMENTS-1];

    // Control registers
    reg [7:0] matrix_size    = 0;    // NxN
    reg [7:0] total_elements = 0;    // N^2
    reg [$clog2(MAX_ELEMENTS)-1:0] index = 0;
    reg [2:0] state          = 3'd0;
    reg [32:0] delay_counter = 0;
    reg [$clog2(MAX_ELEMENTS)-1:0] tx_count = 0;

    // Indices for multiply
    reg [7:0] i = 0, j = 0, k = 0;

    // Edge detect for rxDone
    reg prev_rxDone = 0;
    always @(posedge clk) begin
        prev_rxDone <= rxDone;
    end
    wire rxDoneEdge = rxDone & ~prev_rxDone;

    // ----------------------------------------------------
    // Instantiate BaudRateGenerator, Uart8Receiver, Uart8Transmitter
    // ----------------------------------------------------
    BaudRateGenerator #(
        .CLOCK_RATE(CLOCK_RATE),
        .BAUD_RATE (BAUD_RATE)
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

    // ----------------------------------------------------
    // Instantiate MAC Pipeline
    // ----------------------------------------------------
    reg  mac_clear;
    reg  mac_valid_in;
    wire mac_valid_out;
    reg  [7:0]  mac_inA;
    reg  [7:0]  mac_inB;
    wire [15:0] mac_out;

    mac_pipeline #(
        .WIDTH_IN(8),
        .WIDTH_OUT(16)
    ) mac_inst (
        .clk       (clk),
        .inA       (mac_inA),
        .inB       (mac_inB),
        .clear     (mac_clear),
        .valid_in  (mac_valid_in),
        .out       (mac_out),
        .valid_out (mac_valid_out)
    );

    // ----------------------------------------------------
    // State Machine
    // ----------------------------------------------------
    always @(posedge clk) begin
        case (state)

        // -----------------------------------------------
        // 0) Receive matrix size
        // -----------------------------------------------
        3'd0: begin
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

        // -----------------------------------------------
        // 1) Receive matrix A
        // -----------------------------------------------
        3'd1: begin
            if (rxDoneEdge) begin
                matrix_A[index] <= out;
                led <= out;  // Debug
                if (index == total_elements - 1) begin
                    state <= 3'd2;
                    index <= 0;
                end 
                else begin
                    index <= index + 1;
                end
            end
        end

        // -----------------------------------------------
        // 2) Receive matrix B
        // -----------------------------------------------
        3'd2: begin
            if (rxDoneEdge) begin
                matrix_B[index] <= out;
                led <= out;  // Debug
                if (index == total_elements - 1) begin
                    // Ready for matrix multiply
                    i <= 0; 
                    j <= 0; 
                    k <= 0;
                    state <= 3'd3;
                end 
                else begin
                    index <= index + 1;
                end
            end
        end

        // -----------------------------------------------
        // 3) FEED: Provide MAC inputs for iteration k
        //    - clear accum if k==0
        //    - valid_in=1 for exactly 1 clock
        // -----------------------------------------------
         3'd3: begin
            // Setup inputs
            mac_inA <= matrix_A[i * matrix_size + k];
            mac_inB <= matrix_B[k * matrix_size + j];
            
            // Clear accumulator at start of each cell calculation
            mac_clear <= (k == 0);
            
            // Assert valid for one cycle
            mac_valid_in <= 1'b1;
            
            // Move to wait state
            state <= 3'd4;
        end

        // -----------------------------------------------
        // 4) WAIT: Process MAC pipeline
        // -----------------------------------------------
        // In state 3'd4 of Uart8_pip:
			3'd4: begin
				 // Deassert valid_in after one cycle
				 mac_valid_in <= 1'b0;
				 
				 // Wait for valid_out and store result
				 if (mac_valid_out) begin
					  if (k == matrix_size - 1) begin
							// Store the final accumulated result
							matrix_R[i * matrix_size + j] <= mac_out;
							k <= 0;
							
							if (j < matrix_size - 1) begin
								 j <= j + 1;
							end 
							else begin
								 j <= 0;
								 if (i < matrix_size - 1) begin
									  i <= i + 1;
								 end 
								 else begin
									  // Matrix multiplication complete
									  state <= 3'd5;
									  tx_count <= 0;
									  delay_counter <= 32'd12500;
								 end
							end
					  end 
					  else begin
							k <= k + 1;
					  end
					  
					  // Go back to feed state unless we're completely done
					  if (!(k == matrix_size - 1 && j == matrix_size - 1 && i == matrix_size - 1)) begin
							state <= 3'd3;
					  end
				 end
			end

        // -----------------------------------------------
        // 5) Transmit results (example: 1 byte per cell)
        // -----------------------------------------------
        3'd5: begin
            if (delay_counter > 0) begin
                delay_counter <= delay_counter - 1;
                txStart <= 1'b0;
            end 
            else if (tx_count < total_elements) begin
                if (!txBusy && !txStart) begin
                    // For demonstration: sending only the lower 8 bits
                    in <= matrix_R[tx_count][7:0];
                    txStart <= 1'b1;
                end 
                else if (txDone) begin
                    tx_count <= tx_count + 1;
                    txStart <= 1'b0;
                    delay_counter <= 32'd12500;
                end
            end 
            else begin
                // Done sending
                state <= 3'd0;
                matrix_size <= 0;
                total_elements <= 0;
            end
        end

        default: state <= 3'd0;
        endcase
    end

endmodule
