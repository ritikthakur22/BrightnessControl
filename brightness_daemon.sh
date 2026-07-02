#!/system/bin/sh
# This daemon intercepts brightness changes and smoothly scales them.
# It acts as a translator between Android's slider and the hardware node.

MODDIR=${0%/*}
NODE="/sys/devices/platform/leds-mt65xx/leds/lcd-backlight/brightness"

# The hardware limits
ANDROID_MIN=379
ANDROID_MAX=2047

# Our new target limits
TARGET_MIN=20
TARGET_MAX=2047

LAST_WRITTEN=-1

while true; do
    CUR=$(cat "$NODE" 2>/dev/null)
    
    # If the value is valid and not what we just wrote
    if [ "$CUR" != "" ] && [ "$CUR" != "$LAST_WRITTEN" ]; then
        
        # Screen is off, let it stay off
        if [ "$CUR" -eq 0 ]; then
            LAST_WRITTEN=0
        else
            NEW_VAL=$CUR
            
            # If it's at or below the ROM's hardcoded minimum
            if [ "$CUR" -le "$ANDROID_MIN" ]; then
                NEW_VAL=$TARGET_MIN
            
            # If it's at or above the maximum
            elif [ "$CUR" -ge "$ANDROID_MAX" ]; then
                NEW_VAL=$TARGET_MAX
                
            # Smoothly scale everything in between using integer math
            else
                # Formula: Y = TARGET_MIN + ((X - ANDROID_MIN) * (TARGET_MAX - TARGET_MIN)) / (ANDROID_MAX - ANDROID_MIN)
                # For this device: Y = 20 + ((CUR - 379) * (2047 - 20)) / (2047 - 379)
                # Which simplifies to: Y = 20 + ((CUR - 379) * 2027) / 1668
                
                DIFF=$((CUR - ANDROID_MIN))
                NEW_VAL=$((TARGET_MIN + (DIFF * 2027) / 1668))
            fi
            
            # Write the new scaled value and remember we wrote it
            echo "$NEW_VAL" > "$NODE"
            LAST_WRITTEN=$NEW_VAL
        fi
    fi
    
    # Check 10 times a second for instantly smooth slider movement
    sleep 0.1
done
