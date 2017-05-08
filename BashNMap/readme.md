NativeBash - BashNMap
===================
A native bash network mapping tool
 - Host Scanning
 - Port Scanning
 - Port Stress Testing
 - Banner Grabbing



Usage
-------------
Working strictly from the most basic bash utilities (check the source), this tool allows scanning functionality without adding new software.

Host/Port Scanning: 
Scan through a range of hosts and ports. Ranges supported include 1x dash (-) or comma separated for both IPs and Ports (not cidr) and, of course, the host can also be a FQDN. The display will be only that of live hosts and responding ports. Include -b and we'll try to get a banner parsed out to the most important line. For better banner data use the banner action.

Port Stress: 
Use to test the quality of a connection to a specific port. It does work on ranges of hostnames and ports but they run in sequence only. Also supports user specified connection timeouts and micro sleep duration between connections (defaults are 1sec and 5000usec).

Banner Grabbing: 
Get the raw (ascii still) banner data from ports which respond. Supports host and port ranges but will only display data if a banner is successfully acquired.

Range: 
As a bonus I output the IPs generated from my parser. Sadly, no CIDR range supported yet but the stackoverflow community whipped up something interesting: http://stackoverflow.com/questions/16986879/bash-script-to-list-all-ips-in-prefix

One-Liners: 
I've included one-liner functions within the comments of the script. You can copy and paste these into your terminal then call upon them as you normally would any command. I find these especially useful so I thought others might as well.

Requirements: 
Your linux kernel needs to be compiled with '/dev/tcp' for this to work (which is a standard setup).

```
  Usage: bashnmp action -h <target_hosts> -p <target_ports> ..more arguments

	Actions:         Description:
	      scan         Host & Port Scanner  | args: -h -p [-r -t -b -n]
	    stress         Port Stress Tester   | args: -h -p [-r -t -l -u -n]
	    banner         Port Banner Grabber  | args: -h -p [-r -t -n]
	     range         Host Range Expansion | args: -h

      Arguments:
	        -h         host/host range (dash or comma)   | -h 192.168.10-11.0
	        -p         port/port range (dash or comma)   | -p 1-1024
	        -r         protocol tcp (default) or udp     | -r tcp
	        -t         connection timeout (seconds)      | -t 1
	        -l         limit connections for stress test | -l 3000
	        -u         micro sleep between connections   | -u 5000
	        -b         banner grab during scanner action | -b
	        -n         no ping - skip host ping          | -n	
```

Examples
-------------

IP/Port Scanner
```
-$ bashnmap scan -h 192.168.200.90-100 -p 1-1024 -b
  Host: 192.168.200.98              (pingable)
            80/http                open  SERVER: EPSON_Linux UPnP/1.0 ...
           139/netbios-ssn         open               
           445/microsoft-ds        open               
           515/printer             open               
           631/ipp                 open  SERVER: EPSON_Linux UPnP/1.0 ...
  Host: 192.168.200.99              (pingable)
            22/ssh                 open  SSH-2.0-OpenSSH_6.8p1-hpn14v6
            53/domain              open               
            80/http                open  Server: nginx
           111/sunrpc              open               
           139/netbios-ssn         open               
           161/snmp                open               
           443/https               open  Server: nginx
           445/microsoft-ds        open               
```      
Banner Grab
```
-$ bashnmap banner -h 192.168.200.90-100 -p 1-1024
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
-$ bashmap -h 192.168.20.99 -p 443
Host: 192.168.20.99
Port: 443
Reqs: 3000
Success: 2987 | Fail: 4 (timeouts: 9)
```

Range
```
-$ bashnmap range -h 192.168.2.90-100
192.168.2.90 192.168.2.91 192.168.2.92 192.168.2.93 192.168.2.94 192.168.2.95 192.168.2.96 192.168.2.97 192.168.2.98 192.168.2.99 192.168.2.100
```
