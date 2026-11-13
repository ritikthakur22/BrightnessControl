#!/system/bin/sh
MODDIR=${0%/*}

# Wait until boot completes before launching daemon
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

sh "$MODDIR/brightness_daemon.sh" &
