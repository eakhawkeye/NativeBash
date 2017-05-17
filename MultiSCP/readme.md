NativeBash - Multiple SCP
===================
A native bash tool to scp in parellel.


Usage
-------------
Simply pass two files: the file you want to transfer and a list of hostnames (one per line). The parallelism is hardcoded at 100 right now. I'll add an argument for this later.
Note: Intended use with SSH Keys already setup.

```
  Usage: multiscp.sh action -h <target_hosts_file> -f <file_to_transfer> [options...]

      Arguments:
	        -h         file of hostnames (1/line) | -h hosts/impacted.lst
	        -f         file to transfer           | -f auto-fix.sh
        Options:
	        -m         max concurrent connections | -m 100
	        -t         connetion timeout (in sec) | -t 10
	        -o         ssh/scp options            | -o "-P 44321 -o StrictHostKeyChecking=no"

```

Example
-------------
```
-$ multiscp.sh -f auto-fix.sh -h hosts/impacted-hosts.lst
  Transferring 'auto-fix.sh' to hosts in hosts/impacted-hosts.lst
    Waiting on copies: complete
```
