# Docker + Jenkins CI/CD Pipeline

A self-built CI/CD pipeline that automatically builds a Node.js application into a Docker image, pushes it to Docker Hub, and deploys it — triggered automatically by a GitHub webhook via Jenkins.

## Why this project

Most tutorials show you *how to click* a CI/CD pipeline. This project was built from scratch to understand *why* each stage exists: source control → dependency install → test gate → image build → registry push → deployment.

## Architecture
Developer pushes code to GitHub
│
▼
GitHub Webhook (via ngrok tunnel) triggers Jenkins
│
▼
Pipeline stages run:

Checkout code

Install dependencies (npm install)

Run tests (quality gate)

Build Docker image

Push image to Docker Hub

Pull latest image & Deploy container

Cleanup old Docker images (disk optimization)
│
▼
App running on port 3000

text

## Tech stack

- **Node.js / Express** — demo application
- **Docker** — containerization
- **Jenkins** — CI/CD orchestration (Declarative Pipeline)
- **Docker Hub** — image registry
- **ngrok** — Secure tunneling to expose local Jenkins to GitHub
- **GitHub Webhooks** — Automated pipeline triggering

## Project structure
docker-jenkins-cicd/
├── app.js # Express application
├── package.json # Node dependencies
├── Dockerfile # Multi-layer optimized image build
├── .dockerignore
├── Jenkinsfile # Full CI/CD pipeline definition
└── README.md

text

## Running locally (without Jenkins, to verify it works)

```bash
npm install
npm start
# visit http://localhost:3000
Running with Docker
bash
docker build -t cicd-demo-app .
docker run -d -p 3000:3000 --name cicd-demo-app cicd-demo-app
curl http://localhost:3000/health

Setting up the Jenkins pipeline

Install Jenkins (locally via Docker, or on a free-tier EC2 instance):

bash
docker run -d -p 8080:8080 -p 50000:50000 --name jenkins \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts
Install the Docker Pipeline, GitHub Integration, and Git plugins from the Jenkins plugin manager.

Add Docker Hub credentials: Manage Jenkins → Credentials → Add, ID = dockerhub-creds. (Ensure the token has Read & Write permissions).

Push this repo to your own GitHub.

In Jenkins: New Item → Pipeline → Pipeline script from SCM → Git, point it at your repo. Select your github-creds and set the branch to */main.

Setup Auto-Trigger (Webhook & Ngrok):

Expose your local Jenkins server using ngrok:

bash
ngrok http 8080
Copy the generated public URL (e.g., https://xxxx.ngrok-free.app).

Go to your GitHub Repository → Settings → Webhooks → Add webhook.

Payload URL: https://xxxx.ngrok-free.app/github-webhook/ (Make sure to include the trailing slash).

Content type: application/json.

Events: Select "Just the push event".

In your Jenkins job configuration, under Build Triggers, check "GitHub hook trigger for GITScm polling".

Update DOCKERHUB_USER in the Jenkinsfile to your own Docker Hub username.

Click Build Now — and watch the stages you wrote run end to end. Every subsequent git push will now trigger the pipeline automatically.

📸 Project Screenshots


1. Jenkins Pipeline Success
https://github.com/gitbsns/jenkins-docker-cicd/blob/main/screenshots/jenkins%20pipeline.png

2. Docker Hub Repository (Pushed Images)
https://github.com/gitbsns/jenkins-docker-cicd/blob/main/screenshots/dockerhub.png

3. Ngrok Traffic Inspector (Webhook 200 OK)
https://github.com/gitbsns/jenkins-docker-cicd/blob/main/screenshots/ngrok-WH.png

4. Live Application on Port 3000
https://github.com/gitbsns/jenkins-docker-cicd/blob/main/screenshots/application.png

What this demonstrates
Understanding of Docker layer caching and image optimization

Writing a multi-stage Jenkins Declarative Pipeline from scratch

Secure credential handling in CI/CD (withCredentials)

Automated build → test gate → registry push → deploy flow

Basic troubleshooting of container lifecycle (stop/remove/redeploy)

Setting up automated webhooks using ngrok for local development environments

Implementing automated cleanup of Docker images to optimize disk space
