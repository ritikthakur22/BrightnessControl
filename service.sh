#!/system/bin/sh
MODDIR=${0%/*}

(
    # Start the daemon
    sh $MODDIR/brightness_daemon.sh
) &
