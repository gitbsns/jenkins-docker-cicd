# Docker + Jenkins CI/CD Pipeline

A self-built CI/CD pipeline that automatically builds a Node.js application into a Docker image, pushes it to Docker Hub, and deploys it — triggered by a Jenkins pipeline.

## Why this project

Most tutorials show you *how to click* a CI/CD pipeline. This project was built from scratch to understand *why* each stage exists: source control → dependency install → test gate → image build → registry push → deployment.

## Architecture

```
Developer pushes code to GitHub
        │
        ▼
  Jenkins detects change (webhook/poll)
        │
        ▼
  Pipeline stages run:
   1. Checkout code
   2. Install dependencies (npm install)
   3. Run tests (quality gate)
   4. Build Docker image
   5. Push image to Docker Hub
   6. Deploy container
        │
        ▼
  App running on port 3000
```

## Tech stack

- **Node.js / Express** — demo application
- **Docker** — containerization
- **Jenkins** — CI/CD orchestration (Declarative Pipeline)
- **Docker Hub** — image registry

## Project structure

```
docker-jenkins-cicd/
├── app.js           # Express application
├── package.json     # Node dependencies
├── Dockerfile        # Multi-layer optimized image build
├── .dockerignore
├── Jenkinsfile       # Full CI/CD pipeline definition
└── README.md
```

## Running locally (without Jenkins, to verify it works)

```bash
npm install
npm start
# visit http://localhost:3000
```

## Running with Docker

```bash
docker build -t cicd-demo-app .
docker run -d -p 3000:3000 --name cicd-demo-app cicd-demo-app
curl http://localhost:3000/health
```

## Setting up the Jenkins pipeline

1. Install Jenkins (locally via Docker, or on a free-tier EC2 instance):
   ```bash
   docker run -d -p 8080:8080 -p 50000:50000 --name jenkins \
     -v jenkins_home:/var/jenkins_home \
     -v /var/run/docker.sock:/var/run/docker.sock \
     jenkins/jenkins:lts
   ```
2. Install the **Docker Pipeline** plugin from Jenkins plugin manager.
3. Add Docker Hub credentials: **Manage Jenkins → Credentials → Add**, ID = `dockerhub-creds`.
4. Push this repo to your own GitHub.
5. In Jenkins: **New Item → Pipeline → Pipeline script from SCM → Git**, point it at your repo.
6. Update `DOCKERHUB_USER` in the `Jenkinsfile` to your own Docker Hub username.
7. Click **Build Now** — and watch the stages you wrote run end to end.

## What this demonstrates

- Understanding of Docker layer caching and image optimization
- Writing a multi-stage Jenkins Declarative Pipeline from scratch
- Secure credential handling in CI/CD (`withCredentials`)
- Automated build → test gate → registry push → deploy flow
- Basic troubleshooting of container lifecycle (stop/remove/redeploy)

## Next steps

This pipeline currently deploys to a single Docker host. See the companion
**Kubernetes Deployment** project for deploying this same image to a cluster
with Deployments, Services, and ConfigMaps/Secrets.
