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
