#!/usr/bin/python3

import RPi.GPIO as GPIO
import time
import os
import signal
import sys

# File where the current fan speed is published for read_fan_speed.py to
# read; overridable via environment variable.
FAN_SPEED_FILE = os.environ.get("FAN_SPEED_FILE", "/tmp/fan_speed.txt")

# GPIO14 = physical pin 8
FAN_PIN = 14
GPIO.setmode(GPIO.BCM)
GPIO.setup(FAN_PIN, GPIO.OUT)

pwm = GPIO.PWM(FAN_PIN, 25)
pwm.start(0)

def read_cpu_temperature():
    temp = os.popen("vcgencmd measure_temp").readline()
    temp = temp.replace("temp=", "").replace("'C\n", "")
    return float(temp)

def control_fan_speed(speed):
    with open(FAN_SPEED_FILE, "w") as f:
        f.write(str(speed))
    pwm.ChangeDutyCycle(speed)

def fan_speed_curve(temperature):
    if temperature < 55:
        return 0
    elif 55 <= temperature < 65:
        return 25
    elif 65 <= temperature < 72:
        return 50
    elif 72 <= temperature < 77:
        return 75
    else:
        return 100

def shutdown_handler(signum, frame):
    print("\nTerminating the program...")
    pwm.stop()
    GPIO.cleanup()
    sys.exit(0)

signal.signal(signal.SIGTERM, shutdown_handler)
signal.signal(signal.SIGINT, shutdown_handler)

try:
    while True:
        cpu_temperature = read_cpu_temperature()
        print(f"CPU Temperature: {cpu_temperature}°C")
        control_fan_speed(fan_speed_curve(cpu_temperature))
        time.sleep(1)

except KeyboardInterrupt:
    shutdown_handler(None, None)
