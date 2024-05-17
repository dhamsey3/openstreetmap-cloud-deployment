# Terraform Configuration for OpenStreetMap Website Deployment

This repository contains Terraform configuration to deploy the OpenStreetMap website on AWS.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
- AWS CLI installed and configured with appropriate permissions.
- An SSH key pair for EC2 access.

## Variables

The following variables need to be provided:

- `db_password`: The password for the PostgreSQL database.
- `db_username`: The username for the PostgreSQL database.
- `db_name`: The name of the PostgreSQL database.
- `key_name`: The name of the key pair to use for SSH access.
- `account_id`: The AWS account ID.

## Steps

1. **Initialize Terraform**:

    ```sh
    terraform init
    ```

2. **Plan the Terraform Changes**:

    ```sh
    terraform plan -var="db_password=your_db_password" -var="db_username=your_db_username" -var="db_name=your_db_name" -var="key_name=your_key_name" -var="account_id=your_account_id"
    ```

3. **Apply the Terraform Changes**:

    ```sh
    terraform apply -var="db_password=your_db_password" -var="db_username=your_db_username" -var="db_name=your_db_name" -var="key_name=your_key_name" -var="account_id=your_account_id"
    ```

Replace `your_db_password`, `your_db_username`, `your_db_name`, `your_key_name`, and `your_account_id` with your actual values.

## Configuration Details

The Terraform configuration does the following:

1. **VPC and Networking**:
    - Creates a VPC.
    - Creates a public subnet.
    - Creates an Internet Gateway and associates it with the VPC.
    - Creates a route table and associates it with the public subnet.

2. **Security Groups**:
    - Creates a security group allowing SSH (port 22) and HTTP (port 80) access.

3. **IAM Roles and Policies**:
    - Creates an IAM role and policy for EC2 instances.
    - Creates an instance profile for the IAM role.

4. **Secrets Management**:
    - Creates secrets in AWS Secrets Manager for the database credentials.

5. **EC2 Instance**:
    - Launches an EC2 instance with the specified AMI, instance type, and key pair.
    - Sets up the EC2 instance with PostgreSQL, Nginx, and the OpenStreetMap website.

6. **RDS Instance**:
    - Creates a PostgreSQL RDS instance with the provided credentials.

7. **S3 Bucket**:
    - Creates an S3 bucket for static assets with server-side encryption and lifecycle configuration.

8. **CloudWatch Logs**:
    - Sets up CloudWatch logs for monitoring the EC2 instance.

## Note

Ensure you have configured your AWS CLI with sufficient permissions to create the necessary resources in your AWS account.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
