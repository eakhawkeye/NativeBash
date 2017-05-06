NativeBash - Test Connectivity
===================
A native bash tool to test the port connectivity of a host...repeatedly


Usage
-------------
Simply pass an IP and a port. The tool will then hit the ip:port (natively) as fast as it can and record the failures The requests are hardcoded at 300 right now - I'll add an argument for this later.
Note: Timeouts are counted as Failures so the total requests = Success + Failures. Timeouts just give context

```
  Usage: test_connectivity.sh <target_host> <target_port>
```

Example
-------------
```
-$ test_connectivity.sh 192.168.2.99 443
Host: 192.168.2.99
Port: 443
Reqs: 3000
Success: 2991 | Fail: 9 (timeouts: 9)
```
