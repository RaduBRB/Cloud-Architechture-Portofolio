============================================================
              CLOUD PORTFOLIO PROJECT OVERVIEW
============================================================

GOAL OF THE PROJECT
------------------------------------------------------------
Build a real-world cloud deployment pipeline using:

- AWS ECS Fargate (to run the application)
- AWS ECR (to store container images)
- Terraform (to create all cloud infrastructure as code)
- GitHub Actions (to automate deployments)
- OIDC (to let GitHub authenticate to AWS securely)

This project demonstrates the core skills needed for cloud roles:
Infrastructure as Code, CI/CD, containers, networking, IAM, and
cloud architecture.

------------------------------------------------------------
HIGH-LEVEL ARCHITECTURE (PLAIN ENGLISH)
------------------------------------------------------------

1. You write code and push it to GitHub.
2. GitHub Actions automatically:
   - Builds a Docker image of your app
   - Pushes the image to AWS ECR
   - Updates ECS to deploy the new version
3. ECS Fargate runs the container without needing servers.
4. An Application Load Balancer exposes the app to the internet.
5. Terraform defines and deploys all AWS resources.

This is a real production-style workflow used by cloud teams.

------------------------------------------------------------
WHY THIS PROJECT MATTERS
------------------------------------------------------------

This project proves you understand:

- How cloud applications run in containers
- How to automate infrastructure with Terraform
- How CI/CD pipelines work in real companies
- How to design secure, scalable cloud systems
- How to use modern DevOps tools

It becomes a strong portfolio piece for cloud engineering roles.

------------------------------------------------------------
PROJECT PHASES (STEP-BY-STEP)
------------------------------------------------------------

PHASE 1 — LEARN THE CONCEPTS
- What Terraform is and why it's used
- What ECS Fargate is and why containers matter
- What ECR is and how images are stored
- What GitHub Actions is and how CI/CD works
- What OIDC is and why it's more secure than AWS keys

PHASE 2 — BUILD THE INFRASTRUCTURE (TERRAFORM)
Terraform will create:
- VPC
- Subnets
- Internet Gateway
- ECS Cluster
- Task Definition
- Fargate Service
- Application Load Balancer
- Security Groups
- ECR Repository
- IAM Roles for GitHub OIDC

Recommended folder structure:

infra/
  modules/
    vpc/
    ecs/
    ecr/
  env/
    dev/
      main.tf
      variables.tf
      outputs.tf

PHASE 3 — BUILD THE APPLICATION
A simple web app (Node.js or Python) with one endpoint.
Containerized using a Dockerfile.

Example Dockerfile:

FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
CMD ["node", "index.js"]

PHASE 4 — BUILD THE CI/CD PIPELINE (GITHUB ACTIONS)
Pipeline tasks:
1. Authenticate to AWS using OIDC
2. Build Docker image
3. Push image to ECR
4. Update ECS task definition
5. Deploy new version automatically

PHASE 5 — DOCUMENTATION + PORTFOLIO
Create a README that explains:
- What you built
- Why you built it
- Architecture diagram
- How Terraform works
- How CI/CD works
- Screenshots of AWS console

------------------------------------------------------------
WHAT TO TELL ANY AI ON ANY COMPUTER
------------------------------------------------------------

"I am building a cloud portfolio project where I deploy a
containerized web app to AWS ECS Fargate using Terraform for
infrastructure and GitHub Actions for CI/CD. The architecture
includes VPC, subnets, ALB, ECS cluster, ECR, IAM roles, and
OIDC authentication. I need help continuing from where I left off."

============================================================
END OF PROJECT OVERVIEW
============================================================
