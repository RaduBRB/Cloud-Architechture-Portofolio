============================================================
                 TERRAFORM + APP FOLDER STRUCTURE
============================================================

Project-Root/
|
+-- app/                          <-- Application code
|    |
|    +-- src/                     <-- Your app files (Node/Python)
|    |     index.js
|    |
|    +-- package.json             <-- Dependencies (Node example)
|    +-- requirements.txt         <-- (Python example, optional)
|    +-- Dockerfile               <-- Container build instructions
|
|
+-- infra/                        <-- Terraform infrastructure
|    |
|    +-- modules/                 <-- Reusable Terraform modules
|    |      |
|    |      +-- vpc/              <-- VPC, subnets, IGW
|    |      |     main.tf
|    |      |     variables.tf
|    |      |     outputs.tf
|    |      |
|    |      +-- ecs/              <-- ECS cluster, service, task def
|    |      |     main.tf
|    |      |     variables.tf
|    |      |     outputs.tf
|    |      |
|    |      +-- ecr/              <-- ECR repository
|    |            main.tf
|    |            variables.tf
|    |            outputs.tf
|    |
|    +-- env/                     <-- Environment-specific configs
|          |
|          +-- dev/               <-- Dev environment
|                main.tf
|                variables.tf
|                outputs.tf
|
|
+-- .github/
|      |
|      +-- workflows/
|             deploy.yml          <-- GitHub Actions CI/CD pipeline
|
|
+-- README.md                     <-- Documentation + diagrams
|
+-- .gitignore
|
============================================================
END OF FOLDER STRUCTURE DIAGRAM
============================================================
