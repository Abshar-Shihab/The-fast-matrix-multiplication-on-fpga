`timescale 1ns / 1ps

`include "UartStates.vh"

/*
 * 8-bit UART Transmitter with corrected state transitions and bit handling.
 */
module Uart8Transmitter (
    input  wire       clk,   // baud rate
    input  wire       en,
    input  wire       start, // start of transaction
    input  wire [7:0] in,    // data to transmit
    output reg        out,   // tx
    output reg        done,  // end on transaction
    output reg        busy   // transaction is in process
);
    reg [2:0] state  = `RESET;
    reg [7:0] data   = 8'b0; // to store a copy of input data
    reg [2:0] bitIdx = 3'b0; // for 8-bit data

    always @(posedge clk) begin
        case (state)
            default     : state <= `IDLE;

            `IDLE       : begin
                out     <= 1'b1; // drive line high for idle
                done    <= 1'b0;
                busy    <= 1'b0;
                bitIdx  <= 3'b0;
                data    <= 8'b0;
                if (start) begin
                    data    <= in; // save a copy of input data
                    state   <= `START_BIT;
                    busy    <= 1'b1;
                end
            end

            `START_BIT  : begin
                out     <= 1'b0; // send start bit (low)
                state   <= `DATA_BITS;
            end

            `DATA_BITS  : begin // Send 8 data bits
                out     <= data[bitIdx];
                if (bitIdx == 3'd7) begin
                    bitIdx  <= 3'b0;
                    state   <= `STOP_BIT;
                end else begin
                    bitIdx  <= bitIdx + 1'b1;
                end
            end

            `STOP_BIT   : begin // Send out Stop bit (high)
                out     <= 1'b1;
                done    <= 1'b1;
                busy    <= 1'b0;
                state   <= `IDLE;
            end
        endcase
    end

endmodule
