pipeline {
    agent any

    environment {
        // Tumhara Docker Hub username (Screenshot ke mutabiq)
        DOCKERHUB_USER = 'abhdoc'
        IMAGE_NAME     = "${DOCKERHUB_USER}/project1"
        // Har build ka unique tag
        IMAGE_TAG      = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub...'
                // Ye step job configuration se GitHub creds use karega
                checkout scm
            }
        }

        stage('Install & Test') {
            // Node.js ko host machine par install karne ki zaroorat nahi,
            // hum ephemeral Docker container use karenge testing ke liye
            agent {
                docker { image 'node:20-alpine' }
            }
            steps {
                echo 'Installing npm dependencies...'
                sh 'npm install'
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

        stage('Pull Image') {
            steps {
                echo 'Pulling the newly built image from Docker Hub...'
                sh "docker pull ${IMAGE_NAME}:${IMAGE_TAG}"
            }
        }

        stage('Deploy New Container') {
            steps {
                echo 'Deploying new container...'
                sh '''
                    # Purana container band aur remove karo (agar exist karta hai)
                    docker stop project1 || true
                    docker rm project1 || true
                    
                    # Naya container run karo
                    docker run -d --name project1 -p 3000:3000 \
                        -e BUILD_VERSION=${IMAGE_TAG} \
                        ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully! App is running on port 3000.'
        }
        failure {
            echo 'Pipeline failed - check the stage logs above.'
        }
        always {
            sh 'docker logout || true'
        }
    }
}
