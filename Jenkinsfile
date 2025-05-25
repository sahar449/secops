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

        stage('Trivy Scan') {
            steps {
                echo "🔍 Scanning image with Trivy for vulnerabilities and misconfigurations..."
                sh "trivy image --exit-code 0 --severity MEDIUM,HIGH,CRITICAL ${IMAGE_NAME}:${IMAGE_TAG}"
                sh "trivy config . || true"
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
                    echo "✅ Cosign signature verified!"
                }
            }
        }

        stage('Get Digest') {
            steps {
                script {
                    def digest = sh(
                        script: "docker inspect --format='{{index .RepoDigests 0}}' ${IMAGE_NAME}:${IMAGE_TAG} | cut -d'@' -f2",
                        returnStdout: true
                    ).trim()
                    env.IMAGE_DIGEST = digest
                }
            }
        }

        stage('Helm Deploy') {
            steps {
                script {
                    sh """
                        helm upgrade --install sahar-secops ./helm \\
                          --set image.repository=${IMAGE_NAME} \\
                          --set image.digest=${IMAGE_DIGEST} \\
                          --wait
                    """
                    sh "kubectl rollout status deployment/sahar-app --timeout=300s"
                    echo "🚀 Helm deploy completed with image digest"
                }
            }
        }

        stage('Verify') {
            steps {
                sh "kubectl get pods -l app=sahar-app"
                sh "kubectl get svc sahar-service"
                echo "✅ Deployment is available via NodePort 30080"
            }
        }
    }

    post {
        always {
            sh "docker logout"
        }
        success {
            echo "✅ Pipeline completed successfully!"
        }
        failure {
            echo "❌ Pipeline failed."
        }
    }
}
