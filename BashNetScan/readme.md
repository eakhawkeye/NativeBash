NativeBash - BashNetScan
===================
A native bash network scanning tool
 - Host Scan
 - Port Scan
 - Port Ping
 - Port Stress Test
 - Banner Grab



Usage
-------------
Working strictly from the most basic bash utilities (check the source), this tool allows scanning functionality without adding new software. This does NOT use *tcat, telnet, or any other external utility to check ports.

Host/Port Scanning: 
Scan through a range of hosts and ports. Ranges supported include 1x dash (-) or comma separated for both IPs and Ports (not cidr) and, of course, the host can also be a FQDN. The display will be only that of live hosts and responding ports. Include -b and we'll try to get a banner parsed out to the most important line. For better banner data use the banner action.

Port Stress: 
Use to test the quality of a connection to a specific port. It does work on ranges of hostnames and ports but they run in sequence only. Also supports user specified connection timeouts and micro sleep duration between connections (defaults are 1sec and 5000usec).

Banner Grabbing: 
Get the raw (ascii still) banner data from ports which respond. Supports host and port ranges but will only display data if a banner is successfully acquired.

Port (ping):
Ping a single port for a single host and exit with the results. This is useful for scripting ports checks and could be used in place of nc -z.

Range: 
As a bonus I output the IPs generated from my parser. Sadly, no CIDR range supported yet but the stackoverflow community whipped up something interesting: http://stackoverflow.com/questions/16986879/bash-script-to-list-all-ips-in-prefix

One-Liners: 
I've included one-liner functions within the comments of the script. You can copy and paste these into your terminal then call upon them as you normally would any command. I find these especially useful so I thought others might as well.

Requirements: 
Your linux kernel needs to be compiled with '/dev/tcp' for this to work (which is a standard setup).

```
  Usage: bnscan <action> (-h <target_hosts>|-f <target_host_file>) -p <target_ports> ..more arguments

	Actions:         Description:
	      scan         Host & Port Scanner  | args: (-h|-f) -p [-r -t -b -n]
	    stress         Port Stress Tester   | args: (-h|-f) -p [-r -t -l -u -n]
	    banner         Port Banner Grabber  | args: (-h|-f) -p [-r -t -n]
	     range         Host Range Expansion | args:  -h
	      port         Port Check           | args:  -h -p (no ranges accepted)

      Arguments:
	        -h         host(s)/ip range (dash or comma)  | -h 192.168.2-3.0
	        -f         host file line separated          | -f hostlist.txt
	        -p         port/port range (dash or comma)   | -p 1-1024
	        -r         protocol tcp (default) or udp     | -r tcp
	        -t         connection timeout (seconds)      | -t 1
	        -l         limit connections for stress test | -l 3000
	        -u         micro sleep between connections   | -u 5000
	        -b         banner grab during scanner action | -b
	        -n         no ping - skip host ping          | -n
	        -i         ping but ignore results           | -i

```

Examples
-------------

IP/Port Scanner
```
-$ bnscan scan -h 192.168.200.90-100 -p 1-1024 -b
192.168.200.98                  (pingable)
            80/http                open  SERVER: EPSON_Linux UPnP/1.0 ...
           139/netbios-ssn         open               
           445/microsoft-ds        open               
           515/printer             open               
           631/ipp                 open  SERVER: EPSON_Linux UPnP/1.0 ...
192.168.200.99                   (pingable)
            22/ssh                 open  SSH-2.0-OpenSSH_6.8p1-hpn14v6
            53/domain              open               
            80/http                open  Server: nginx
           111/sunrpc              open               
           139/netbios-ssn         open               
           161/snmp                open               
           443/https               open  Server: nginx
           445/microsoft-ds        open               
```      

Port (Ping)
```
-$ bnscan port -h 192.168.200.99 -p 80; echo $?
0
```

Banner Grab
```
-$ bnscan banner -h 192.168.200.90-100 -p 1-1024
Host: 192.168.200.98:80        
HTTP/1.1 404 Not Found
CONTENT-LENGTH: 0
SERVER: EPSON_Linux UPnP/1.0 Epson UPnP SDK/1.0
CONNECTION: close


Host: 192.168.200.98:631        
HTTP/1.1 404 Not Found
CONTENT-LENGTH: 0
SERVER: EPSON_Linux UPnP/1.0 Epson UPnP SDK/1.0
CONNECTION: close


Host: 192.168.200.99:22          
SSH-2.0-OpenSSH_6.8p1-hpn14v6

Host: 192.168.200.99:80        
HTTP/1.1 400 Bad Request
Server: nginx
Date: Mon, 08 May 2017 10:42:20 GMT
Content-Type: text/html
Content-Length: 166
Connection: close


Host: 192.168.200.99:443        
HTTP/1.1 400 Bad Request
Server: nginx
Date: Mon, 08 May 2017 10:42:23 GMT
Content-Type: text/html
Content-Length: 166
Connection: close

```

Stress Test
```
-$ bnscan stress -h 192.168.200.98-99 -p 22,80,445,5001 -l 500
192.168.200.98                   (pingable)
        _port      _succ    _fail    _tmout
           22          0      500         0
           80        470        0        30
          445        500        0         0
         5001          0      500         0
192.168.200.99                   (pingable)
        _port      _succ    _fail    _tmout
           22        500        0         0
           80        500        0         0
          445        496        0         4
         5001          0      500         0
```

Range
```
-$ bnscan range -h 192.168.200.90-100
192.168.200.90 192.168.200.91 192.168.200.92 192.168.200.93 192.168.200.94 192.168.200.95 192.168.200.96 192.168.200.97 192.168.200.98 192.168.200.99 192.168.200.100
```
