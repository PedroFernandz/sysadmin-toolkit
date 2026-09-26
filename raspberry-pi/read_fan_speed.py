#!/usr/bin/python3
# It is necessary to be running the fan_speed_control.py script.

import os

# File where fan_speed_control.py publishes the current fan speed;
# overridable via environment variable (must match FAN_SPEED_FILE there).
FAN_SPEED_FILE = os.environ.get("FAN_SPEED_FILE", "/tmp/fan_speed.txt")


def read_fan_speed():
    try:
        with open(FAN_SPEED_FILE, "r") as f:
            fan_speed = int(f.read())
    except FileNotFoundError:
        fan_speed = None
    return fan_speed

fan_speed_percentage = read_fan_speed()

if fan_speed_percentage is not None:
    print(f"Fan speed: {fan_speed_percentage}%")
else:
    print("Could not read the fan speed.")
