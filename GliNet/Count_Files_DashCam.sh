#!/bin/bash

echo '************************************'
echo '** DashCam kort ** DashCam kort **'
echo '************************************'

echo ""
count=$(wget -qO- http://192.168.1.254/DCIM/Photo | grep -o 'JPG' | wc -l)
result=$((count / 2))
echo Photos: $result

count=$(wget -qO- http://192.168.1.254/DCIM/Movie | grep -o 'MP4' | wc -l)
result=$((count / 2))
echo Movie: $result

count=$(wget -qO- http://192.168.1.254/DCIM/Movie/RO | grep -o 'MP4' | wc -l)
result=$((count / 2))
echo Movie RO: $result

count=$(wget -qO- http://192.168.1.254/DCIM/Movie/Parking | grep -o 'MP4' | wc -l)
result=$((count / 2))
echo Movie Parking: $result
echo ""
echo '************************************'
echo '** DashCam kort ** DashCam kort **'
echo '************************************'
