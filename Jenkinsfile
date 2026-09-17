// ============================================================
// Jenkins Declarative Pipeline - Docker Build & Deploy
//
// Ye file exactly wo hai jo aap job mein "Build Now" dabate ho -
// lekin yahan aap ise SAMAJH kar khud likh rahe ho.
//
// SETUP KARNE SE PEHLE (Jenkins mein karna hoga):
// 1. Jenkins pe "Docker Pipeline" plugin install karo
// 2. Manage Jenkins -> Credentials mein Docker Hub username/password
//    add karo, ID rakho: "dockerhub-creds"
// 3. Ye repo GitHub pe push karo, phir Jenkins mein
//    "New Item" -> "Pipeline" -> "Pipeline script from SCM" select karo
// ============================================================

pipeline {
    agent any

    environment {
        // Apna Docker Hub username yahan daalo
        DOCKERHUB_USER = 'your-dockerhub-username'
        IMAGE_NAME     = "${DOCKERHUB_USER}/cicd-demo-app"
        // BUILD_NUMBER Jenkins khud provide karta hai - har build ka
        // unique tag ban jata hai, "latest" pe depend nahi karna padta
        IMAGE_TAG      = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                // GitHub se latest code khinch kar laata hai
                echo 'Checking out source code from GitHub...'
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                echo 'Installing npm dependencies...'
                sh 'npm install'
            }
        }

        stage('Run Tests') {
            steps {
                // Abhi test hollow hai - jab aap Jest/Mocha add karo,
                // ye stage real tests chalayega aur fail hone par
                // pipeline yahin ruk jayega (deploy nahi hoga)
                echo 'Running tests...'
                sh 'npm test'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -t ${IMAGE_NAME}:latest ."
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo 'Pushing image to Docker Hub...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Deploy') {
            steps {
                // Simplest possible deploy: purana container hata kar
                // naya image ke saath chalao. Real production mein
                // ye stage Kubernetes "kubectl apply" ho sakta hai -
                // wo Project 2 mein cover karenge.
                echo 'Deploying new container...'
                sh '''
                    docker stop cicd-demo-app || true
                    docker rm cicd-demo-app || true
                    docker run -d --name cicd-demo-app -p 3000:3000 \
                        -e BUILD_VERSION=${IMAGE_TAG} \
                        ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed - check the stage logs above.'
        }
        always {
            // Docker login session clean karo
            sh 'docker logout || true'
        }
    }
}
