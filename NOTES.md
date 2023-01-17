docker:20 doesn't have dockerd (no longer has?)


docker:20-dind and 23-rc-dind fail with 

Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000100
entry_SYSCALL_64_after_hwframe+0x44/0xae

but just docker:20 works fine
docker:20-dind works fine locally, just not on firecracker

multiple service sections with non-http handlers and/or udp and/or > 3 ports will time out with no message

