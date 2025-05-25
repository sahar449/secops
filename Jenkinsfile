pipeline {
    agent any
    
    environment {
        IMAGE_NAME = 'sahar449/secops'
        COSIGN_PASSWORD = credentials('cosign-password')
    }
    
    stages {
        stage('Build') {
            steps {
                script {
                    def tag = "${BUILD_NUMBER}"
                    sh "docker build -t ${IMAGE_NAME}:${tag} ."
                    sh "docker tag ${IMAGE_NAME}:${tag} ${IMAGE_NAME}:latest"
                    env.IMAGE_TAG = tag
                }
            }
        }
        
        stage('Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh "echo \$PASS | docker login -u \$USER --password-stdin"
                    sh "docker push ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker push ${IMAGE_NAME}:latest"
                }
            }
        }
        
        stage('Sign with Cosign') {
            steps {
                withCredentials([file(credentialsId: 'cosign-private-key', variable: 'COSIGN_KEY')]) {
                    sh "cosign sign --key \$COSIGN_KEY ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "cosign sign --key \$COSIGN_KEY ${IMAGE_NAME}:latest"
                }
            }
        }
        
        stage('Verify Signature') {
            steps {
                withCredentials([file(credentialsId: 'cosign-public-key', variable: 'COSIGN_PUB_KEY')]) {
                    sh "cosign verify --key \$COSIGN_PUB_KEY ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "cosign verify --key \$COSIGN_PUB_KEY ${IMAGE_NAME}:latest"
                    echo "✅ Image signatures verified successfully!"
                }
            }
        }
        
        stage('Pre-Deploy Verification') {
            steps {
                // Verify image signature before deployment
                withCredentials([file(credentialsId: 'cosign-public-key', variable: 'COSIGN_PUB_KEY')]) {
                    sh "cosign verify --key \$COSIGN_PUB_KEY ${IMAGE_NAME}:${IMAGE_TAG}"
                    echo "✅ Image verified before deployment"
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    // Get image digest for secure deployment
                    def imageDigest = sh(
                        script: "docker inspect --format='{{index .RepoDigests 0}}' ${IMAGE_NAME}:${IMAGE_TAG} | cut -d'@' -f2",
                        returnStdout: true
                    ).trim()
                    
                    // Update deployment with image digest
                    sh "sed -i 's|image: sahar449/secops:latest|image: ${IMAGE_NAME}@${imageDigest}|g' deployment.yaml"
                }
                
                sh "kubectl apply -f kyverno-policy.yaml"
                sh "kubectl apply -f deployment.yaml"
                
                // Wait until deployment is successfully completed
                sh "kubectl rollout status deployment/sahar-app --timeout=300s"
                echo "✅ Deployment completed successfully with verified image digest"
            }
        }
        
        stage('Verify') {
            steps {
                sh "kubectl get pods -l app=sahar-app"
                sh "kubectl get svc sahar-service"
                sh "echo 'App available on NodePort 30080'"
            }
        }
    }
    
    post {
        always {
            sh "docker logout"
        }
        success {
            echo "✅ Pipeline completed! Image signed and deployed securely."
        }
    }
}