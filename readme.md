# automagic

## about

this repo manages various automated workflows for my home lab environment. components managed include:
- proxmox
- tailscale


## usage

creating a PR against this repo will initialize automated jobs to validate and apply changes prior to deployment.

## to do
- [ ] decide on using "manual" certs vs funnel for serving pve UI. See [1]
- [ ] finish pve action, it should push whatever files are required on pve host for previous step
- [ ] (feat) write ansible jobs for VM creation on pve 


## docs
[1] https://tailscale.com/kb/1133/proxmox#troubleshooting