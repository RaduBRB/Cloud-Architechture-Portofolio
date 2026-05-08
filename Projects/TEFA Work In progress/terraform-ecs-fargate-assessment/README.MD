Infrastructure Assessment and Improvements – ECS on Fargate
Overview
This project documents the assessment, design decisions, and incremental improvements applied to an AWS-based containerised application running on ECS with Fargate.
The primary goals were to:

Secure public access to the application
Improve resilience and scalability
Add observability and monitoring
Align the architecture with AWS best practices
Adapt the design to sandbox account limitations while maintaining production readiness

The infrastructure is fully defined using Terraform.

Part 1: Initial Assessment (Before)
1. Virtual Private Cloud (VPC)
To challenge myself and avoid relying on AWS defaults, I created a custom VPC instead of using the default VPC.
Key design choices:

DNS resolution and DNS hostnames enabled, required for ALB and ECS task name resolution
An Internet Gateway attached to allow outbound internet connectivity
Two public subnets, each in a different Availability Zone
Automatic public IP assignment enabled for ECS tasks and the ALB
A public route table with a default route to the Internet Gateway

This design ensures:

High availability across AZs (ALB requires at least two subnets in different AZs)
Proper routing for ECS tasks and load balancer traffic


2. Security Groups
Two separate security groups were created to enforce least privilege:
ALB Security Group

Allows inbound HTTP traffic only from a specific IP address
Outbound traffic fully open to support health checks and backend communication

ECS Task Security Group

No public inbound access
Allows inbound traffic only from the ALB on port 80
Outbound traffic allowed for:

pulling container images
sending logs to CloudWatch
accessing external services



This ensures ECS tasks are never directly exposed to the internet.

3. Outputs and Locals
Outputs were created to expose key infrastructure details after deployment:

VPC ID
Public subnet IDs
Application URL (via ALB)

A local value (public_subnets) was introduced to improve readability and avoid repeating subnet references across resources.

4. Variables
The following variables were introduced:

region
vpc_cidr
allowed_ip

These make the deployment:

reusable across regions
configurable without code changes

allowed_ip intentionally has no default value, requiring user input at apply time to prevent hardcoding sensitive data.

5. ECS and Application Load Balancer
ECS Components

ECS Cluster: logical grouping for services and tasks
Execution IAM Role: allows ECS to pull images and write CloudWatch logs
AWS-managed execution policy
Task Definition:

NGINX container image
CPU and memory configuration
Port mappings
Logging configuration


ECS Service:

maintains desired task count
integrates with the ALB
performs health checks and deployments



ALB Components

Application Load Balancer (entry point)
Target Group (ECS tasks register as targets)
Listener (HTTP on port 80)


6. Terraform State
Terraform state is stored remotely in an S3 backend for durability and team safety.
Because the backend must exist before Terraform initialises, the backend S3 bucket was created manually. The bucket has:

public access blocked
versioning enabled


Part 2: Improvements and Hardening (After)
1. CloudFront Integration and HTTPS
Initially, the application was only accessible over HTTP, which is insecure.
CloudFront was introduced to:

terminate TLS/HTTPS at the edge
provide AWS Shield DDoS protection
enable WAF integration
act as the single public entry point

Using CloudFront with ACM:

provides a trusted *.cloudfront.net TLS certificate
requires no domain ownership or manual certificate validation
avoids sandbox restrictions related to Route53 and ACM

Traffic flow after this change:

Browser → CloudFront (HTTPS, TLS validated)
CloudFront → ALB (HTTP over AWS private backbone)
ALB → ECS tasks (HTTP on port 80)
Response flows back through the same path

TLS is terminated once at the edge, a common best practice known as TLS termination, reducing container complexity and overhead.

2. Blocking Direct ALB Access
After introducing CloudFront, the ALB should no longer be directly accessible.
To enforce this:

The ALB default listener action was changed to a fixed 403 response
A listener rule was added requiring a shared‑secret HTTP header
Only requests matching this header are forwarded to the target group

This ensures:

only CloudFront-originated traffic reaches ECS
direct ALB access is blocked


3. Web Application Firewall (WAF)
To meet the requirement of restricting public access to specific IPs, AWS WAF was added.
Why WAF:

CloudFront is now the public entry point
ALB no longer sees real client IPs
Security groups cannot inspect HTTP‑level data

WAF capabilities:

IP filtering
protection against SQL injection, XSS, malformed requests
request inspection at the edge

Implementation steps:

Created IPv4 and IPv6 IP sets
Web ACL with default action BLOCK
Allow rule tied to the approved IP set
Associated the Web ACL with the CloudFront distribution

IPv6 issue encountered
Modern browsers use Happy Eyeballs (IPv6 preferred). This caused unexpected 403s when only IPv4 was allowed.
Resolution:

IPv6 IP set explicitly disabled
IPv6 disabled at the CloudFront distribution level

This ensured consistent behaviour across browsers.

4. CloudWatch Monitoring
Two CloudWatch alarms were created:

CPU utilisation alarm

Alerts when average CPU exceeds 80%


Memory utilisation alarm

Critical because memory exhaustion causes immediate task termination on Fargate



Important learning:

These alarms are for observability
ECS autoscaling does not use these alarms


5. ECS Service Autoscaling
Autoscaling was introduced to make the platform self‑healing and resilient.

Application Auto Scaling with target tracking
Scales the desired count between 1 and 4 tasks
Two policies:

CPU-based target tracking (60%)
Memory-based target tracking (70%)



Benefits:

Automatic scale‑out during traffic spikes
Gradual scale‑in as load decreases
Prevents memory‑driven task failures

Autoscaling operates independently of CloudWatch alarms, maintaining a clean separation between:

automation (autoscaling)
human visibility (alarms)


Part 3: Observability and Logging Design
The target logging architecture consisted of:

CloudFront access logs
ALB access logs
WAF decision logs via Kinesis Data Firehose
A central S3 bucket for log storage

Intended benefits:

request‑level visibility at the edge
clear explanation of WAF allow/block decisions
troubleshooting of unexpected 403 responses
validation of security posture

Kinesis Data Firehose
AWS WAF requires Firehose because WAF generates real‑time security events, not completed access logs. Firehose ensures asynchronous delivery without impacting request evaluation.

Sandbox Environment Limitations
Despite correct configuration, multiple logging features could not be activated due to sandbox account restrictions:

WAF logging to Firehose rejected with “The ARN isn’t valid” despite valid configuration
ALB access logging failed with “Access denied for bucket”
CloudFront access logging failed due to ACL restrictions
Service‑managed log delivery to S3 is restricted

These issues persist even with:

correct IAM policies
correct regions
correct dependencies
correct resource sequencing

Final sandbox decision
The following were commented out:

CloudFront access logging
ALB access logging
WAF logging configuration
Kinesis Firehose
Logging S3 bucket

This ensures:

clean Terraform apply
fully functional application
production‑ready code remains visible


Final Outcome
What works in the sandbox:

CloudFront HTTPS endpoint
WAF enforcement and IP restriction
Secure ALB design
ECS service with autoscaling
ECS logs in CloudWatch
High availability and resilience

What is designed but disabled:

Centralised S3 logging (blocked by sandbox)
Firehose (WAF logs blocked by the sanbox)
CloudFront Logs (Blocked by Sandbox)
ALB Logs (Blocked by Sandbox)
Conclusion
This project demonstrates a secure, scalable, and production‑ready AWS architecture.
While sandbox restrictions limited the activation of service‑managed logging, the design follows AWS best practices and would function without modification in a standard AWS account.
The work reflects real‑world AWS engineering trade‑offs, security hardening, and operational awareness.