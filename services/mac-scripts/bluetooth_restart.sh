#!/bin/bash

# Check if the device is connected
deviceStatus=$(/usr/sbin/system_profiler SPBluetoothDataType -json 2>/dev/null | /usr/local/bin/jq -r '.SPBluetoothDataType.[].device_title[]."Desk 7593".device_isconnected')

if [ "$deviceStatus" == "attrib_Yes" ]; then
  echo "Desk is connected. No need to toggle Bluetooth."
  exit 0
fi

osascript -e 'tell application "System Events" to tell process "SystemUIServer" to click (first menu bar item whose description is "bluetooth") of menu bar 1'
osascript -e 'tell application "System Events" to tell process "SystemUIServer" to click menu item "Turn Bluetooth Off" of menu 1 of (first menu bar item whose description is "bluetooth") of menu bar 1'

sleep 1

# Turn Bluetooth on
osascript -e 'tell application "System Events" to tell process "SystemUIServer" to click (first menu bar item whose description is "bluetooth") of menu bar 1'
osascript -e 'tell application "System Events" to tell process "SystemUIServer" to click menu item "Turn Bluetooth On" of menu 1 of (first menu bar item whose description is "bluetooth") of menu bar 1'
