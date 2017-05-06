#!/bin/bash


#############
# Variables #
#############
max_conn=100
timeout_conn=10
my_file=
my_host_list=



#############
# Functions #
#############
function transfer_files()
{
	# Transfer the files to the brokers
	local ary_process=()
	unset ary_process
	local my_file=${1}
	local host_list=${2}
	local max_connections=${3}
	local timeout_conn=${4}
	local count=0
	local max_hosts=$(cat ${host_list} | wc -l)

	for my_host in $(cat ${host_list}); do 

		# Copy the files and add the PID to the array
		scp -o ConnectTimeout=${timeout_conn} -q ${my_file} ${my_host}:. &
		ary_process+=( $! )
		let "count++"

		# Wait on the processes (pids) to complete then do next batch
		if [[ ${#ary_process[@]} -ge ${max_connections} || ${count} -ge ${max_hosts} ]]; then
			for my_pid in ${ary_process[@]}; do
				echo -en "   Waiting on copies: ${count} left    \r"
				wait ${my_pid};
				let "count--"
			done
			unset ary_process
			count=0
			echo "   Waiting on copies: complete     "
		fi

	done

	return 0
}

function help_me()
{
	echo "  Usage: $0 <file to transfer> <hosts file>"
	exit 1
}



#########
# Logic #
#########
# Pass a file of hostnames to the script
if ! [[ $# -eq 2 ]]; then help_me; fi

my_file=${1}
my_host_list=${2}

# Make sure the hostlist exists
if ! [ -e ${my_host_list} ]; then echo "  Missing ${my_host_list}"; fi

# Process the hostlist
echo "  Transfering ${my_file} to ${my_host_list} hosts;"
transfer_files "${my_file}" "${my_host_list}" ${max_conn} ${timeout_conn}

exit 0