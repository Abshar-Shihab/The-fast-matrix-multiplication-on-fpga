import serial
import time
import numpy as np

def send_matrix_and_receive(size):
    # Open the serial port with a sufficient timeout
    ser = serial.Serial('COM3', 9600, timeout=5)
    
    # Send the matrix size to the FPGA
    print(f"Sending matrix size: {size}")
    ser.write(bytes([size]))
    time.sleep(0.5)  # Delay to allow the FPGA to process
    
    # Generate matrices A and B
    # Modify range if you need more diverse input for testing
    matrix_A = np.random.randint(1, 10, (size, size)).flatten()
    matrix_B = np.random.randint(1, 10, (size, size)).flatten()
    
    # Display the matrices
    print("\nMatrix A:")
    print(matrix_A.reshape(size, size))
    print("\nMatrix B:")
    print(matrix_B.reshape(size, size))
    
    # Send matrices A and B to the FPGA
    print("\nSending matrix A and B to FPGA...")
    for matrix in [matrix_A, matrix_B]:
        for value in matrix:
            print(f"Sending value: {value}")
            ser.write(bytes([int(value)]))
            time.sleep(0.1)  # Ensure there's enough time for the FPGA to process
    
    # Calculate the number of bytes to read (2 bytes per 16-bit result)
    bytes_to_read = 2 * size * size
    result_bytes = []
    
    print(f"\nReceiving result matrix R ({bytes_to_read} bytes expected)...")
    
    # Read the expected number of bytes from the FPGA
    for i in range(bytes_to_read):
        byte = ser.read(1)
        if not byte:
            print(f"Timeout or no data received at byte {i+1}.")
            break
        val = ord(byte)
        result_bytes.append(val)
        print(f"Received byte {i+1}/{bytes_to_read}: {val}")
    
    # Close the serial port
    ser.close()
    
    print(f"\n8-bit bytes received: {result_bytes}")
    
    # Check if we received the correct number of bytes
    if len(result_bytes) != bytes_to_read:
        print(f"Error: Expected {bytes_to_read} bytes, but received {len(result_bytes)}.")
        return
    
    # Reconstruct 16-bit values from the received bytes
    parsed_16bit = []
    for i in range(0, len(result_bytes), 2):
        hi = result_bytes[i]
        lo = result_bytes[i+1]
        val = (hi << 8) | lo  # Combine high and low bytes into a 16-bit integer
        parsed_16bit.append(val)
    
    print(f"\n16-bit result values: {parsed_16bit}")
    
    # Reshape the result into a matrix
    if len(parsed_16bit) == size * size:
        matrix_R = np.array(parsed_16bit).reshape(size, size)
        print("\nMatrix R (NxN):")
        print(matrix_R)
    else:
        print(f"Warning: Expected {size * size} 16-bit values, but got {len(parsed_16bit)}.")

# Main entry point
if __name__ == "__main__":
    size = int(input("Enter matrix size (2-10): "))
    if 2 <= size <= 10:
        send_matrix_and_receive(size)
    else:
        print("Invalid size. Please enter a size between 2 and 10.")
