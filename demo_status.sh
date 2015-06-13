#!/bin/bash

set -e

. /srv/RDO-7/configs/keystonerc_admin

make_stat_buf() {
	statbuf="$(date)\n\n"
	statbuf="${statbuf}Pacemaker\n---------\n\n"

	pcsstatus="$(pcs status)"

	controllernodesonline=$(echo "$pcsstatus" | grep ^Online | sed -e 's#.*\[ ##g' -e 's# \].*##g')
	statbuf="${statbuf}Online controller nodes:\n  $controllernodesonline\n\n"

	controllernodesoffline=$(echo "$pcsstatus" | grep ^OFFLINE | sed -e 's#.*\[ ##g' -e 's# \].*##g')
	statbuf="${statbuf}Offline controller nodes:\n  $controllernodesoffline\n\n"

	controllernodesunclean=$(echo "$pcsstatus" | grep ^Node | grep UNCLEAN | sed -e 's#.*Node ##g' -e 's#: UNCLEAN.*##g')
	statbuf="${statbuf}Unclean controller nodes (will be fenced):\n  $controllernodesunclean\n\n"

	remotenodesonline=$(echo "$pcsstatus" | grep RemoteOnline | sed -e 's#.*\[ ##g' -e 's# \].*##g')
	statbuf="${statbuf}Online remote compute nodes:\n  $remotenodesonline\n\n"

	remotenodesoffline=$(echo "$pcsstatus" | grep RemoteOFFLINE | sed -e 's#.*\[ ##g' -e 's# \].*##g')
	statbuf="${statbuf}Offline remote compute nodes:\n  $remotenodesoffline\n\n"

	remotenodesunclean=$(echo "$pcsstatus" | grep RemoteNode | grep UNCLEAN | sed -e 's#.*RemoteNode ##g' -e 's#: UNCLEAN.*##g')
	statbuf="${statbuf}Unclean remote compute nodes (will be fenced):\n  $remotenodesunclean\n\n"

	novacomputenodes=$(echo "$pcsstatus" |grep nova-compute-clone -A1 | grep Started | grep -v UNCLEAN | sed -e 's#.*\[ ##g' -e 's# \].*##g')
	statbuf="${statbuf}Nodes running nova-compute:\n  $novacomputenodes\n"

	statbuf="${statbuf}\n"

	statbuf="${statbuf}Nova Hypervisors:\n-----------------\n\n"
	hvlist="$(nova hypervisor-list | grep "^|" | grep -v ID)"
	hostlist="$(echo "$hvlist" | awk '{print $4}')"
	for hv in $hostlist; do
		statbuf="${statbuf}$hv\n"
		status=$(echo "$hvlist" | grep $hv | awk '{print $6}')
		statbuf="${statbuf}  Status: $status\n"
		if [ "$status" = "up" ]; then
			runningvms="$(nova hypervisor-show $hv | grep running_v | awk '{print $4}')"
			statbuf="${statbuf}  Running $runningvms instances\n"
		fi
		statbuf="${statbuf}\n"
	done
	statbuf="${statbuf}Instances:\n\n"
	novalist="$(nova list)"
	vmlist="$(echo "$novalist" |grep -v ^+ | grep -v ID | awk '{print $4}')"
	for vm in $vmlist; do
		vmstatus="$(echo "$novalist" | grep $vm | awk '{print "Instance: " $4 " Status: " $6 " State: " $10}')"
		statbuf="${statbuf}$vmstatus"
		vmhv="$(nova show $vm | grep hypervisor_hostname | awk '{print $4}' | sed -e 's/\..*//g')"
		statbuf="${statbuf} hypervisor: $vmhv\n"
	done
}

while [ ! -f /root/stop ]; do
	make_stat_buf
	clear
	echo -e "$statbuf"
done
