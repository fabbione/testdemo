#!/bin/bash

[ -z "$1" ] && echo "Need starting node(s)" && exit 1

rm -f /tmp/graph.xml

while [ -n "$1" ]; do
	failopts="$failopts -d $1"
	shift
done

crm_simulate -SL $failopts -G /tmp/graph.xml > /dev/null
grep active_uname /tmp/graph.xml | \
	tail -n 1 | \
	sed -e 's#.*CRM_meta_notify_active_uname=\"##g' -e 's#\".*##g' | \
	awk '{print "DO NOT KILL: " $1 " CAN KILL: " $2 }'
