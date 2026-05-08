Purpose

This document records the reasoning, trade-offs, and implementation steps taken to
incrementally harden and improve the environment. It complements, but does not replace,
the main architecture documentation.


The first change I would like to do is to create the environment more secure.
1. **CloudFront integration + ACM**
By default CF was built for caching, static content and Global Performance.
However modern CF also solves :
    TLS/HTTPS termination
    DDoS protection (via AWS Shield)
    WAF integration
    Bot protection
Currently my enviroment receives requests through HTTP which is insecure due to not verifying certificates and the traffic is not ecnrypted which can cause man in the middle attack as the traffic can be intercepted.
Initially I wanted to use ACM + ALB however this requires a domain and as I am in a Sandbox environment, the best way to make this secure is through CF and this would not involve any costs. Also after the research I've done the Sandbox is restricting the following :
    restrict Route 53 public zones
    restrict IAM permissions related to certificates
    restrict validation methods
    restrict internet‑facing DNS changes
CF always speaks HTTPS to the browser.
ACM + CF =  Cloudfront will provide a domain with a valid cert .cloudfront.net which:
    is globally trusted
    is auto‑rotated
    is invisible to you
    requires zero setup
        -CloudFront presents a TLS certificate
        That certificate:
        -Is issued by AWS via ACM
        -Covers *.cloudfront.net
        -Is trusted by all major browsers
        -TLS handshake succeeds
        -Traffic is encrypted
With CF integration, ALB will not be the front door anymore so is not exposed directly to the internet and the responsabilties that remain are :
    Path‑based routing
    Health checks
    Target group management
    ECS integration
    Availability zone redundancy

One thing that I've questioned was what about the traffic within the envinroment? Shouldn't this be HTTPS aswell ?
Well the answer is no as the traffic between CF<->ALB and ALB<->ECS stays between the private backbone, packets never traverse the p.internet and the risk profile is different.The TLS is terminated once at the edge and the benefits are:
    simpler ECS tasks
    no cert management inside containers
    no TLS overhead on every task
This practice is called TLS termination.

How the traffic actually flows now :
            1. Browser > CF
        GET https://blablalba.cloudfront.net/
        a. Browser validates the TLS Certificate
        b. Ecrypted tunnel established
        C. Browser trusts AWS
            2. CF > ALB
        a. CF forwards the traffic to its origin
            3. ALB > ECS Task
        a. ALB picks a healthy target
        b. ALB forwards the requests to the tasks ENI
        c. Uses HTTP on port 80
            ECS task:
        a.Receives the request
        b.NGINX serves the response
            4. Flowback response:
    ECS > ALB > CF > Browser

Although my application is now exposed publicly via HTTPS through Cloudfront which acts as the secure edge layer, my next concern is the fact the the ALB is left open and I can still reach it through a HTTP request directly to the web application and is not intended to be accessed directly by end users.
The way I have designed this to work is by blocking direct access to the Application Load Balancer. I did this by changing the default ALB listener action from forward to a fixed response, so any request that does not meet my conditions is rejected.
Access to the ALB is now only allowed if a specific shared‑secret header is present. To achieve this, I created an additional ALB listener rule that checks for this header and only forwards the request to the target group when the secret value matches.
This ensures that requests coming from CloudFront are allowed, while any direct access to the ALB URL is blocked.

2. **WAF (Web Application Firewall)**
The next logical improvement for this environment is to look back at the assessment request which was "Restrict public access to specific IP addresses."
WAF acts like a bouncer for web traffic, standing between the internet and the application.
WAF can inspect:
-Source IP address
-HTTP method (GET, POST, etc.)
-URI path
-Query string
-Headers
-Cookies
-Request body (up to a limit)

This means WAF can answer questions like:

“Is this request coming from my IP?”
“Is this a known bad pattern?”
“Is someone trying SQL injection?”
“Is this a bot scraping my app?”

Security groups cannot do any of this.

Since CloudFront is now the front door , ALB no longer sees the real client IP so WAF is the correct tool as now I can create an IP Set (allowed Ip addresses) with a rule " If request IP is not in this list > block the request" 
The reason why WAF is better than IP restriction at the ALB is because the direct ALB access is blocked and cloudfront is the only entry point. Without WAF any IP can reach CF which means public access is not yet restricted.
Once WAF is added:
    Only approved IPs reach CF
    ALB never sees unwanted traffic
    ECS never sees unwanted traffic
Also the security is improved as WAF can protect against SQL injection attempts, XSS atacks and malformed requests.

WAF attaches to the edge and entry-service points such as :
    -CloudFront
    -ALB
    -APi Gateway
In my architechture the correct point is Cloud front as this is my public entry point,CF sees the real IP Address and it receives requests before it hits the VPC.

Steps taken  :
    a.I have create and IP set for allowed IP addresses which requires the input from the user of the IP address.
    b.I have created an ACL with a default action of block, ensuring a deny‑by‑default security posture
    c.I have created an Allow rule that permits traffic only when the request originates from the approved IP Set
    d.I have associated the WEB ACL with the Cloudfront distribution so all incoming requests are evaluated by the WAF before allowing access to the backend.

# The issue I've encountered here was that although the terraform code was correct, I was still get 403 error. After a bit of research this was caused by the alghorithm used by the modern browsers called Happy Eyeballs.
    The browser tries IPv6 first, if available
    If IPv6 connects successfully, it never falls back to IPv4
    Even if IPv4 would succeed
# The way I've diagnosed what the issue was is by applying both IPv4 and IPv6 :
   terraform apply \
  -var='allowed_ipv4_cloudfront=["x.x.x.x/32"]' \
  -var='allowed_ipv6_cloudfront=["yyyy::zzzz/128"]'
# And after that, using the curl command : curl -4 xxxxxx.cloudfront.net and curl -6 xxxxxx.cloudfront.net  . Curl -4 was a success however the browser was still getting the 403 error.
The way I have approached the fix was by disabling the IPv6 access at CloudFront so instead of inputing the ip address I use [] and also I have disabled the IPv6 in Cloud Distribution resource , see example : 
terraform apply \
  -var='allowed_ipv4_cloudfront=["x.x.x.x/32"]' \
  -var='allowed_ipv6_cloudfront=[]'
Now I can confirm that public access is restricted to specific IP addresses at the CloudFront layer, while backend infrastructure is shielded from direct internet access

The next improvement I would like to make is to add monitoring and auto-scaling for the ECS on Fargate.
3. **CloudWatch Monitoring**

I have created two alarms
    a. CPU Utilisation Alarm
This CloudWatch alarm monitors the average CPU utilisation of an ECS service running on Fargate.
It evaluates CPU usage every 60 seconds, and if the CPU exceeds 80% for one evaluation period, the alarm enters the ALARM state.
The alarm is scoped specifically to a single ECS service using the ClusterName and ServiceName dimensions.
    b.Memory Utilisation Alarm
The reason why I have created a Memory Utilisation Alarm is because when an ECS Task running on Fargate runs out of memory, the container is killed immediately and the request fails. ECS might restart the task but users still experience errors.
In ECS/Fargate environments, AWS implicitly expects:
CPU alarms → performance indicators
Memory alarms → stability/safety indicators
# At there point I thought that the CloudWatch Monitoring alarms are meant to be used for the Autoscaling but actually they are for observability. After some research I've discovered that Autoscaling its using its own CPU/Memory readings and policies. Autoscaling does not depend on the alarms I've created.

4. **Application Autoscaling**
Autoscaling:
-Reads CloudWatch metrics directly
-Uses scaling policies, not alarms
-Reacts continuously not discretely

ECS Service Autoscaling
After implementing observability using CloudWatch metrics and alarms, the next improvement was to make the environment self‑healing and adaptive under load by enabling autoscaling for the ECS service running on Fargate.
The purpose of autoscaling is to allow the ECS service to automatically adjust the number of running tasks based on resource consumption, instead of relying on manual intervention. This ensures that the application can handle increases in load while maintaining performance and stability.
Why autoscaling is required
In its initial state, the ECS service was running with a static number of tasks. This means:

During traffic spikes, tasks could become overloaded
CPU and memory utilization could exceed safe thresholds
Performance degradation or task failures could occur

Autoscaling solves this by continuously reacting to real‑time metrics and adjusting capacity accordingly. This shifts the service from a reactive model to a proactive and resilient design.
Autoscaling model used
For this setup, Target Tracking Scaling was chosen, which is the recommended approach for ECS on Fargate.
Instead of defining static rules such as:

“Add 1 task when CPU exceeds X%”

Target tracking allows AWS to continuously evaluate resource usage and try to maintain a stable target value. AWS automatically decides when to scale out or scale in, reducing the risk of aggressive or oscillating scaling behaviour.
Scalable target definition
The first step was to register the ECS service as a scalable target using Application Auto Scaling. This defines what can scale and within what boundaries.
In this configuration:

The ECS service can scale between 1 and 4 running tasks
The scaling action applies to the DesiredCount of the service
Scaling is scoped to a specific ECS service within a specific cluster

This ensures that the service always has a minimum level of availability while preventing uncontrolled scaling.
CPU‑based autoscaling
The first autoscaling policy is based on average CPU utilization across all running tasks in the ECS service.
Key characteristics:

The target CPU utilization is set to 60%
When CPU usage increases above this value, new tasks are added
When CPU usage decreases, tasks are removed gradually
Scale‑out occurs faster than scale‑in to absorb sudden spikes
Cooldown periods are applied to avoid rapid scaling fluctuations

This allows the service to remain responsive during increased demand without becoming over‑provisioned when load decreases.
Memory‑based autoscaling
In addition to CPU, a second autoscaling policy was introduced based on memory utilization.
This is especially important for ECS on Fargate because:

Memory exhaustion results in immediate task termination (OOM kill)
Unlike CPU throttling, memory pressure causes hard failures
Memory usage typically grows over time and does not recover without scaling or restarts

For this reason:

The memory target value is set to 70%
Scaling behaviour is aligned with CPU scaling cooldowns
Autoscaling reacts before tasks approach unsafe memory levels

Using both CPU and memory policies ensures the service scales correctly for performance requirements and stability risks.
Relationship to CloudWatch alarms
It is important to clarify that autoscaling does not rely on CloudWatch alarms.
The CloudWatch alarms that were created earlier serve observability purposes only, allowing operators to see when thresholds are exceeded and investigate issues. Autoscaling policies, on the other hand, read CloudWatch metrics directly and make scaling decisions independently.
This separation ensures:

Alarms inform humans
Autoscaling reacts automatically
No dependency between alerting and scaling logic

Resulting behaviour
With autoscaling enabled:

The ECS service automatically increases capacity under load
Tasks are scaled down when demand decreases
Performance remains stable without manual scaling
Resource limits are respected, reducing the risk of failures

This completes the transition from a static ECS deployment to a dynamic, self‑adjusting service aligned with AWS best practices for ECS on Fargate.

5. **Improved observability**
Although I have built some observability I don't think this is enough and more logs should be accessible. These logs would help with troubleshooting and understanding the bigger picture of the architechture as-well as helping with improving the services and how they work.
### Cloudfront Logs
As CloudFront is acting as the secure edge and all public traffic flows through it, the next improvement is to increase visibility at the entry point by enabling CloudFront access logs. 
At this stage of the architecture, traffic is already restricted and protected, but without logs there is no easy way to understand how requests behave once they hit the edge
Because CloudFont is the first public-facing component, it is most valuable place top gain insight into incoming traffic. CloudFront logs provide visibility over the requests which is essential for diagnossing issues and validating security controls.
By enabling access logs, I gain visibility into:
-The client IP address seen by CloudFront
-Requested paths and HTTP methods
-HTTP response status codes (200, 403, 404, 5xx, etc.)
-Whether requests were served or blocked (including WAF interaction)
=Request timing and volume patterns
If the user gets a 403 unexpected response the way I got earlier, CloudFront logs are the first place to look at.

CloudWatch metrics and alarms already provide aggregated visibility (CPU, memory, scaling behaviour), but they do not show individual requests.
CloudFront access logs complement metrics by answering questions such as:
-Which IP made the request?
-Which path was accessed?
-Was the request blocked by WAF?
-Is traffic coming from unexpected locations?
-Are clients receiving errors or cached responses?

### WAF Logs
While CloudFront logs show what requests reach the edge and what response was returned, they do not explain why a request was allowed or blocked. WAF logs fill this gap by providing decision‑level visibility for security rules.
Because WAF is now responsible for enforcing IP‑based access control and protecting against malicious traffic, monitoring its decisions is critical for troubleshooting and validating security behaviour.
Why WAF logs are required
Without WAF logs, any blocked request appears simply as a 403 response at CloudFront. There is no visibility into:
Which WAF rule triggered
Which condition failed
Which IP address was evaluated
Whether the block was intentional or a misconfiguration

This was already observed during the debugging process when valid traffic was being blocked due to IPv6 behaviour. Without WAF logs, distinguishing between an IP restriction issue, an IPv6 mismatch, or a misconfigured rule becomes guesswork.
WAF logs allow answering questions such as:
Why was this request blocked?
Which rule enforced the block?
Was the request evaluated as IPv4 or IPv6?
Are there false positives occurring?

**What WAF logs contain**
WAF logs provide structured, security‑focused data, including:
Source IP address
Matched rule ID and rule name
Action taken (ALLOW, BLOCK, COUNT)
Web ACL name
Request details (URI, headers, HTTP method)
Reason codes for the decision

Because WAF operates at the edge, it is the only service capable of explaining security enforcement decisions in this architecture.

### Kinesis Data Firehose
Kinesis Data Firehose is required in order to enable logging for AWS WAF.
The way I wanted to set up the logging architecture was to use a single S3 bucket to centralise all logs. However, during this process it became clear that there is an important difference between how logs are generated by services such as CloudFront, ALB, and ECS, and how logs are generated by AWS WAF.
For example, ALB access logs are written after a request has been fully processed. These logs represent completed HTTP requests and include information such as response codes, latency, and target responses. Because the request has already finished, these logs can be safely batched and written directly to S3 without impacting request handling or application performance.
AWS WAF behaves differently. WAF produces real‑time security decision events rather than traditional access logs. Each event represents how WAF evaluated a request and why a specific action (ALLOW or BLOCK) was taken. Because WAF operates as a real‑time security enforcement engine, logging must never delay or interfere with request evaluation, especially during traffic spikes or attacks.
For this reason, AWS requires WAF logs to be streamed via Kinesis Data Firehose rather than written directly to S3.
Amazon Kinesis Data Firehose is a managed log‑delivery service. It is not a monitoring tool and it is not a streaming analytics platform. Its sole purpose is to reliably deliver large volumes of event data from AWS services to downstream destinations while remaining completely decoupled from the service generating the logs.
Firehose:

Is fully managed (no servers to provision or scale)
Buffers and batches log records
Handles retries and temporary delivery failures
Delivers data to destinations such as:
Amazon S3
CloudWatch Logs
Amazon OpenSearch
Is not queried directly; it simply acts as a delivery pipeline
By using Firehose, AWS WAF can emit security‑critical events immediately while log delivery happens asynchronously in the background. This ensures that security enforcement at the edge remains fast and reliable, while still providing full visibility into WAF decisions through stored logs.

###### AWS WAF logging to Kinesis Data Firehose was configured correctly.. However, due to sandbox account restrictions, the logging configuration could not be activated, despite correct IAM policies, regional alignment, and dependency ordering. This limitation is specific to the sandbox environment and would not apply in a standard AWS account.
Regardless of what I have been trying, I am getting : The ARN isn't valid.
Even thoughm the ARN is valid, Firehose exists, the region is correct and the IAM Roles is correct.
###### ALB access logging and WAF logging to Kinesis Firehose were implemented correctly. However, the sandbox environment restricts service‑managed log delivery to S3, preventing these features from being activated despite correct permissions.
InvalidConfigurationRequest: Access Denied for bucket: procode-logs-23105422
###### CloudFront logging is also restricted and cannot be used in Sandbox envirnomnent. 
###### S3 bucket has also been commented as this can not be used for its intent at the moment.
cloudfront-access-logs/
alb-access-logs/
waf-logs/
**I have commented all the above logging services to show the work was carried out however due to the Sanbox restricitons, those can not be seen working.**
