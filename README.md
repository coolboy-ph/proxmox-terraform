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
    
                
    - Run terraform commands
        
        ```bash
        terraform init
        terraform plan --auto-approve
        terraform apply --auto-approve
        ```
