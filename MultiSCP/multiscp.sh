#!/bin/bash
#
# By EakHawkEye
#



#############
# Variables #
#############
max_conn=100
timeout_conn=10
data_file=
host_file=



#############
# Functions #
#############
function transfer_files()
{
	# Transfer the files to the brokers
	local my_file=${1}
	local host_list=${2}
	local max_connections=${3}
	local timeout_conn=${4}
	local scp_options=${5}
	local count=0
	local ary_process=()
	local max_hosts=$(cat ${host_list} | wc -l)

	# Iterate through all the hostnames in the file
	for my_host in $(cat ${host_list}); do 

		# Copy the files and add the PID to the array
		scp ${scp_options} -o ConnectTimeout=${timeout_conn} -q ${my_file} ${my_host}:. &
		ary_process+=( $! )
		let "count++"

		# Wait on the processes (pids) to complete then do next batch
		if [[ ${#ary_process[@]} -ge ${max_connections} || ${count} -ge ${max_hosts} ]]; then
			for my_pid in ${ary_process[@]}; do
				echo -en "    Waiting on copies: ${count} left    \r"
				wait ${my_pid};
				let "count--"
			done
			unset ary_process
			count=0
			echo "    Waiting on copies: complete     "
		fi

	done

	return 0
}

function usage()
{
	# [USER OUTPUT] Help
	echo -e "  Usage: $( basename $0 ) action -h <target_hosts_file> -f <file_to_transfer> [options...]"
	echo -e "\n      Arguments:"
	echo -e "\t        -h         file of hostnames (1/line) | -h hosts/impacted.lst"
	echo -e "\t        -f         file to transfer           | -f auto-fix.sh"
	echo -e "        Options:"
	echo -e "\t        -m         max concurrent connections | -m 100"
	echo -e "\t        -t         connetion timeout (in sec) | -t 10"
	echo -e "\t        -o         ssh/scp options            | -o \"-P 44321 -o StrictHostKeyChecking=no\"\n"

	exit 1
}



#########
# Logic #
#########
# Pass a file of hostnames to the script
if [[ $# -lt 4 ]]; then usage; fi

# [INPUT PARSE] - Arguments
while [ "${1}" ]; do
	case "${1}" in
		"-h" | "--host"* ) host_file=${2}; shift ;;
		"-f" | "--file"* ) data_file=${2}; shift ;;
		"-m" | "--max"*  ) max_conn=${2}; shift ;;
		"-t" | "--time"* ) timeout_conn=${2}; shift ;;
		"-o" | "--ssho"* ) ssh_options=${2}; shift ;;
					   * ) echo "Option: '${1}' is unsupported"; usage;;
	esac
	shift
done

# Make sure the hostlist exists
if ! [ -e ${host_file} ]; then echo "  Missing ${host_file}"; exit 3; fi
if ! [ -e ${data_file} ]; then echo "  Missing ${host_file}"; exit 3; fi

# Process the hostlist
echo "  Transferring '${data_file}' to hosts in ${host_file}"
transfer_files "${data_file}" "${host_file}" ${max_conn} ${timeout_conn} "${ssh_options}"


exit 0