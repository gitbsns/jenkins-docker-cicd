// ============================================================
// Jenkins Declarative Pipeline - Docker Build + Kubernetes Deploy
//
// UPDATED VERSION: purani "docker run" deploy stage hata kar
// ab pipeline seedha Kubernetes cluster pe rolling update karta hai.
//
// NAYA SETUP KARNA HOGA (ek baar):
// 1. Jenkins Credentials mein add karo:
//    - ID "dockerhub-creds"   -> Docker Hub username/password (already hai)
//    - ID "kubeconfig-cred"   -> type "Secret file", apna limited kubeconfig upload karo
//    - ID "session-secret"    -> type "Secret text", naya rotated SESSION_SECRET value
// 2. Namespace ke andar Jenkins ke liye limited ServiceAccount + Role banao
//    (poora cluster-admin mat do - sirf is app ke Deployment/Service/Secret tak)
// 3. secret.yaml ab repo mein commit NAHI hogi - is Jenkinsfile ki
//    "Update K8s Secret" stage khud secret banayegi/update karegi
// ============================================================

pipeline {
    agent any

    environment {
        DOCKERHUB_USER = 'ahbdoc'
        IMAGE_NAME     = "${DOCKERHUB_USER}/project1"
        IMAGE_TAG      = "${BUILD_NUMBER}"
        K8S_NAMESPACE  = 'default'
        DEPLOYMENT     = 'myapp-deployment'
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

        stage('Update K8s Secret') {
            steps {
                // Secret YAML file se nahi aata - Jenkins Credentials store se
                // seedha inject hota hai. Repo mein iski asal value kabhi nahi hoti.
                withCredentials([string(
                    credentialsId: 'session-secret',
                    variable: 'SESSION_SECRET_VALUE'
                )]) {
                    withKubeConfig([credentialsId: 'kubeconfig-cred']) {
                        sh '''
                            kubectl create secret generic myapp-secret \
                                --namespace=${K8S_NAMESPACE} \
                                --from-literal=SESSION_SECRET=$SESSION_SECRET_VALUE \
                                --dry-run=client -o yaml | kubectl apply -f -
                        '''
                    }
                }
            }
        }

        stage('Apply ConfigMap') {
            steps {
                withKubeConfig([credentialsId: 'kubeconfig-cred']) {
                    // ConfigMap mein koi secret nahi hoti, isliye ye file
                    // repo mein rakhna safe hai
                    sh "kubectl apply -f configmap.yaml -n ${K8S_NAMESPACE}"
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo "Rolling update: setting image to ${IMAGE_NAME}:${IMAGE_TAG}"
                withKubeConfig([credentialsId: 'kubeconfig-cred']) {
                    sh '''
                        # Pehli baar deploy ho raha ho to poora manifest apply karo,
                        # baad ke builds sirf image update karenge (chhota rolling update)
                        kubectl apply -f deployment.yaml -n ${K8S_NAMESPACE}
                        kubectl apply -f service.yaml -n ${K8S_NAMESPACE}
                        kubectl set image deployment/${DEPLOYMENT} \
                            myapp=${IMAGE_NAME}:${IMAGE_TAG} \
                            -n ${K8S_NAMESPACE}
                    '''
                }
            }
        }

        stage('Verify Rollout') {
            steps {
                echo 'Checking rollout status - agar naya pod crash hua to yahin fail hoga...'
                withKubeConfig([credentialsId: 'kubeconfig-cred']) {
                    sh "kubectl rollout status deployment/${DEPLOYMENT} -n ${K8S_NAMESPACE} --timeout=90s"
                }
            }
        }

        stage('Cleanup Old Images') {
            steps {
                echo 'Cleaning up old Docker images to save space...'
                sh '''
                    docker images "${IMAGE_NAME}" --format "{{.Repository}}:{{.Tag}}" | grep -v "latest" | xargs -r docker rmi -f || true
                    docker image prune -f || true
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully! New version rolled out to Kubernetes.'
        }
        failure {
            echo 'Pipeline failed. If rollout failed, Kubernetes keeps the previous working pods running (no downtime).'
        }
        always {
            sh 'docker logout || true'
        }
    }
}
