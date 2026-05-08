============================================================
                 CLOUD PROJECT ARCHITECTURE (ASCII)
============================================================

                         +--------------------+
                         |     GitHub Repo    |
                         |  (App + Terraform) |
                         +---------+----------+
                                   |
                                   | Push code
                                   v
                     +-------------------------------+
                     |        GitHub Actions         |
                     |  (CI/CD Pipeline with OIDC)   |
                     +-------------------------------+
                       |        |             |
                       |        |             |
                       |        |             |
                       |        |             |
                       |        |             |
        Build Docker   |        |  Authenticate to AWS (OIDC)
        Image          |        |
                       v        v
                +---------------------+
                |   Docker Image      |
                +----------+----------+
                           |
                           | Push image
                           v
                +-----------------------------+
                |      AWS ECR Repository     |
                | (Stores container images)   |
                +--------------+--------------+
                               |
                               | New image version
                               v
                +-----------------------------+
                |       AWS ECS Fargate       |
                |  (Runs containerized app)   |
                +--------------+--------------+
                               |
                               | Registers tasks
                               v
                +-----------------------------+
                |  Application Load Balancer  |
                |   (Public entry point)      |
                +--------------+--------------+
                               |
                               | HTTP/HTTPS
                               v
                +-----------------------------+
                |        End Users            |
                |  (Access the application)   |
                +-----------------------------+


============================================================
                 NETWORK + INFRASTRUCTURE LAYER
============================================================

                    +-----------------------------+
                    |            VPC              |
                    |  (Isolated cloud network)   |
                    +-----------------------------+
                       |                     |
                       |                     |
             +----------+----+       +-------+-----------+
             |  Public Subnet |       |  Private Subnet  |
             | (ALB lives here)|       | (ECS tasks here)|
             +-----------------+       +------------------+

                       +-----------------------------+
                       |     Internet Gateway        |
                       | (Allows public access)      |
                       +-----------------------------+


============================================================
                    IAM + SECURITY OVERVIEW
============================================================

- GitHub → AWS authentication uses OIDC (no stored AWS keys)
- ECS Task Role controls what the app can access
- Security Groups:
    - ALB SG: allows inbound HTTP/HTTPS
    - ECS SG: only allows traffic from ALB
- Least privilege IAM policies for:
    - ECR push/pull
    - ECS deployments
    - Terraform provisioning

============================================================
END OF ASCII ARCHITECTURE DIAGRAM
============================================================
