#
# Regular cron jobs for the pixelpulse2 package
#
0 4	* * *	root	[ -x /usr/bin/pixelpulse2_maintenance ] && /usr/bin/pixelpulse2_maintenance
