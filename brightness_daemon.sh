#!/system/bin/sh
# Systemless hardware backlight interceptor and dynamic scaler
# Intercepts raw sysfs brightness and smoothly scales the slider range.

MODDIR=${0%/*}
NODE="/sys/devices/platform/leds-mt65xx/leds/lcd-backlight/brightness"

# ROM/Hardware slider boundaries
ANDROID_MIN=379
ANDROID_MAX=2047

# Desired output boundaries
TARGET_MIN=20
TARGET_MAX=2047

LAST_WRITTEN=-1

SPAN_TARGET=$((TARGET_MAX - TARGET_MIN))
SPAN_ANDROID=$((ANDROID_MAX - ANDROID_MIN))

while true; do
    CUR=$(cat "$NODE" 2>/dev/null)

    # Validate that CUR is a valid integer
    case "$CUR" in
        ''|*[!0-9]*)
            sleep 0.1
            continue
            ;;
    esac

    # Only process if value changed and wasn't written by this daemon
    if [ "$CUR" -ne "$LAST_WRITTEN" ]; then
        # Preserve screen-off state
        if [ "$CUR" -eq 0 ]; then
            LAST_WRITTEN=0
        else
            if [ "$CUR" -le "$ANDROID_MIN" ]; then
                NEW_VAL=$TARGET_MIN
            elif [ "$CUR" -ge "$ANDROID_MAX" ]; then
                NEW_VAL=$TARGET_MAX
            else
                # Linear interpolation:
                # Y = TARGET_MIN + ((CUR - ANDROID_MIN) * (TARGET_MAX - TARGET_MIN)) / (ANDROID_MAX - ANDROID_MIN)
                DIFF=$((CUR - ANDROID_MIN))
                NEW_VAL=$((TARGET_MIN + (DIFF * SPAN_TARGET) / SPAN_ANDROID))
            fi

            echo "$NEW_VAL" > "$NODE" 2>/dev/null
            LAST_WRITTEN=$NEW_VAL
        fi
    fi

    # Poll every 100ms for responsive slider movement with negligible CPU overhead
    sleep 0.1
done
