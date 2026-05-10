====================================================================
                          PURPOSE
====================================================================

This project documents the process of deploying a containerised
application on AWS using ECS Fargate, with a focus on understanding
how the system behaves when things do not work as expected.

The objective was not just to deploy the application, but to:

    - Understand the interaction between ECS, networking and CI/CD
    - Debug real issues across multiple layers
    - Fix those issues step by step


====================================================================
                        ARCHITECTURE
====================================================================

Final setup after fixes:

          Internet
              |
              v
     +----------------------+
     |  ALB (Public Subnet) |
     +----------------------+
              |
              v
        +-------------+
        | Target Group|
        +-------------+
          |        |
          v        v
 +-------------------+   +-------------------+
 | ECS Task (AZ1)    |   | ECS Task (AZ2)    |
 | Private Subnet    |   | Private Subnet    |
 +-------------------+   +-------------------+
         |                         |
         v                         v
 +-------------------+   +-------------------+
 | NAT Gateway (AZ1) |   | NAT Gateway (AZ2) |
 +-------------------+   +-------------------+
              |
              v
          Internet
              |
              v
           AWS ECR


Application images are built and pushed using GitHub Actions,
and ECS pulls the image from ECR during startup.


====================================================================
                    DEPLOYMENT FLOW (CI/CD)
====================================================================

    Git Push
        |
        v
    GitHub Actions
        |
        v
    Build Docker image
        |
        v
    Tag image:
        - commit SHA
        - latest
        |
        v
    Push to ECR
        |
        v
    ECS force deployment


====================================================================
                  MAIN ISSUES ENCOUNTERED
====================================================================


--------------------------------------------------------------------
1. ECS TASKS STUCK IN PENDING
--------------------------------------------------------------------

Initial issue:

    ECS tasks were stuck in PENDING and never reached RUNNING

At first, the assumption was that ECS itself was misconfigured.

After checking logs and task events, the issue turned out to be
network-related.

Setup at the time:

    Tasks deployed in public subnet
    assign_public_ip = false

Result:

    ECS task had no internet access
    → could not reach ECR
    → could not pull container image
    → task remained in PENDING

Fix:

    Move ECS tasks to private subnets:

        subnets = private_subnets
        assign_public_ip = false

Learning:

    Public subnet without public IP does not provide outbound
    connectivity, even though it appears to be internet-facing.


--------------------------------------------------------------------
2. INCONSISTENT TASK STARTUP (NAT / AZ ISSUE)
--------------------------------------------------------------------

After fixing subnet placement, behaviour was still inconsistent.

Observed behaviour:

    Some tasks would start successfully
    Others would fail with timeouts

This made troubleshooting confusing as the setup looked correct.

Root cause:

    Multiple private subnets across different AZs were used
    but only one NAT Gateway existed

Result:

    Tasks running in AZ with NAT → worked 
    Tasks running in AZ without NAT → failed 

Fix:

    Create NAT Gateway per AZ
    Ensure each private subnet routes to its respective NAT

Learning:

    NAT must be available per AZ for ECS to reliably initialise
    tasks. Otherwise behaviour becomes intermittent.


--------------------------------------------------------------------
3. IMAGE PULL FAILURE (TAG MISMATCH)
--------------------------------------------------------------------

After resolving networking issues, tasks still failed to start.

Error:

    CannotPullContainerError
    :latest not found

At first, this looked like a Docker or build issue.

Actual problem:

    ECS was configured to pull the "latest" tag
    but the pipeline was only pushing commit SHA tags

Result:

    ECS tried to pull :latest
    but ECR did not contain it
    → image not found

Fix:

    Update pipeline to push both:

        :latest
        :commit SHA

Learning:

    ECS only pulls the exact tag defined.
    The pipeline must push the same tag that ECS expects.


====================================================================
                         SECURITY MODEL
====================================================================

- ECS tasks run in private subnets
- No public IPs assigned
- ALB is the entry point
- Security groups allow only ALB → ECS traffic
- GitHub Actions uses OIDC (no static AWS credentials)


====================================================================
                         FINAL STATE
====================================================================

After all fixes:

    ECS tasks RUNNING 
    Target group HEALTHY 
    Application accessible via ALB 
    CI/CD pipeline working 


====================================================================
                         KEY TAKEAWAYS
====================================================================

- Most issues were related to networking, not application code

- ECS task failures are often indirect and require checking
  logs and infrastructure together

- Multi-AZ setups require correct NAT configuration

- CI/CD configuration must match runtime expectations
  (especially when using image tags)

- The biggest learning came from debugging rather than
  initial deployment


====================================================================
                          FINAL NOTE
====================================================================

This project represents a debugging-driven learning process.

The application itself was simple, but getting it to run
correctly required understanding:

    - ECS task lifecycle
    - VPC networking
    - NAT behaviour
    - CI/CD integration

The final result is a working system, but the main value was
in understanding why it originally failed.
====================================================================
