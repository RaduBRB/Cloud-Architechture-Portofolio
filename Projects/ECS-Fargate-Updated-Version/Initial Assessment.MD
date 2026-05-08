
1. VPC
To challange myself I've decided to go with the route of creating my own VPC although using the one provided by AWS would've been the easier option.
I created the VPC with DNS enabled so the ECS and ALB can resolve names. I attached the internet gateway to allow outbound access to the internet.I then created two public subnets in different Availability Zones, each configured to automatically assign public IPs. I created a public route table with a default route to the internet gateway and associated with both subnets. This makes the subnets public and allows the ALB and ECS to operate correctly.
Is worth mentioning that an ALB requires a minimum of two subnets, each launched a different AZ for availability.

2. Security Groups
I created two security groups. One for the load balancers and one for the ECS Tasks.
The ALB security group allows inbound HTTP traffic only from a specific IP address which achieves the request of restricting the public access. The outbound traffic is fully open so the ALB can perfom health checks and communicate with the tasks.
The ECS security group does not allow any public access and only accepts traffic from the ALB subnets on port 80. This ensures that the containers are never exposed to internet directly and can only be reached  through the load balancer. Outbound traffic is allowed so tasks can pull the images, send logs and reach external services.

3. OUTPUTS
I have created the Outputs to so the Key information is easily accessible after deployment. The VPC ID and the public subnet IDs are useful for debugging, and documentation but acccording to AWS Documentation they can also be used for expansion of the environment. The application URL output provides a direct ink to the load balancer , allowing quick verification that the containerised web application is running correctly.
I have created a local value called public_subnets to make the code easier to read and avoid repeating values. The locals are calculated from the resources.

4. Variables
I created the following variables:
 region
 vpc_cidr
 allowed_ip
So the deployment can be reused in a different AWS region if needed without modifying the code. This makes the configuration more flexible.
I created an allowed_ip variable to restrict access to the ALB. I intentionally did nto a default value so the Terraform prompts the user to provide the correct IP for ALB access at the deployment time. This prevents hardcoding sensitive data.

5. ECS + ALB
The next step was to create the ECS + Application Load Balancer which together run and expose the containerised web application. 
ECS Components :
    1.ECS Cluster - This is a logical grouping of the ECS resourcess. The cluster is required as the logical container for services and tasks.Without a cluster, I won't be able to run an ECS Service.
    2.IAM Execution Role - This allows ECS to pull images and publish logs in CloudWatch.
    3.AWS Managed Policy - This policy gives ECS permission for pulling images from ECR, write CloudWatch logs.
    4.Task Definition -  This defines the following:
                                    - Container Image (Nginx in my case)
                                    - CPU/Memory
                                    - Port Mappings
                                    - Evironmnetal Variables
                                    - Logging Configuration
    5. ECS Service - The service is what keeps the desired number of tasks running, integrates with the ALB for traffic routing and handles the deployments and health checks.
    6. Application Load Balancer - The ALB is what decides where the traffic is directed in order for the service to be hihgly available
                                 - The ALB components :
                                        - Application Load Balancer  - the entry point for the traffic (receives the HTTP/s requests and directs them across multiple ECS Tasks )
                                        - Target Group - groups the tasks together and contains the list of destinations the ALB can send traffic to. The ECS Tasks register themselves as targets.
                                        - Listener - is the port and protocol that the ALB listens on

6. Terraform State
Terraform stores state locally by default; however, for this project, state is stored remotely in an S3 backend so it is not tied to a single machine and avoids accidental state loss.
Because the backend must exist before Terraform can initialise and manage resources, the S3 bucket is created beforehand in the AWS Console; otherwise, the backend would not work.
The S3 bucket has public access blocked and versioning enabled.

