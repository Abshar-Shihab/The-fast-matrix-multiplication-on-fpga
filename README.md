# The Fast Matrix Multiplication on FPGA

## Project Overview

This project explores efficient matrix multiplication on FPGA hardware, focusing on optimizing computation speed using serial, parallel, and pipelined processing methods. Communication between the PC and FPGA is implemented through UART or Ethernet.

### Team Members:
- **U.L. Mohamed Abshar Shihab**
- **Imad ud Din**
- **Kanwar M. Umar**

### Objectives
1. Establish UART communication between the PC and FPGA.
2. Implement and test 2x2 upto 10x10 matrix multiplication on the FPGA using Verilog.
3. Optimize matrix multiplication using pipelining for increased computational speed.

### Repository Structure
```
The-fast-matrix-multiplication-on-fpga/
├── 2x2 Matrix_Multiplication/
├── Uart_Testing/
├── complete-matrix-multiplication/
│   ├── 16-Bit-Transmitter/
│   │   ├── Outputs/
│   │   │   ├── 16bit-2x2.png
│   │   │   ├── 16bit-3x3.png
│   │   ├── Python Code/
│   │   │   ├── 16bit.py
│   │   ├── BaudRateGenerator.v
│   │   ├── Uart8Receiver.v
│   │   ├── Uart8Transmitter.v
│   │   ├── Uart8_Matrix.v
│   │   ├── UartStates.vh
│   │   ├── ucf.ucf
│   ├── Matrix-Multiplication-with-pipeline/
│   │   ├── Outputs/
│   │   │   ├── 3x3-p.png
│   │   │   ├── 4x4-p.png
│   │   │   ├── 5x5-p.png
│   │   │   ├── 10x10-p.png
│   │   ├── Python Code/
│   │   │   ├── upto_Ten_Time.py
│   │   ├── BaudRateGenerator.v
│   │   ├── Uart8Receiver.v
│   │   ├── Uart8Transmitter.v
│   │   ├── Uart8_pip.v
│   │   ├── UartStates.vh
│   │   ├── ucf.ucf
│   ├── Matrix_Multiplication/
│   │   ├── Outputs/
│   │   │   ├── 3x3.png
│   │   │   ├── 4x4.png
│   │   │   ├── 5x5.png
│   │   │   ├── 10x10.png
│   │   ├── Python Code/
│   │   │   ├── upto_Ten_Time.py
│   │   ├── BaudRateGenerator.v
│   │   ├── Uart8Receiver.v
│   │   ├── Uart8Transmitter.v
│   │   ├── Uart8_Matrix.v
│   │   ├── UartStates.vh
│   │   ├── ucf.ucf
├── README.md
```

## How to Run
1. Clone the repository:
   ```bash
   git clone https://github.com/Abshar-Shihab/The-fast-matrix-multiplication-on-fpga.git
   ```
2. Navigate to the appropriate folder for the desired module.
3. Follow the Python script in each folder to test the corresponding functionality.
   - Use `16bit.py` for 16-bit transmitter tests.
   - Use `upto_Ten_Time.py` for matrix multiplication tests.
4. Analyze the output images in the `Outputs` folder to validate the results.



## Future Goals
- Explore larger matrix sizes and improve hardware utilization.
- Compare FPGA performance against CPU and GPU implementations.

