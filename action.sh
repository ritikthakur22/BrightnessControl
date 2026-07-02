#!/system/bin/sh
MODDIR=${0%/*}

killall brightness_daemon.sh 2>/dev/null
sh $MODDIR/brightness_daemon.sh &

echo "Smooth brightness daemon restarted!"
