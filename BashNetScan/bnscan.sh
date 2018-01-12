#!/bin/bash
#
# By: EakHawkEye
# All I ask is you give credit where it is due. Otherwise, enjoy!
#
# Bash Network Scanner
# -------------------------------------
#
# ### One Liners ###
# Host:Port Check:
# function ping_port() { local myhost=${1}; local myport=${2}; if timeout 2 bash -c "exec > /dev/tcp/${myhost}/${myport}" > /dev/null 2>&1; then echo "alive"; else echo "dead"; fi; }
# -$ ping_port msn.com 80
#
# Grab Host & Port Banner:
# function get_banner(){ local myhost=${1}; local port=${2}; exec 3<>/dev/tcp/${myhost}/${port}; echo -e "HEAD / HTTP/1.1\r\n\r\n" >&3; output=$(timeout 1 bash -c cat <&3 2>/dev/null); echo -e "${output}"; }
# -$ get_banner 192.168.2.99 443
#
# Lookup Port Service
# function port_lookup(){ local target_port=${1}; local protocol=${2}; grep " ${target_port}/${protocol}" /etc/services | cut -d ' ' -f 1; }
# -$ port_lookup 22 tcp
#
#
# --- Credits ---
# TCP Connect & IFS Port Parse Method: http://www.catonmat.net/blog/tcp-port-scanner-in-bash/
# Read/Write TCP: http://www.linuxjournal.com/content/more-using-bashs-built-devtcp-file-tcpip
# Declare Brace Expansion: http://wiki.bash-hackers.org/syntax/expansion/brace
#
trap bashtrap INT



#############
# Variables #
#############
test_limit=3000
connect_timeout=1
micro_sleep=5000
sleep_cmd="usleep"
protocol="tcp"
g_banner=false
no_ping=false
ignore_ping=false
action=

# Assign your port service variable
if [ -a "/etc/unicornscan/ports.txt" ]; then 
    f_services="/etc/unicornscan/ports.txt"
else    
    f_services="/etc/services"
fi



#############
# Functions #
#############
function bashtrap()
{
    # In case of cancel
    echo -e "\n  User canceled! Backing up current file."
    exit 5
}

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
    echo -e "  Usage: $( basename $0 ) <action> (-h <target_hosts>|-f <target_host_file>) -p <target_ports> ..more arguments"
    echo -e "\n\tActions:         Description:"
    echo -e "\t      scan         Host & Port Scanner  | args: (-h|-f) -p [-r -t -b -n]"
    echo -e "\t    stress         Port Stress Tester   | args: (-h|-f) -p [-r -t -l -u -n]"
    echo -e "\t    banner         Port Banner Grabber  | args: (-h|-f) -p [-r -t -n]"
    echo -e "\t     range         Host Range Expansion | args:  -h"
    echo -e "\t      port         Port Check           | args:  -h -p (no ranges accepted)"
    echo -e "\n      Arguments:"
    echo -e "\t        -h         host(s)/ip range (dash or comma)  | -h 192.168.2-3.0"
    echo -e "\t        -f         host file line separated          | -f hostlist.txt"
    echo -e "\t        -p         port/port range (dash or comma)   | -p 1-1024"
    echo -e "\t        -r         protocol tcp (default) or udp     | -r tcp"
    echo -e "\t        -t         connection timeout (seconds)      | -t 1"
    echo -e "\t        -l         limit connections for stress test | -l 3000"
    echo -e "\t        -u         micro sleep between connections   | -u 5000"
    echo -e "\t        -b         banner grab during scanner action | -b"
    echo -e "\t        -n         no ping - skip host ping          | -n"
    echo -e "\t        -i         ping but ignore results           | -i\n"
}

function ping_host()
{
    # Ping the host and return the command status
    local target_host=${1}
    local connect_timeout=${2}

    # Ping once, quietly.
    ping -c 1 -W ${connect_timeout} -q ${target_host} > /dev/null 2>&1

    return $?
}

function ping_port()
{
    # Hit the port
    local target_host=${1}
    local target_port=${2}
    local protocol=${3}
    local connect_timeout=${4}

    # Controlled with a timeout, attempt to connect to the address:port
    timeout ${connect_timeout} bash -c "exec > /dev/${protocol}/${target_host}/${target_port}" > /dev/null 2>&1

    return $?
}

function lookup_port()
{
    # Lookup the default port service vi /etc/services
    local target_port=${1}
    local protocol=${2}
    local f_services=${3}

    # Return the short name of the default service
    egrep " ${target_port}/${protocol}" "${f_services}" | head -n1 | cut -d ' ' -f 1
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
    timeout ${connect_timeout} bash -c cat <&3 2>/dev/null
}

function input_parser()
{
    # Pass a portion of the user input to get parsed
    local i_type=${1}
    local i_data=${2}
    local a_parsed=()
    local a_temp=()
    local a_input=()
    local s_temp=""
    local parse_method="ifs"
    local input=

    # Iterate through the input with ',' as the parser and build the target arrays
    ogIFS=${IFS}; IFS=, 
    for input in ${i_data}; do 

        # Determine the datatype and split method
        case ${i_type}:${input} in
            ports:*[0-9]-[0-9]* ) # Port Range: n-n
                        IFS=- read start end <<< ${input}

                        # Incase the IFS parsing doesn't work...
                        if [ "${end}x" == "x" ]; then
                            start=$(cut -d- -f 1 <<< ${i_data})
                            end=$(cut -d- -f 2 <<< ${i_data})
                        fi

                        # Iterate, building the port array
                        for ((port=start; port <= end; port++)); do
                            a_parsed+=( ${port} )
                        done
                        ;;

              ips:*[0-9]-[0-9]* ) # IP Range: 192.168.2.1-255
                        unset a_temp
                        IFS=. read -ra a_temp <<< ${input}

                        # Incase the IFS parsing doesn't work...
                        if [ "${a_temp[2]}x" == "x" ]; then
                            for i in {1..4..1}; do a_temp+=( $(cut -d. -f ${i} <<< ${input}) ); done
                            parse_method="alt"
                        fi

                        # Iterate through the elements of IPv4 stored in ${a_temp[@]}
                        for num in {0..3}; do

                            # When you find the range, split it, expand it based on position, and store in an array
                            if [[ "${a_temp[${num}]}" == *[0-9]"-"[0-9]* ]]; then
                                
                                # Determine the parsing method (in case IFS isn't working)
                                case "${parse_method}" in 
                                    "ifs" ) IFS=- read start end <<< ${a_temp[${num}]}
                                            ;;
                                    "alt" ) start=$(cut -d- -f 1 <<< ${i_data} | cut -d. -f $((num+1)))
                                            end=$(cut -d- -f 2 <<< ${i_data} | cut -d. -f 1)
                                            ;;
                                esac

                                # Determine the octet to expand and do it
                                case ${num} in
                                    # The first line expands a class A IP which is incredibly large. Uncomment and goodluck.
                                #   0 ) declare -a 'a_parsed=( {'"${start}..${end}"'}.{'"0..255"'}.{'"0..255"'}.{'"1..254"'} )' ;;
                                    1 ) declare -a 'a_parsed+=( '"${s_temp}"'{'"${start}..${end}"'}.{'"0..255"'}.{'"1..254"'} )' ;;
                                    2 ) declare -a 'a_parsed+=( '"${s_temp}"'{'"${start}..${end}"'}.{'"1..254"'} )' ;;
                                    3 ) declare -a 'a_parsed+=( '"${s_temp}"'{'"${start}..${end}"'} )' ;;
                                esac

                                break
                            else

                                # Otherwise add the values as the IP range prefix
                                s_temp+="${a_temp[${num}]}."

                            fi

                        done
                        ;;

               file:* ) # Process Host File line separated
                        a_parsed=()
                        for h in $(cat ${i_data}); do
                            a_parsed+=( ${h} )
                        done
                        ;;

                    * ) #        Port: Single Entry: n
                        # IP/Hostname: Single Entry: 192.168.1.10
                        a_parsed+=( ${input} )
                        ;;
        esac

    done

    # Return the array
    export IFS=${ogIFS}
    echo "${a_parsed[@]}"
}

function determine_ping_host_results() {
    # Ping Host and Decide - requires ping_host()
    #   Take the hostname, no_ping, & ignore_ping user requests
    #   ping the host then output the results along with a 
    #   response code which is used to determine continuation
    local target_host=${1}
    local connect_timeout=${2}
    local no_ping=${3}
    local ignore_ping=${4}
    local message="Host: ${target_host}"
    local rtrn=0
    local GREENCOLOR='\E[0;32m'
    local REDCOLOR='\E[0;31m'
    local ENDCOLOR='\E[0m'


    printf "%-33s" ${target_host}

    if ${no_ping}; then
        # Don't Ping
        printf "%10s\n" "(skip-ping)" 

    else
        # Ping & Determine the response code and output
        ping_host ${target_host} ${connect_timeout}
        case ${?} in
            0 ) # If the host is alive to ping
                printf "${GREENCOLOR}%10s${ENDCOLOR}\n" "(pingable)"
                ;;
            * ) # If the host is down to ping
                if ${ignore_ping}; then
                    printf "${REDCOLOR}%14s${ENDCOLOR}\n" "(not-pingable)"
                else
                    echo -en "                                         \r"
                    rtrn=1
                fi
                ;;
        esac
    fi

    return ${rtrn}
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
    local ignore_ping=${7}
    local lk_port=""
    local rtrn=""
    local banner=""
    local GREENCOLOR='\E[0;32m'
    local REDCOLOR='\E[0;31m'
    local ENDCOLOR='\E[0m'

    # HOSTS - Iterate through hosts
    for target_host in ${ary_target_hosts[@]}; do

        # PING - then decide what to do next
        if ! determine_ping_host_results ${target_host} ${connect_timeout} ${no_ping} ${ignore_ping}; then
            continue
        fi

        # PORTS - Iterate through ports
        for target_port in ${ary_target_ports[@]}; do

            # Lookup the port service and ping the port...
            printf "%15s\r" ${target_port}
            lk_port=$( lookup_port ${target_port} ${protocol} ${f_services} )

            # ...depending on the return, if alive output, or if not move to the next port
            ping_port ${target_host} ${target_port} ${protocol} ${connect_timeout}          
            case ${?} in
                0 ) # If the port is up
                    printf "%15s%-15s" "${target_port}/" ${lk_port}
                    printf "${GREENCOLOR}%9s${ENDCOLOR}" "open"
                    # If requested, attempt to get a banner from the port and display a single, important line only
                    if ${g_banner}; then
                        unset banner
                        banner=$(get_banner ${target_host} ${target_port} ${protocol} ${connect_timeout} | \
                                 egrep -i 'server|welcome|[0-9]\.[0-9]' | \
                                 grep -v HTTP/1 | \
                                 head -n1)
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

    # Clean up output
    echo "                         "
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

        # PING - then decide what to do next
        if ! determine_ping_host_results ${target_host} ${connect_timeout} ${no_ping} ${ignore_ping}; then
            continue
        fi
            
        # PORTS - Iterate through ports
        for target_port in ${ary_target_ports[@]}; do

            # If the port is up then continue with the banner grab
            echo -en "Host: ${target_host}:${target_port}        \r"
            if ping_port ${target_host} ${target_port} ${protocol} ${connect_timeout}; then

                # Attempt to get the banner but only output if a banner is returned
                banner=$(get_banner ${target_host} ${target_port} ${protocol} ${connect_timeout})
                if [ "${banner}" ]; then
                    echo -e "Host: ${target_host}:${target_port}"
                    echo -e "${banner}\n"
                fi
            
            fi

        done

    done

    # Text Cleanup
    echo -en "                                 \r"
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
    local cmd_sleep=${6}
    local u_sleep=${7}
    local no_ping=${8}
    local ignore_ping=${9}
    local rtrn


    # HOSTS - Iterate through hosts
    for target_host in ${ary_target_hosts[@]}; do

        # PING - then decide what to do next
        if ! determine_ping_host_results ${target_host} ${connect_timeout} ${no_ping} ${ignore_ping}; then
            continue
        fi      

        # Third print method headers
        printf "%13s %10s %8s %9s\n" "_port" "_succ" "_fail" "_tmout"

        # PORTS - Iterate through ports
        for target_port in ${ary_target_ports[@]}; do
            local suc_count=0
            local fail_count=0
            local timeout_count=0   

            # Start the port test iterations until the limit is reached
            while [ $((suc_count + fail_count + timeout_count)) -lt ${limit} ]; do 

                # Call on the port test and store the response code
                # [WARN] This function calls upon another
                ping_port ${target_host} ${target_port} ${protocol} ${connect_timeout}
                case $? in
                    0) ((suc_count++));;
                    1) ((fail_count++));;
                  124) ((timeout_count++));;
                    *) ((fail_count++)); exit_on_error ${rtrn} "Unknown";;
                esac

                # [USER OUTPUT] Update the output counts in real-time
                #printf "    Port: %5i  Success: %-5i  Fail: %-5i  Timeouts: %-5i\r" ${target_port} ${suc_count} ${fail_count} ${timeout_count}
                printf "%13i %10i %8i %9i\r" ${target_port} ${suc_count} ${fail_count} ${timeout_count}
                ${cmd_sleep} ${u_sleep} 2>/dev/null

            done
            echo

        done

    done
}



#########
# Logic #
#########
# Verify arguments exist
if [[ $# -lt 3 ]]; then usage; exit 2; fi

# [INPUT PARSE] - Action Requested
case "${1}" in
      "scan" ) action="scan" ;;
    "stress" ) action="stress" ;;
    "banner" ) action="banner" ;;
     "range" ) action="range" ;;
      "port" ) action="port" ;;
           * ) echo "[-] Action: ${1} unsupported."; usage; exit 1;;
esac
shift

# [INPUT PARSE] - Arguments
while [ "${1}" ]; do
    case "${1}" in
        "-h" | "--host"* ) ary_hosts=( $( input_parser "ips" ${2} ) ); shift ;;
        "-f" | "--file"* ) if ! [ -e "${2}" ]; then usage; exit 1; fi; ary_hosts=( $( input_parser "file" ${2} ) ); shift ;;
        "-p" | "--port"* ) ary_ports=( $( input_parser "ports" ${2} ) ); shift ;;
        "-r" | "--prot"* ) protocol="${2}"; shift ;;
        "-b" | "--bann"* ) g_banner=true ;;
        "-t" | "--time"* ) connect_timeout=${2} ;;
        "-l" | "--limi"* ) test_limit=${2} ;;
        "-u" | "--usle"* ) micro_sleep=${2} ;;
        "-n" | "--nopi"* ) no_ping=true ;;
        "-i" | "--igno"* ) ignore_ping=true;;
    esac
    shift
done

# [SLEEP CHECK] - Determine which sleep to use and convert input as needed
#   sleep - Newer bash use builtin. Convert input to decimal for micro
#   usleep - Older bash make external call. No input conversion
if sleep 0.00001 > /dev/null 2>&1; then
    sleep_cmd="sleep"
    micro_sleep=$( echo "scale=6; ${micro_sleep} / 1000000" | bc )
fi

# [ACTION] - Now run the request
case "${action}" in
      "scan" ) process_scan ary_hosts[@] ary_ports[@] "${protocol}" ${connect_timeout} ${g_banner} ${no_ping} ${ignore_ping};;
    "stress" ) process_stress_port ary_hosts[@] ary_ports[@] "${protocol}" ${test_limit} ${connect_timeout} ${sleep_cmd} ${micro_sleep} ${no_ping} ${ignore_ping};;
    "banner" ) process_banners ary_hosts[@] ary_ports[@] "${protocol}" ${connect_timeout} ${no_ping} ${ignore_ping};;
     "range" ) echo -e "${ary_hosts[@]}" ;;
      "port" ) ping_port ${ary_hosts[0]} ${ary_ports[0]} "${protocol}" ${connect_timeout}; exit $?;;
           * ) echo "[-] Impossible" ;;
esac

exit $?
