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
                script {
                    sh '''
                        trivy image --exit-code 1 --severity CRITICAL,HIGH ${IMAGE_NAME}:${IMAGE_TAG}
                        trivy config --exit-code 1 --severity CRITICAL,HIGH . || true
                        trivy secret --exit-code 1 . || true
                    '''
                }
            }
        }

        stage('Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                        echo $PASS | docker login -u $USER --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                        docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Sign with Cosign') {
            steps {
                withCredentials([file(credentialsId: 'cosign-private-key', variable: 'COSIGN_KEY')]) {
                    sh '''
                        cosign sign --key $COSIGN_KEY ${IMAGE_NAME}:${IMAGE_TAG}
                        cosign sign --key $COSIGN_KEY ${IMAGE_NAME}:latest
                    '''
                }
            }
        }

        stage('Verify Signature') {
            steps {
                withCredentials([file(credentialsId: 'cosign-public-key', variable: 'COSIGN_PUB_KEY')]) {
                    sh '''
                        cosign verify --key $COSIGN_PUB_KEY ${IMAGE_NAME}:${IMAGE_TAG}
                        cosign verify --key $COSIGN_PUB_KEY ${IMAGE_NAME}:latest
                    '''
                    echo "✅ Image signatures verified successfully!"
                }
            }
        }

        stage('Pre-Deploy Verification') {
            steps {
                withCredentials([file(credentialsId: 'cosign-public-key', variable: 'COSIGN_PUB_KEY')]) {
                    sh "cosign verify --key $COSIGN_PUB_KEY ${IMAGE_NAME}:${IMAGE_TAG}"
                    echo "✅ Image verified before deployment"
                }
            }
        }

        stage('Deploy') {
            steps {
                script {
                    def imageDigest = sh(
                        script: "docker inspect --format='{{index .RepoDigests 0}}' ${IMAGE_NAME}:${IMAGE_TAG} | cut -d'@' -f2",
                        returnStdout: true
                    ).trim()

                    // Update digest in Helm values file using yq
                    sh "yq e '.image.repository = \"${IMAGE_NAME}\"' -i helm/values.yaml"
                    sh "yq e '.image.digest = \"${imageDigest}\"' -i helm/values.yaml"
                }

                sh "kubectl apply -f kyverno-policy.yaml"
                sh "helm upgrade --install sahar-app ./helm -n default --create-namespace"

                sh "kubectl rollout status deployment/sahar-app --timeout=300s"
                echo "✅ Deployment completed successfully with verified image digest"
            }
        }

        stage('Verify') {
            steps {
                sh "kubectl get pods -l app=sahar-app"
                sh "kubectl get svc sahar-service"
                echo "✅ App available on NodePort 30080"
            }
        }
    }

    post {
        always {
            sh "docker logout || true"
        }
        success {
            echo "✅ Pipeline completed! Image signed, scanned and deployed securely with digest!"
        }
        failure {
            echo "❌ Pipeline failed"
        }
    }
}
