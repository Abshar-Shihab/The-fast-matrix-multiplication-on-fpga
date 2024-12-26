import serial
import time
import numpy as np

def send_matrix_and_receive(size):
    # Record start time
    overall_start_time = time.time()

    # Configure serial port
    ser = serial.Serial('COM3', 9600, timeout=1)
    
    # Send the matrix size
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
    print("\nSending Matrix B:")
    for value in matrix_B:
        print(f"Sending value: {value}")
        ser.write(bytes([int(value)]))
        time.sleep(0.1)
    
    # Prepare to receive result matrix
    result = []
    expected_size = size * size
    print(f"\nReceiving result matrix (waiting for {expected_size} values)...")
    
    # We'll measure the time for the receive phase separately as well
    receive_start_time = time.time()

    # Give up after 10 seconds if not complete
    timeout = time.time() + 10  # 10 second overall receive timeout
    while len(result) < expected_size and time.time() < timeout:
        if ser.in_waiting:
            byte = ser.read(1)
            if byte:
                value = ord(byte)
                result.append(value)
                print(f"Received: {value}")
    
    # End of receiving
    receive_end_time = time.time()
    ser.close()
    
    # Check and reshape result
    if len(result) == expected_size:
        result_matrix = np.array(result).reshape((size, size))
        print("\nResult matrix:")
        print(result_matrix)
    else:
        print(f"Error: Received {len(result)} values, expected {expected_size}")
    
    # Record end time
    overall_end_time = time.time()
    
    # Report total times
    total_overall = overall_end_time - overall_start_time
    total_receive = receive_end_time - receive_start_time

    print(f"\n--- Timing Report ---")
    print(f"Total time (send + receive + any delays): {total_overall:.4f} seconds")
    print(f"Receive phase time: {total_receive:.4f} seconds")
    print("---------------------")

# Example usage
if __name__ == "__main__":
    size = int(input("Enter matrix size (2-10): "))
    if 2 <= size <= 10:
        send_matrix_and_receive(size)
    else:
        print("Invalid size. Please enter a size between 2 and 10.")
