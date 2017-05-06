#!/bin/bash
# NON-STOP HOST CONNECTIVITY CHECK
# -------------------------------------
#
# One Liner
# suc_count=0; fail_count=0; while true; do nc -z -w3 tc200.usne1r.dht.bf1.yahoo.com 4080 > /dev/null 2>&1; if [[ $? -eq 0 ]]; then ((suc_count++)); else ((fail_count++)); fi; echo -en "Success: ${suc_count} | Fail: ${fail_count}\r";  usleep 500; done


#############
# Variables #
#############
test_limit=3000
connect_timeout=1
micro_sleep=5000



#############
# Functions #
#############
function exit_on_error()
{
	# Exit the script when an error occurs
	# exit_on_error ${rtrn} "Timeout"
	local code=${1}
	local mesg=${2}
	echo "ERROR: ${1} - ${2}"

	exit ${1}
}

function show_help()
{
	# Help
	echo -e "  Usage: $( basename $0 ) <target_host> <target_port>"
}

function test_connect()
{
	# Test connectivity against the host:port
	local target_host=$1
	local target_port=$2
	local connect_timeout=$3
	timeout ${connect_timeout} bash -c "exec >/dev/tcp/${target_host}/${target_port}" > /dev/null 2>&1

	echo $?
}

function main()
{
	# 1=target host, 2=target port, 3=check test iteration limit, 4=connection timeout; 4=sleep in micro seconds
	local target_host=${1}
	local target_port=${2}
	local limit=${4}
	local u_sleep=${5}
	local suc_count=0
	local fail_count=0
	local timeout_count=0
	local connect_timeout=${3}
	local rtrn

	echo -e "Host: ${target_host}\nPort: ${target_port}\nReqs: ${limit}"

	while [ $((suc_count + fail_count)) -lt ${limit} ]; do 

		#nc -z -w3 ${target_host} ${target_port} > /dev/null 2>&1
		unset rtrn
		rtrn=$( test_connect ${target_host} ${target_port} ${connect_timeout} )

		case ${rtrn} in
			0) ((suc_count++));;
			1) ((fail_count++));;
		  124) ((fail_count++)); ((timeout_count++));;
			*) ((fail_count++)); exit_on_error ${rtrn} "Unknown";;
		esac

		echo -en "Success: ${suc_count} | Fail: ${fail_count} (timeouts: ${timeout_count})\r"
		usleep ${u_sleep}

	done
	echo
}



#########
# Logic #
#########
if ! [ $# -eq 2 ]; then show_help; exit 2; fi
main $@ ${connect_timeout} ${test_limit} ${micro_sleep}

exit $?