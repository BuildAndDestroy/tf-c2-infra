# tf-c2-infra

C2 setup on AWS — Terraform layout for two VPCs, three EC2 hosts, peering, and Docker bootstrap.

This Terraform config creates:

- VPC A:
  - 1 EC2 instance
  - 1 ENI
  - Extra EBS volume of 100 GB
  - Internet ingress only on TCP 22
- VPC B:
  - 2 EC2 instances
  - 2 ENIs (one per instance)
  - Internet ingress only on TCP 22 and TCP 443
- VPC peering between A and B with routes both directions
- Security groups that allow all traffic between VPC A and VPC B CIDRs
- Docker installed at boot on all EC2 instances

## Usage

1. Create your variable file:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and set:
   - `key_name` (required): existing EC2 key pair
   - `aws_region` and any optional overrides

3. Deploy:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Read outputs for public/private IPs and peering ID.

## Notes

- The 100 GB disk for instance A is configured as an extra data volume (`/dev/xvdb`), not root.
- The default root volumes use AMI defaults. If you need explicit root sizing, that can be added.
