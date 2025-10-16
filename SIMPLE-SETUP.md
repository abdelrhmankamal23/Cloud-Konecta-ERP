# Simple AWS Setup for Konecta ERP

The easiest way to run your ERP system on AWS for free.

## What You Need
- AWS account (free)
- Basic computer skills

## Step 1: Create AWS Account
1. Go to [aws.amazon.com](https://aws.amazon.com)
2. Click "Create AWS Account"
3. Follow the steps (you need a credit card but won't be charged)

## Step 2: Launch EC2 Instance
1. Login to AWS Console
2. Search for "EC2" and click it
3. Click "Launch Instance"
4. Choose these settings:
   - **Name**: `konecta-erp`
   - **Image**: Amazon Linux 2023 (free tier)
   - **Instance type**: t2.micro (free tier)
   - **Key pair**: Create new key pair, download the .pem file
   - **Security group**: Allow SSH (22), HTTP (80), Custom TCP (8080-8090)
5. Click "Launch Instance"

## Step 3: Connect to Your Server
1. Wait 2 minutes for instance to start
2. Click on your instance
3. Click "Connect" button
4. Use "EC2 Instance Connect" (easiest way)

## Step 4: Install Docker
Copy and paste these commands one by one:

```bash
sudo yum update -y
sudo yum install -y docker git
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
```

Log out and log back in, then:

```bash
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

## Step 5: Get Your Code
```bash
git clone https://github.com/your-username/Konecta-ERP-System.git
cd Konecta-ERP-System
```

## Step 6: Start Your Application
```bash
docker-compose -f infrastructure/docker-compose.simple.yml up -d
```

## Step 7: Access Your App
1. Go back to EC2 console
2. Copy your instance's "Public IPv4 address"
3. Open browser and go to: `http://YOUR-IP-ADDRESS`

## That's It!
Your ERP system is now running for free on AWS.

## If Something Goes Wrong
1. Check if containers are running: `docker ps`
2. See what's wrong: `docker-compose -f infrastructure/docker-compose.simple.yml logs`
3. Restart everything: `docker-compose -f infrastructure/docker-compose.simple.yml restart`

## Monthly Cost
- **First 12 months**: $0 (AWS Free Tier)
- **After 12 months**: ~$8/month