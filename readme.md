![architecture](./aws_basic.svg)

# How to Use
1.  Install terraform

    Reference:
    https://developer.hashicorp.com/terraform/install#windows

2. Use`terraform init` to initialize .tfstate

3.  Use `terraform plan` to preview the infrastructure changes.

4.  Use `terraform apply` to apply these changes. 
> In this case, a basic AWS network architecture(refer to the image) would be set down, includes one VPC, one public subnet, one private subnet, along with their corresponding route tables and EC2. Additionally, an internet gateway and a NAT gateway  will be established.

# Architecture Information
*   **Providers:** AWS version = "5.37.0"
*   **Region:** "us-west-2"
*   **AWS Security Group:** Allows all inbound traffic on port 22.


# SSH Connection
*   the following commands(also the outputs) to connect:
    *   Public EC2 : `ssh -i your_key.pem ubuntu@ec2_public_ip`
    *   Private EC2 : Connect to the EC2 in the private network via a bastion EC2 in the public domain.
    **Remove 2 backslash before quotation mark**
    `ssh ubuntu@ec2_private_ip -oProxyCommand=\"ssh ubuntu@ec2_public_ip -i your_key.pem -W %h:%p\" -i your_key.pem`


