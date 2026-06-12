# Day 15: RDS, Load Balancers, Auto Scaling

## Concept

**RDS (Relational Database Service)** — managed databases (MySQL, PostgreSQL, Aurora, etc.). Handles backups, patching, replication, failover.

**ALB (Application Load Balancer)** — layer-7 load balancer that routes HTTP/HTTPS traffic based on rules (path, host, headers). Distributes traffic across targets (EC2, Lambda, IPs).

**Auto Scaling Group (ASG)** — maintains a desired count of EC2 instances. Scales based on metrics (CPU, memory, request count). Works with ALB for automatic instance registration/deregistration.

## Task

1. **Create a security group for RDS**
   ```bash
   aws ec2 create-security-group \
     --group-name rds-sg \
     --description "RDS access" \
     --vpc-id vpc-xxxx

   # Allow MySQL from app tier SG (we'll create it)
   aws ec2 authorize-security-group-ingress \
     --group-id sg-rds \
     --protocol tcp --port 3306 \
     --source-group sg-app
   ```

2. **Create an RDS instance**
   ```bash
   aws rds create-db-instance \
     --db-instance-identifier mydb \
     --db-instance-class db.t3.micro \
     --engine mysql \
     --master-username admin \
     --master-user-password password123 \
     --allocated-storage 20 \
     --vpc-security-group-ids sg-rds
   ```
   Wait for it: `aws rds wait db-instance-available --db-instance-identifier mydb`

3. **Create a launch template for ASG**
   ```bash
   aws ec2 create-launch-template \
     --launch-template-name web-template \
     --launch-template-data '{
       "ImageId": "ami-0c55b159cbfafe1f0",
       "InstanceType": "t3.micro",
       "SecurityGroupIds": ["sg-app"],
       "UserData": "'$(echo -n '#!/bin/bash
         yum install -y httpd mysql
         echo "<?php echo \"Hello from ASG\";" > /var/www/html/index.php
         systemctl start httpd' | base64)'"
     }'
   ```

4. **Create an ALB**
   ```bash
   aws elbv2 create-load-balancer \
     --name web-alb \
     --subnets subnet-public1 subnet-public2 \
     --security-groups sg-alb

   # Create target group
   aws elbv2 create-target-group \
     --name web-tg \
     --protocol HTTP --port 80 \
     --vpc-id vpc-xxxx \
     --target-type instance

   # Create listener
   aws elbv2 create-listener \
     --load-balancer-arn arn:alb \
     --protocol HTTP --port 80 \
     --default-actions Type=Forward,TargetGroupArn=arn:tg
   ```

5. **Create an Auto Scaling Group**
   ```bash
   aws autoscaling create-auto-scaling-group \
     --auto-scaling-group-name web-asg \
     --launch-template LaunchTemplateName=web-template \
     --min-size 2 --max-size 6 --desired-capacity 2 \
     --vpc-zone-identifier "subnet-public1,subnet-public2" \
     --target-group-arns arn:tg

   # Add a scale-out policy (CPU > 70%)
   aws autoscaling put-scaling-policy \
     --auto-scaling-group-name web-asg \
     --policy-name cpu-scale-out \
     --scaling-adjustment 1 \
     --adjustment-type ChangeInCapacity

   # Add a scale-in policy (CPU < 30%)
   aws autoscaling put-scaling-policy \
     --auto-scaling-group-name web-asg \
     --policy-name cpu-scale-in \
     --scaling-adjustment -1 \
     --adjustment-type ChangeInCapacity
   ```

6. **Test** — describe instances, get the ALB DNS name, curl it. You should see the PHP response.
   ```bash
   aws elbv2 describe-load-balancers --query "LoadBalancers[*].DNSName"
   ```

## Real-world relevance

RDS + ALB + ASG is the standard architecture for high-availability web applications. The ALB distributes traffic across EC2 instances in the ASG. The ASG replaces failed instances and scales based on load. RDS handles database failover. This is what most production web apps look like.

## Summary

- RDS: managed DB with automated backups, multi-AZ failover
- ALB: layer-7 load balancer with path/host routing
- ASG: maintains instance count, scales based on metrics
- ALB target group registers ASG instances automatically
- Launch template defines the instance config (AMI, SG, user data)

## Interview Question

Design a highly-available web application architecture on AWS. Walk through the components: VPC, subnets, ALB, ASG, RDS. How does traffic flow from the user to the database? How does RDS multi-AZ work? How does the ASG know to register new instances with the ALB?
