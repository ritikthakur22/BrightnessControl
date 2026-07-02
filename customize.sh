#!/system/bin/sh
ui_print "- Setting permissions..."
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/action.sh 0 0 0755
set_perm $MODPATH/brightness_daemon.sh 0 0 0755

ui_print "- Custom Smooth Brightness installed safely!"
