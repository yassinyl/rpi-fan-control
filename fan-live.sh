#!/bin/bash

while true; do
temp=$(awk '{print $1/1000}' /sys/class/thermal/thermal_zone0/temp)

speed=$(pigs gdc 12)
speed=$((speed / 10000))

cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')

echo "--------------------------------"
echo "Time       : $(date '+%H:%M:%S')"
echo "CPU Usage  : ${cpu}%"
echo "Temp       : ${temp}°C"
echo "Fan Speed  : ${speed}%"
echo "--------------------------------"

sleep 2
clear
done
