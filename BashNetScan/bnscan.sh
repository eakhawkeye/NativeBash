#!/bin/bash
#
# By: EakHawkEye
# All I ask is you give credit where it is due. Otherwise, enjoy!
#
# Test Connection Suite
# -------------------------------------
#
# ### One Liners ###
# Host:Port Check:
# function ping_port() { local myhost=${1}; local myport=${2}; timeout 2 bash -c "exec > /dev/tcp/${myhost}/${myport}" > /dev/null 2>&1; if [[ $? -eq 0 ]]; then echo "alive"; else echo "dead"; fi; }
# -$ ping_port msn.com 80
#
# Host & Port Reliability Check:
# function test_port() { local myhost=${1}; local myhost=${2}; suc_count=0; fail_count=0; while true; do timeout 2 bash -c "exec > /dev/tcp/${myhost}/${myport}" > /dev/null 2>&1; if [[ $? -eq 0 ]]; then ((suc_count++)); else ((fail_count++)); fi; echo -en "Success: ${suc_count} | Fail: ${fail_count}\r";  usleep 500; done; }
# -$ test_port 192.168.2.99 443
#
# Grab Host & Port Banner:
# function get_banner(){ local myhost=${1}; local port=${2}; exec 3<>/dev/tcp/${myhost}/${port}; echo -e "HEAD / HTTP/1.1\r\n\r\n" >&3; output=$(timeout 1 bash -c cat <&3 2>/dev/null); echo -e "${output}"; }
# -$ get_banner 192.168.2.99 443
#
# Lookup Port Service
# function port_lookup(){ local target_port=${1}; local protocol=${2}; grep " ${target_port}/${protocol}" /etc/services | cut -d ' ' -f 1; }
# -$ lookup_port 22 tcp
#
#
# --- Credits ---
# TCP Connect & Port Parse: http://www.catonmat.net/blog/tcp-port-scanner-in-bash/
# Read/Write TCP: http://www.linuxjournal.com/content/more-using-bashs-built-devtcp-file-tcpip
# Declare Brace Expansion: http://wiki.bash-hackers.org/syntax/expansion/brace
#



#############
# Variables #
#############
test_limit=3000
connect_timeout=1
micro_sleep=5000
protocol="tcp"
g_banner=false
no_ping=false
action=

# Check for default directory
if [ -a "/bin/egrep" ]; then wd="/bin"; else wd="/usr/bin"; fi

cmd_bash="${wd}/bash"
cmd_cat="${wd}/cat"
cmd_cut="${wd}/cut"
cmd_egrep="${wd}/egrep"
cmd_ping="${wd}/ping"
cmd_usleep="${wd}/usleep"
cmd_timeout="${wd}/timeout"



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

function usage()
{
	# [USER OUTPUT] Help
	echo -e "  Usage: $( basename $0 ) action -h <target_hosts> -p <target_ports> ..more arguments"
	echo -e "\n\tActions:         Description:"
	echo -e "\t      scan         Host & Port Scanner  | args: -h -p [-r -t -b -n]"
	echo -e "\t    stress         Port Stress Tester   | args: -h -p [-r -t -l -u -n]"
	echo -e "\t    banner         Port Banner Grabber  | args: -h -p [-r -t -n]"
	echo -e "\t     range         Host Range Expansion | args: -h"
	echo -e "\n      Arguments:"
	echo -e "\t        -h         host/host range (dash or comma)   | -h 192.168.2-3.0"
	echo -e "\t        -p         port/port range (dash or comma)   | -p 1-1024"
	echo -e "\t        -r         protocol tcp (default) or udp     | -r tcp"
	echo -e "\t        -t         connection timeout (seconds)      | -t 1"
	echo -e "\t        -l         limit connections for stress test | -l 3000"
	echo -e "\t        -u         micro sleep between connections   | -u 5000"
	echo -e "\t        -b         banner grab during scanner action | -b"
	echo -e "\t        -n         no ping - skip host ping          | -n\n"
}

function ping_host()
{
	# Ping the host and return the command status
	local target_host=${1}
	local connect_timeout=${2}

	# Ping once, quietly.
	${cmd_ping} -c 1 -W ${connect_timeout} -q ${target_host} > /dev/null 2>&1

	# Rerturn command response
	echo $?
}

function ping_port()
{
	# Hit the port
	local target_host=${1}
	local target_port=${2}
	local protocol=${3}
	local connect_timeout=${4}

	# Controlled with a timeout, attempt to connect to the address:port
	${cmd_timeout} ${connect_timeout} ${cmd_bash} -c "exec > /dev/${protocol}/${target_host}/${target_port}" > /dev/null 2>&1

	# Return command response code
	echo $?
}

function lookup_port()
{
	# Lookup the default port service vi /etc/services
	local target_port=${1}
	local protocol=${2}
	local f_services="/etc/services"

	# Return the short name of the default service
	${cmd_egrep} " ${target_port}/${protocol}" "${f_services}" | head -n1 | ${cmd_cut} -d ' ' -f 1
}

function get_banner()
{
	# Attempt to grab any banners from a port connection
	# Output should be stored in a variable and read back via echo -e "${var}"
	local target_host=${1}
	local target_port=${2}
	local protocol=${3}
	local connect_timeout=${4}

	# Open a read&write descriptor (3) to the address:port
	# Then send some data to elicit response
	exec 3<>/dev/${protocol}/${target_host}/${target_port}
	echo -e "HEAD / HTTP/1.1\r\n\r\n" >&3

	# Return port response
	${cmd_timeout} ${connect_timeout} ${cmd_bash} -c ${cmd_cat} <&3 2>/dev/null
}

function input_parser()
{
	# Pass a portion of the user input to get parsed
	local i_type=${1}
	local i_data=${2}
	local a_parsed=()
	local a_temp=()
	local s_temp=""

	# Determine the datatype and split method
	case ${i_type}:${i_data} in
		ports:*-* ) # Port: Range: n-n
					IFS=- read start end <<< ${i_data}
					for ((port=start; port <= end; port++)); do
						a_parsed+=( ${port} )
					done
					;;
		  ips:*-* )	#   IP: Range 192.168.2.1-255
					IFS=. read -ra a_temp <<< ${i_data}
					# Iterate through the elements of IPv4 stored in ${a_temp[@]}
					for num in {0..3}; do
						# When you find the range, split it, expand it based on position, and store in an array
						if [[ "${a_temp[${num}]}" == *[0-9]"-"[0-9]* ]]; then
							IFS=- read start end <<< ${a_temp[${num}]}
							case ${num} in
							#	0 ) declare -a 'a_parsed=( {'"${start}..${end}"'}.{'"0..255"'}.{'"0..255"'}.{'"1..254"'} )' ;;
								0 ) echo "You're crazy to expand the first octet. Uncomment above this line if you're so daring." ;;
								1 ) declare -a 'a_parsed=( '"${s_temp}"'{'"${start}..${end}"'}.{'"0..255"'}.{'"1..254"'} )' ;;
								2 ) declare -a 'a_parsed=( '"${s_temp}"'{'"${start}..${end}"'}.{'"1..254"'} )' ;;
								3 ) declare -a 'a_parsed=( '"${s_temp}"'{'"${start}..${end}"'} )' ;;
							esac
							break
						else
							# Otherwise add the values as the IP range prefix
							s_temp+="${a_temp[${num}]}."
						fi
					done
					;;
		      *,* ) # Port: Comma Separated: n,n,n,n
					#   IP: Comma Separated: 192.168.1.10,192.168.2.12
					IFS=, read -ra a_parsed <<< ${i_data}
					;;
		        * )	# Port: Single Entry: n
					#   IP: Single Entry: 192.168.1.10
					a_parsed+=( ${i_data} )
					;;
	esac

	# Return the array
	echo "${a_parsed[@]}"
}

function process_scan()
{
	# Port Scanner - in pure bash!!!
	#   HOSTS: Iterate through the hosts to see if they're alive
	#   PORTS: If host is alive, iterate through the ports to see what is up
	#   BANNERS: If requested also snatch the most important line of a banner response
	# Multi-Function - calls other functions within this function
	declare -a ary_target_hosts=( "${!1}" )
	declare -a ary_target_ports=( "${!2}" )
	local protocol=${3}
	local connect_timeout=${4}
	local g_banner=${5}
	local no_ping=${6}
	local lk_port=""
	local rtrn=""
	local banner=""
	local GREENCOLOR='\E[0;32m'
	local REDCOLOR='\E[0;31m'
	local ENDCOLOR='\E[0m'

	# HOSTS - Iterate through hosts
	for target_host in ${ary_target_hosts[@]}; do

		# Test to be sure the host is alive
		echo -en "  Host: ${target_host}\r"
		rtrn=$( ping_host ${target_host} ${connect_timeout} )
		case ${rtrn} in
			0 ) # If the host is alive to ping
				printf "%-34s" "  Host: ${target_host}"; 
				printf "${GREENCOLOR}%10s${ENDCOLOR}\n" "(pingable)"
				;;
			* ) # If the host is down to ping
				if ${no_ping}; then
					printf "%-34s" "  Host: ${target_host}"; 
					printf "${REDCOLOR}%14s${ENDCOLOR}\n" "(non-pingable)"
				else
					continue
				fi
				;;
		esac

		# PORTS - Iterate through ports
		for target_port in ${ary_target_ports[@]}; do

			# Lookup the port service and ping the port...
			echo -en "            ${target_port}\r"
			lk_port=$( lookup_port ${target_port} ${protocol} )
			rtrn=$( ping_port ${target_host} ${target_port} ${protocol} ${connect_timeout} )

			# ...depending on the return, if alive output, or if not move to the next port
			case ${rtrn} in
				0 ) # If the port is up
					printf "%15s" "${target_port}/"
					printf "%-15s" "${lk_port}"
					printf "${GREENCOLOR}%9s${ENDCOLOR}" "open"
					# If requested, attempt to get a banner from the port and display a single, important line only
					if ${g_banner}; then
						banner=""
						banner=$(get_banner ${target_host} ${target_port} ${protocol} ${connect_timeout} | ${cmd_egrep} -i 'server|welcome|[0-9]\.[0-9]' | grep -v HTTP/1)
					fi
					# No matter what, print a new line
					printf "%15s\n" "  ${banner}"
					;;
				* ) # If the port is down
					continue 
					;;
			esac

		done
		
	done
}

function process_banners()
{
	# Simply Grab All the Banners Possible
	#   Similar to the normal scanner except
	#   it outputs host:port & raw banner for successful banner grabs
	# Multi-Function - calls other functions within this function
	declare -a ary_target_hosts=( "${!1}" )
	declare -a ary_target_ports=( "${!2}" )
	local protocol=${3}
	local connect_timeout=${4}
	local no_ping=${5}
	local banner=""

	# HOSTS - Iterate through hosts
	for target_host in ${ary_target_hosts[@]}; do

		# If the host is up then continue onto the ports
		echo -en "Host: ${target_host}      \r"
		if [[ $(ping_host ${target_host} ${connect_timeout}) -eq 0 ]]; then
			
			# PORTS - Iterate through ports
			for target_port in ${ary_target_ports[@]}; do

				# If the port is up then continue with the banner grab
				echo -en "Host: ${target_host}:${target_port}        \r"
				if [[ $(ping_port ${target_host} ${target_port} ${protocol} ${connect_timeout}) -eq 0 ]]; then

					# Attempt to get the banner but only output if a banner is returned
					banner=$(get_banner ${target_host} ${target_port} ${protocol} ${connect_timeout})
					if [ "${banner}" ]; then
						echo -e "Host: ${target_host}:${target_port}"
						echo -e "${banner}\n"
					fi
				
				fi

			done

		fi

	done
}

function process_stress_port()
{
	# Stress Test Host:Port
	#   Used to test connectivition reliability and service availability 
	#   from the network perspective by hitting the port repeatedly
	# Multi-Function - calls other functions within this function
	declare -a ary_target_hosts=( "${!1}" )
	declare -a ary_target_ports=( "${!2}" )
	local protocol=${3}
	local limit=${4}
	local connect_timeout=${5}
	local u_sleep=${6}
	local no_ping=${7}
	local suc_count=0
	local fail_count=0
	local timeout_count=0
	local rtrn


	# HOSTS - Iterate through hosts
	for target_host in ${ary_target_hosts[@]}; do

		# PORTS - Iterate through ports
		for target_port in ${ary_target_ports[@]}; do

			# [USER OUTPUT] Remind the user of their parameters
			echo -e "Host: ${target_host}\nPort: ${target_port}\nReqs: ${limit}"

			# Start the port test iterations until the limit is reached
			while [ $((suc_count + fail_count)) -lt ${limit} ]; do 

				# Call on the port test and store the response code
				# [WARN] This function calls upon another
				unset rtrn
				rtrn=$( ping_port ${target_host} ${target_port} ${protocol} ${connect_timeout} )

				# Determine the outcome based on the response code
				case ${rtrn} in
					0) ((suc_count++));;
					1) ((fail_count++));;
				  124) ((timeout_count++));;
					*) ((fail_count++)); exit_on_error ${rtrn} "Unknown";;
				esac

				# [USER OUTPUT] Update the output counts in real-time
				echo -en "Success: ${suc_count} | Fail: ${fail_count} | Timeouts: ${timeout_count}\r"
				${cmd_usleep} ${u_sleep}

			done
			echo

		done

	done
}



#########
# Logic #
#########
#if ! [ $# -eq 2 ]; then show_help; exit 2; fi
#stress_port $@ ${protocol} ${test_limit} ${connect_timeout} ${micro_sleep}
#input_parser "ips" "${1}"
if [[ $# -lt 3 ]]; then usage; exit 2; fi

# [INPUT PARSE] - Action Requested
case "${1}" in
	  "scan" ) action="scan" ;;
	"stress" ) action="stress" ;;
	"banner" ) action="banner" ;;
	 "range" ) action="range" ;;
	       * ) echo "[-] Action: ${1} unsupported."; usage; exit 1;;
esac
shift


# [INPUT PARSE] - Arguments
while [ "${1}" ]; do
	case "${1}" in
		"-h" | "--host"* ) ary_hosts=( $( input_parser "ips" ${2} ) ); shift ;;
		"-p" | "--port"* ) ary_ports=( $( input_parser "ports" ${2} ) ); shift ;;
		"-r" | "--prot"* ) protocol="${2}"; shift ;;
		"-b" | "--bann"* ) g_banner=true ;;
		"-t" | "--time"* ) connect_timeout=${2} ;;
		"-l" | "--limi"* ) test_limit=${2} ;;
		"-u" | "--usle"* ) micro_sleep=${2} ;;
		"-n" | "--nopi"* ) no_ping=true ;;
	esac
	shift
done

# [ACTION] - Now run the request
case "${action}" in
	  "scan" ) process_scan ary_hosts[@] ary_ports[@] "${protocol}" ${connect_timeout} ${g_banner} ${no_ping} ;;
	"stress" ) process_stress_port ary_hosts[@] ary_ports[@] "${protocol}" ${test_limit} ${connect_timeout} ${micro_sleep} ${no_ping} ;;
	"banner" ) process_banners ary_hosts[@] ary_ports[@] "${protocol}" ${connect_timeout} ${no_ping} ;;
	 "range" ) echo -e "${ary_hosts[@]}" ;;
	       * ) echo "[-] Impossible" ;;
esac

exit $?