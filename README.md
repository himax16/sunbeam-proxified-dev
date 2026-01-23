# `sunbeam` Proxified Development Environment

Collection of [Terraform](https://developer.hashicorp.com/terraform) configuration files to deploy a `sunbeam` environment with proxy support for development purposes.

## Prerequisites

- [LXD](https://canonical.com/lxd) is installed and initialized.

  ```bash
  sudo snap install lxd
  lxd init --auto
  ```

- [Terraform](https://developer.hashicorp.com/terraform) is installed.

  ```bash
  sudo snap install terraform --classic
  ```

## Usage

1. Clone the repository.

    ```bash
    git clone https://github.com/himax16/sunbeam-proxified-dev.git
    cd sunbeam-proxified-dev
    ```

2. Initialize Terraform.

    ```bash
    terraform init
    ```

3. Apply the Terraform configuration.

    ```bash
    terraform apply
    ```

4. Bootstrap the `sunbeam` environment in the main VM (`bm0`) using the `manifest.yaml` file.

    ```bash
    lxc exec bm0 -- su - ubuntu
    # Follow sunbeam installation and prepare-node-script instructions
    ```

    ```bash
    sunbeam -v cluster bootstrap --role control,compute,storage
    ```

## Syncing local changes to VMs

When developing using [`snap try`](https://snapcraft.io/docs/snap-try), you might want to sync local changes to the VMs for testing. The accompanying script [`watch_rsync_push.sh`](watch_rsync_push.sh) can help with that.

Usage:

```bash
./watch_rsync_push.sh -J ubuntu@[JUMP_HOST_IP] snap-openstack/sunbeam-python/sunbeam/ ubuntu@[VM_LOCAL_IP]:~/squashfs-root/lib/python3.12/site-packages/sunbeam
```

Replace `VM_LOCAL_IP` with the actual IP address of the target VM obtained from `lxc list`. The `-J` flag is used for SSH jump host if needed.
