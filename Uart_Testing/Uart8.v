`timescale 1ns / 1ps

/*
 * Simple 8-bit UART realization.
 * Combine receiver, transmitter and baud rate generator.
 * Able to operate 8 bits of serial data, one start bit, one stop bit.
 */
module Uart8  #(
    parameter CLOCK_RATE = 100000000, // board internal clock
    parameter BAUD_RATE = 9600
)(
    input wire clk,

    // rx interface
    input wire rx,
    input wire rxEn,
    output wire [7:0] out,
    output wire rxDone,
    output wire rxBusy,
    output wire rxErr,

    // tx interface
    output wire tx,
    input wire txEn,
    input wire txStart,
    //input reg [7:0] in,
    output wire txDone,
    output wire txBusy,

    // LED output
    output reg [7:0] led
);

// Internal signals
wire rxClk;
wire txClk;

reg [7:0] in = 8'd0;
//reg txStart;

// Registers for received numbers and states
reg [7:0] num1 = 8'd0; // First received number
reg [7:0] num2 = 8'd0; // Second received number
reg [7:0] result = 8'd0; // Sum of the two numbers
reg [1:0] state = 2'd0; // State to track which number is being received

// For detecting rising edge of rxDone
reg prev_rxDone = 0;
reg cond = 0;
always @(posedge clk) begin
    prev_rxDone <= rxDone;
end
wire rxDoneEdge = rxDone & ~prev_rxDone; // Rising edge detection

// Instantiate baud rate generator
BaudRateGenerator #(
    .CLOCK_RATE(CLOCK_RATE),
    .BAUD_RATE(BAUD_RATE)
) generatorInst (
    .clk(clk),
    .rxClk(rxClk),
    .txClk(txClk)
);

// Instantiate receiver
Uart8Receiver rxInst (
    .clk(rxClk),
    .en(rxEn),
    .in(rx),
    .out(out),
    .done(rxDone),
    .busy(rxBusy),
    .err(rxErr)
);

// Instantiate transmitter
Uart8Transmitter txInst (
    .clk(txClk),
    .en(txEn),
    .start(txStart),
    .in(in),
    .out(tx),
    .done(txDone),
    .busy(txBusy)
);


// Main state machine for receiving numbers and updating LEDs
always @(posedge clk) begin
	 if (cond == 1'b1) begin
					 result <= num1 + num2; // Compute the sum of the two numbers
                led <= num1 + num2;
					 //led <= 8'd8;          // Update LED to indicate processing is done
                state <= 2'd0;        // Reset state for the next input sequence
					 cond <= 1'b0;
					 in <= num1 + num2;
					 //txStart <= 1;
	 end
    if (rxDoneEdge) begin
	 //txStart <= 0;
        case (state)
            2'd0: begin
				in <= 8'd0;
                num1 <= out;     // Store the first received number
                led <= out;
					 //led <= 8'd1;     // Update LED to indicate first number received
                state <= 2'd1;   // Move to the next state
            end
            2'd1: begin
                num2 <= out;     // Store the second received number
                led <= out;
					 //led <= 8'd2;     // Update LED to indicate second number received
                state <= 2'd2;   // Move to the next state
					 cond <= 1'b1;
            end
            2'd2: begin
                result <= num1 + num2; // Compute the sum of the two numbers
                led <= 8'd8;          // Update LED to indicate processing is done
                state <= 2'd0;        // Reset state for the next input sequence
            end
        endcase
    end
end
endmodule
