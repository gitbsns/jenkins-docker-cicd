pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'abhdoc'
        IMAGE_NAME     = "${DOCKERHUB_USER}/project1"
        IMAGE_TAG      = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub...'
                checkout scm
            }
        }

        stage('Install & Test') {
            agent {
                docker {
                    image 'node:20-alpine'
                    args '-e npm_config_cache=$WORKSPACE/.npm'
                }
            }
            steps {
                echo 'Installing npm dependencies...'
                sh 'npm install --cache .npm'
                echo 'Running tests...'
                sh 'npm test'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
                // Hum image ko do tags dete hain: ek unique build number, aur ek 'latest'
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

        stage('Pull & Deploy') {
            steps {
                echo 'Pulling the latest image from Docker Hub...'
                sh "docker pull ${IMAGE_NAME}:latest"

                echo 'Deploying new container using :latest tag...'
                sh '''
                    # Purana container band aur remove karo
                    docker stop project1 || true
                    docker rm project1 || true
                    
                    # Naya container hamesha :latest tag se chalao
                    docker run -d --name project1 -p 3000:3000 \
                        -e BUILD_VERSION=${IMAGE_TAG} \
                        ${IMAGE_NAME}:latest
                '''
            }
        }

        stage('Cleanup Old Images') {
            steps {
                echo 'Cleaning up old Docker images to save space...'
                sh '''
                    # Purane saare tags (except latest) delete karo
                    docker images "${IMAGE_NAME}" --format "{{.Repository}}:{{.Tag}}" | grep -v "latest" | xargs -r docker rmi -f || true
                    # Dangling (faltu) images clean karo
                    docker image prune -f || true
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully! App is running on :latest tag.'
        }
        failure {
            echo 'Pipeline failed - check the stage logs above.'
        }
        always {
            sh 'docker logout || true'
        }
    }
}
