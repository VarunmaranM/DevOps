pipeline {
    // Run this pipeline on a specific Jenkins agent that is an EC2 instance with an IAM role.
    // Ensure you label your agent 'aws-ec2-agent' in Jenkins's node configuration.
    agent { label 'aws-ec2-agent' }

    environment {
        // IDs of credentials stored securely in Jenkins Credentials Manager
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'

        // --- IMPORTANT: CHANGE THESE TWO VALUES ---
        DOCKER_IMAGE_NAME = 'yourdockerhubusername/my-cicd-app' // Use your DockerHub username
        AWS_REGION        = 'us-east-1' // Or your preferred AWS region
        // --- --- --- --- --- --- --- --- --- --- ---

        EKS_CLUSTER_NAME  = 'my-app-cluster'
    }

    stages {
        stage('1. Checkout Code') {
            steps {
                echo 'Checking out the latest code from Git...'
                checkout scm
            }
        }

        stage('2. Build and Push Docker Image') {
            steps {
                script {
                    env.IMAGE_TAG = "${BUILD_NUMBER}"
                    echo "Building Docker image: ${DOCKER_IMAGE_NAME}:${env.IMAGE_TAG}"
                    sh "docker build -t ${DOCKER_IMAGE_NAME}:${env.IMAGE_TAG} ./app"

                    withCredentials([usernamePassword(credentialsId: DOCKERHUB_CREDENTIALS_ID, usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        echo "Logging into DockerHub and pushing image..."
                        sh "echo ${DOCKER_PASS} | docker login -u ${DOCKER_USER} --password-stdin"
                        sh "docker push ${DOCKER_IMAGE_NAME}:${env.IMAGE_TAG}"
                    }
                }
            }
        }

        stage('3. Provision Infrastructure (Terraform)') {
            steps {
                // The withCredentials wrapper for AWS is removed.
                // The pipeline will now automatically use the IAM Role from the EC2 agent.
                dir('infra') {
                    echo "Initializing Terraform..."
                    sh 'terraform init -input=false'
                    echo "Planning and Applying infrastructure changes..."
                    sh 'terraform apply -auto-approve -input=false'
                }
            }
        }

        stage('4. Deploy to Kubernetes') {
            steps {
                // The withCredentials wrapper for AWS is removed here as well.
                script {
                    echo "Updating Kubernetes manifests with new image tag: ${env.IMAGE_TAG}"
                    // This command replaces the placeholder with the actual build number
                    sh "sed -i 's|__IMAGE_TAG__|${env.IMAGE_TAG}|g' k8s/deployment.yaml"

                    echo "Connecting to EKS cluster..."
                    sh "aws eks update-kubeconfig --region ${AWS_REGION} --name ${EKS_CLUSTER_NAME}"
                    
                    echo "Applying manifests to the cluster..."
                    sh "kubectl apply -f k8s/"
                    
                    echo "Waiting for deployment rollout to complete..."
                    sh "kubectl rollout status deployment/my-app-deployment --timeout=120s"
                }
            }
        }
    }

    post {
        // This block runs after all stages, regardless of success or failure
        always {
            echo 'Pipeline finished. Cleaning up workspace...'
            cleanWs() // Deletes all files from the Jenkins workspace for the next run
        }
    }
}

