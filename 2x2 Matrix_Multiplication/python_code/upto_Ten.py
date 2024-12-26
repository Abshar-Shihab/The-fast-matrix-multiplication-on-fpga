import serial
import time
import numpy as np

def send_matrix_and_receive(size):
    # Configure serial port
    ser = serial.Serial('COM3', 9600, timeout=1)
    
    # First send the matrix size
    print(f"Sending matrix size: {size}")
    ser.write(bytes([size]))
    time.sleep(0.5)
    
    # Generate random test matrices
    matrix_A = np.random.randint(1, 10, (size, size)).flatten()
    matrix_B = np.random.randint(1, 10, (size, size)).flatten()
    
    # Send matrix A
    print("Sending Matrix A:")
    for value in matrix_A:
        print(f"Sending value: {value}")
        ser.write(bytes([int(value)]))
        time.sleep(0.1)
    
    # Send matrix B
    print("Sending Matrix B:")
    for value in matrix_B:
        print(f"Sending value: {value}")
        ser.write(bytes([int(value)]))
        time.sleep(0.1)
    
    # Receive result matrix
    result = []
    expected_size = size * size
    print(f"Receiving result matrix (waiting for {expected_size} values)...")
    
    timeout = time.time() + 10  # 10 second timeout
    while len(result) < expected_size and time.time() < timeout:
        if ser.in_waiting:
            byte = ser.read(1)
            if byte:
                value = ord(byte)
                result.append(value)
                print(f"Received: {value}")
    
    # Reshape result into matrix form
    if len(result) == expected_size:
        result_matrix = np.array(result).reshape((size, size))
        print("\nResult matrix:")
        print(result_matrix)
    else:
        print(f"Error: Received {len(result)} values, expected {expected_size}")
    
    ser.close()

# Example usage
size = int(input("Enter matrix size (2-10): "))
if 2 <= size <= 10:
    send_matrix_and_receive(size)
else:
    print("Invalid size. Please enter a size between 2 and 10.")
