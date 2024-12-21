import serial
import time
import random  # Import the random module

# Configure the serial port
ser = serial.Serial('COM3', 9600, timeout=1)  # Replace 'COM3' with your port

ser.reset_input_buffer()
ser.reset_output_buffer()

def send_and_receive():
    # Generate random numbers under 30
    num1 = random.randint(0, 29)  # Random number between 0 and 29
    num2 = random.randint(0, 29)  # Random number between 0 and 29

    print(f"Sending num1: {num1}")
    ser.write(bytes([num1]))  # Send first number
    time.sleep(5)            # Wait for FPGA acknowledgment and LED blink    
    
    ser.reset_input_buffer()
    print(f"Sending num2: {num2}")
    ser.write(bytes([num2]))  # Send second number
    time.sleep(5)            # Wait for FPGA acknowledgment and LED blink

    print("Waiting for result...")
    result = ser.read(1)     # Read the result
    if result:
        print(f"Result received: {ord(result)}")
    else:
        print("No response from FPGA.")

# Execute the function
send_and_receive()
