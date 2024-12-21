# The Fast Matrix Multiplication on FPGA

## Project Overview

This project explores efficient matrix multiplication on FPGA hardware, focusing on optimizing computation speed using serial, parallel, and pipelined processing methods. Communication between the PC and FPGA is implemented through UART.

### Team Members:
- **Mohamed Abshar Shihab**
- **Imad ud Din**
- **Kanwar M. Umar**

### Objectives
1. Establish UART communication between the PC and FPGA.
2. Implement and test 3x3 matrix multiplication on the FPGA.
3. Extend the implementation to handle 10x10 matrix multiplication.
4. Optimize matrix multiplication using pipelining for increased computational speed.

## Current Progress

### UART Communication Testing
We have successfully tested the UART communication interface using the following steps:
- Two numbers are sent from a Python script to the FPGA.
- The FPGA performs addition on the received numbers.
- The result is sent back to the Python script and displayed in the command line.

#### Files in `Uart_sampling` Folder
- `Uart8.v`  
  Defines the UART 8-bit module for communication.
- `BaudRateGenerator.v`  
  Generates the clock signal for UART communication.
- `Uart8Receiver.v`  
  Handles receiving data via UART.
- `Uart8Transmitter.v`  
  Handles transmitting data via UART.
- `sample.py`  
  Python script for testing UART communication between the PC and FPGA.

### Next Steps
1. **Matrix Multiplication (3x3):** (Already done and needed to test with Uart)
   - Send two matrices (3x3) from the Python script to the FPGA.
   - Perform matrix multiplication on the FPGA.
   - Send the result matrix back to the Python script for validation.

2. **Matrix Multiplication (10x10):**
   - Extend the 3x3 implementation to handle larger matrices (10x10).

3. **Optimization:**
   - Implement pipelining techniques to optimize matrix multiplication for higher performance.


## How to Run
1. Clone the repository:
   ```bash
   git clone https://github.com/Abshar-Shihab/The-fast-matrix-multiplication-on-fpga.git
   ```
2. Navigate to the `Uart_sampling` folder and set up the UART communication test.
3. Run `sample.py` to test number addition between PC and FPGA.
4. Follow updates in `matrix_multiplication` and `optimization` folders for further developments.

## Future Goals
- Expand the project to support Ethernet communication.
- Explore larger matrix sizes and improve hardware utilization.
- Compare FPGA performance against CPU and GPU implementations.

