# proxmox-terraform

- **Terraform**
    
    Install libguestfs-tools
    
    ```bash
    ssh root@promox-server
    sudo apt update -y && sudo apt install libguestfs-tools -y
    ```
    
    Download ubuntu cloud image
    
    ```bash
    wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
    ```
    
    There is no default username/password for the ubuntu cloud image. Need to configure it using below cmd, before creating instance from the image.
    
    ```bash
    virt-customize -a focal-server-cloudimg-amd64.img --root-password password:<pass>
    ```
    
    Install qemu-guest-agent in the cloud image
    
    ```bash
    virt-customize -a focal-server-cloudimg-amd64.img --install qemu-guest-agent
    ```
    
    Create VM Template
    
    ```bash
    qm create 9000 --name "ubuntu-focal-cloudinit-template" --memory 1024 --cores 1 --net0 virtio,bridge=vmbr0
    qm importdisk 9000 focal-server-cloudimg-amd64.img local-lvm
    qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
    qm set 9000 --ide0 local-lvm:cloudinit
    qm set 9000 --boot order=scsi0
    qm set 9000 --agent enabled=1
    qm template 9000
    ```
    
    Create a role and user for terraform
    
    ```bash
    # Create Role
    pveum role add terraform_role -privs "Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit Group.Allocate Mapping.Audit Mapping.Use Pool.Allocate Pool.Audit Realm.AllocateUser SDN.Allocate SDN.Audit SDN.Use Sys.Audit Sys.Console Sys.Syslog Sys.Modify User.Modify VM.Allocate VM.Audit VM.Backup VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Console VM.Migrate VM.Monitor VM.PowerMgmt VM.Snapshot VM.Snapshot.Rollback"
    
    # Create User
    pveum user add terraform_user@pve --password <pass>
    
    # Map Role to User
    pveum aclmod / -user terraform_user@pve -role terraform_role
    ```
    
    Create API token for terraform user
    
    ![image](https://github.com/user-attachments/assets/e5b66693-2140-4b08-98d0-1bf23e5443cb)

    
    Copy the Token ID and Secret
    
    ![image](https://github.com/user-attachments/assets/298e956f-e364-4ac8-b0a4-318fae6b68f2)
    
    - Terraform code
        - main.tf
            
            
            variable "cloudinit_template_name" {
                type = string 
            }
            
            variable "proxmox_node" {
                type = string
            }
            
            variable "ssh_key" {
                type = string
            }
            
            resource "proxmox_vm_qemu" "ubuntu" {
              count = 2
              vmid = "100${count.index + 1}"
              name = "ubuntu-0${count.index + 1}"
              target_node = var.proxmox_node
              clone = var.cloudinit_template_name
              agent = 1
              os_type = "cloud-init"
              cores = 1
              sockets = 1
              cpu = "host"
              memory = 1024
              scsihw = "virtio-scsi-pci"
              bootdisk = "scsi0"
            
              disk {
                size = "10G"
                slot = "scsi0"
                storage = "local-lvm"
              }
              
              disk {
                type     = "cloudinit"
                storage  = "local-lvm"
                slot     = "ide0"
              }
            
              network {
                model = "virtio"
                bridge = "vmbr0"
              }
              
              lifecycle {
                ignore_changes = [
                  network,
                ]
              }
            
              ipconfig0 = "ip=192.168.100.20${count.index + 1}/24,gw=192.168.100.1"
              nameserver = "1.1.1.1"
              
              sshkeys = <<EOF
              ${var.ssh_key}
              EOF
            }
            
            
        - provider.tf
            
            
            variable "pm_api_url" {
              type = string
            }
            
            variable "pm_api_token_id" {
                type = string
            }
            
            variable "pm_api_token_secret" {
                type = string
                sensitive = true
            }
            
            terraform {
              required_providers {
                proxmox = {
                  source = "telmate/proxmox"
                  version = "3.0.1-rc4"
                }
              }
            }
            
            provider "proxmox" {
              pm_api_url = var.pm_api_url
              pm_api_token_id = var.pm_api_token_id
              pm_api_token_secret = var.pm_api_token_secret
              pm_tls_insecure = true
            }
            
            
            
        - terraform.tfvars
            
            
            pm_api_url = "https://<proxmox-ip>:8006/api2/json"
            cloudinit_template_name = "ubuntu-focal-cloudinit-template"
            proxmox_node = "<proxmox-node-name>"
            pm_api_token_id = "<token_id>"
            pm_api_token_secret = "<token_secret>"
            ssh_key = "ssh-rsa ..."
            
            
    - Run terraform commands
        
        ```bash
        terraform init
        terraform plan --auto-approve
        terraform apply --auto-approve
        ```
