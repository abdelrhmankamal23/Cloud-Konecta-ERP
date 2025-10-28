# Module Purpose Explanation in Plain English

## What This Module Does

This CloudWatch module is like a **security guard and health monitor** for your Kubernetes cluster (EKS). It watches your system and alerts you when something goes wrong.

### What happens when alerts trigger

1. System detects high CPU or memory usage
2. Sends notification through SNS topic (like sending a text message)
3. You get alerted to fix the problem before users are affected

---

## Security Point of View

### Why Security Matters Here

Even though this is "just monitoring," it can reveal sensitive information about your system like:

- When your system is under attack (high CPU spikes)
- Your system's capacity and weaknesses
- When you're most vulnerable (low resources)
- Internal system names and configurations

### Security Measures We Implemented

#### 1. Encrypted Notifications

`kms_master_key_id` to define which specific encryption key to use for encrypting the SNS topic messages,`alias/aws/sns` is a built-in encryption key specifically designed for SNS topics.  

This means:  

- All messages stored in the topic are now encrypted
- Only your AWS account can decrypt and read them

#### 2. Limited Log Retention

`retention_in_days = 14` to automatically delete CloudWatch logs after 14 days instead of keeping them forever.

This means:

- Less data stored = less risk if breached
- Meets compliance requirements for data retention
- Reduces storage costs

#### 3. Secure Access Control

Using AWS IAM permissions and encrypted resources so only authorized AWS services can access the monitoring data.

This means:

- Even people with some AWS access can't easily read monitoring messages
- Only your specific AWS resources can decrypt and use the data
- Prevents unauthorized access to system information

#### 4. No Sensitive Data in Metrics 

Monitoring only system-level metrics like CPU and memory percentages, not user data or application secrets.

This means:

- No personal information is captured in monitoring
- Even if monitoring data is compromised, no user data is exposed
- Safe to share metrics with support teams if needed

### What This Protects Against

- **Data breaches**: Encrypted messages can't be read by unauthorized people
- **System reconnaissance**: Attackers can't easily learn about your infrastructure
- **Compliance violations**: Meets security standards for data protection
- **Insider threats**: Even people with some AWS access can't easily read monitoring data 