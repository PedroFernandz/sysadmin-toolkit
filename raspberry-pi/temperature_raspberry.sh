#!/bin/bash

# Thermal zone file and vcgencmd binary, overridable via environment
# variables.
THERMAL_ZONE_FILE="${THERMAL_ZONE_FILE:-/sys/class/thermal/thermal_zone0/temp}"
VCGENCMD="${VCGENCMD:-vcgencmd}"

 cpu=$(cat "${THERMAL_ZONE_FILE}")
 echo "Equipo => $(hostname)"
 echo "$(date)"
 echo "------------------------------"
 echo "Temp.CPU => $((cpu/1000))'Cº"
 echo "Temp.GPU => $(${VCGENCMD} measure_temp)"
 echo "------------------------------"
 echo "CPU"
 echo "$(${VCGENCMD} measure_volts core)"
 echo "Mem. del Sistema $(${VCGENCMD} get_mem arm)"
 echo "Mem. de la $(${VCGENCMD} get_mem gpu)"
 echo "------------------------------"
 echo "Consumo de memoria"
 echo "$(egrep --color 'Mem|Cache|Swap' /proc/meminfo)"
