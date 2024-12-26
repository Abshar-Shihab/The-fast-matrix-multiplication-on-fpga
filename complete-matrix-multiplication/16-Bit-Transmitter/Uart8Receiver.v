`timescale 1ns / 1ps

`include "UartStates.vh"

module Uart8Receiver (
    input  wire       clk,  // baud rate
    input  wire       en,
    input  wire       in,   // rx
    output reg  [7:0] out,  // received data
    output reg        done, // end on transaction
    output reg        busy, // transaction is in process
    output reg        err   // error while receiving data
);
    // States as parameters instead of registers
    localparam [1:0] RESET = 2'b00;
    localparam [1:0] IDLE = 2'b01;
    localparam [1:0] DATA_BITS = 2'b10;
    localparam [1:0] STOP_BIT = 2'b11;

    reg [1:0] state;
    reg [2:0] bitIdx;
    reg [2:0] inputSw;  // Expanded to 3 bits for better noise immunity
    reg [3:0] clockCount;
    reg [7:0] receivedData;
    
    // Majority vote sampling
    wire sampledBit = (inputSw[2] & inputSw[1]) | 
                     (inputSw[1] & inputSw[0]) | 
                     (inputSw[2] & inputSw[0]);

    initial begin
        state <= RESET;
        bitIdx <= 0;
        inputSw <= 3'b111;  // Initialize to idle state
        clockCount <= 0;
        receivedData <= 0;
        out <= 0;
        err <= 0;
        done <= 0;
        busy <= 0;
    end

    always @(posedge clk) begin
        // Input synchronizer with 3 samples
        inputSw <= {inputSw[1:0], in};
        
        // Clear done flag after one clock cycle
        if (done) done <= 1'b0;

        if (!en) begin
            state <= RESET;
        end else begin
            case (state)
                RESET: begin
                    state <= IDLE;
                    out <= 8'b0;
                    err <= 1'b0;
                    done <= 1'b0;
                    busy <= 1'b0;
                    bitIdx <= 3'b0;
                    clockCount <= 4'b0;
                    receivedData <= 8'b0;
                end

                IDLE: begin
                    if (!sampledBit) begin  // Start bit detected
                        if (clockCount == 4'h7) begin  // Sample at middle of start bit
                            if (!sampledBit) begin  // Verify start bit
                                state <= DATA_BITS;
                                busy <= 1'b1;
                                clockCount <= 4'b0;
                                bitIdx <= 3'b0;
                            end else begin
                                state <= IDLE;
                            end
                        end else begin
                            clockCount <= clockCount + 4'b1;
                        end
                    end else begin
                        clockCount <= 4'b0;
                    end
                end

                DATA_BITS: begin
                    if (clockCount == 4'hF) begin  // Sample at middle of data bit
                        receivedData[bitIdx] <= sampledBit;
                        clockCount <= 4'b0;
                        if (bitIdx == 3'h7) begin
                            state <= STOP_BIT;
                        end else begin
                            bitIdx <= bitIdx + 3'b1;
                        end
                    end else begin
                        clockCount <= clockCount + 4'b1;
                    end
                end

                STOP_BIT: begin
                    if (clockCount == 4'hF) begin
                        if (sampledBit) begin  // Valid stop bit
                            state <= IDLE;
                            done <= 1'b1;
                            busy <= 1'b0;
                            out <= receivedData;
                        end else begin
                            state <= IDLE;
                            err <= 1'b1;
                        end
                        clockCount <= 4'b0;
                    end else begin
                        clockCount <= clockCount + 4'b1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
