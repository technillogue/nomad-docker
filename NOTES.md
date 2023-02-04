> URLs to your test app and Kibana

App: <https://sylv-nomad-test.fly.dev>  
Kibana: <https://sylv-nomad-test.fly.dev:5601>  
Nomad: <https://sylv-nomad-test.fly.dev:4646>  

> A short summary of what you built, how it works, and the decisions you made to get there

Simple script that starts dockerd and nomad. Didn't bother with tini.
It's just a normal dev mode nomad cluster, no frills, no consul or anything. I decided to use filebeat and mount nomad's data dir in the filebeat container to access logs; I couldn't get nomad autodiscover to work. Had to do a fair amount of debugging around providing enough memory to elastic (had to request dedicated VMs), and filebeat + kibana authenticating. 

It took me a while to get dockerd to work on firecracker. I tried to work off https://github.com/fly-apps/docker-daemon, but ran into issues with the base images being changed and kernel panics (see below). I ended up using flyio/rchab as a base image, since I know it works. 

I was really interested in this, and spent a while trying to run a cluster on runpod. I refered to @tqbf's post on docker without docker to write a script that would pull and run docker images using the exec/raw_exec drivers. I tried chroot, but couldn't mount /dev; then I tried proot, fakechroot, and a few others with and without alpine, but eventually ran into problems with the nvidia container toolkit I couldn't get around. Still, I was able to run nomad in docker and run whalesay and have fun.

> What you would do or explore if you were actually deploying this to production
 
I wouldn't use elastic, and I wouldn't be running a container like this. If I were just running my own nomad cluster, I'd still probably do something with vector and honeycomb or something. 

I *am* still unfortunately interested in the idea of running containerized nomad clients aggregating across services like Runpod and Vast.ai. I was looking at <https://github.com/jsiebens/nomad-droplets-autoscaler> as a reference for getting cluster autoscaling with per-provider APIs. Rolling a userland chroot that correctly handles libnvidia-container might be viable if you keep at it, or just live with the nomad clients being disposible and run your entire workload with the exec driver without faking docker.

flyctl should let you do --local-only by default, it could go in ~/.fly/config.yml, but it needs a command other than `fly config`. An option making  `---strategy immediate` the default for new projects would also be a handy option 

## debug notes

docker:20 doesn't have dockerd (no longer has?)

docker:20-dind and 23-rc-dind fail with 

Kernel panic - not syncing: Attempted to kill init! exitcode=0x00000100
entry_SYSCALL_64_after_hwframe+0x44/0xae

but just docker:20 works fine
docker:20-dind works fine locally, just not on firecracker

multiple service sections with non-http handlers and/or udp and/or > 3 ports will time out with no message

turns out you need to include `handlers = []` 
