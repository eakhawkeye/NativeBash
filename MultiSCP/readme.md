NativeBash - Multiple SCP
===================
A native bash tool to scp in parellel.


Usage
-------------
Simply pass two files: the file you want to transfer and a list of hostnames (one per line). The parallelism is hardcoded at 100 right now. I'll add an argument for this later.

```
  Usage: multiscp.sh <file to transfer> <hosts file>
```

Example
-------------
```
-$ multiscp.sh auto-fix.sh hosts/impacted-hosts.lst
  Transfering mikes-broker-bouncer.sh to hosts/full_prod1-brokers.native hosts;
   Waiting on copies: complete
```
