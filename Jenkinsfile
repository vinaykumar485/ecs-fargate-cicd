pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = '273263084701.dkr.ecr.us-east-1.amazonaws.com/ecs-fargate-cicd'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Maven Build') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    IMAGE_TAG=$(git rev-parse --short HEAD)

                    docker build \
                      -t $ECR_REPO:$IMAGE_TAG \
                      -t $ECR_REPO:latest .
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    aws ecr get-login-password --region $AWS_REGION | \
                    docker login --username AWS --password-stdin $ECR_REPO

                    IMAGE_TAG=$(git rev-parse --short HEAD)

                    docker push $ECR_REPO:$IMAGE_TAG
                    docker push $ECR_REPO:latest
                '''
            }
        }
                stage('Deploy to ECS') {
            steps {
                sh '''
                    IMAGE_TAG=$(git rev-parse --short HEAD)

                    echo "Deploying image: $ECR_REPO:$IMAGE_TAG"

                    aws ecs describe-task-definition \
                      --task-definition ecs-fargate-cicd \
                      --region $AWS_REGION \
                      --query taskDefinition > current-task-definition.json

                    jq --arg IMAGE "$ECR_REPO:$IMAGE_TAG" \
                      '.containerDefinitions[0].image = $IMAGE |
                       del(.taskDefinitionArn,
                           .revision,
                           .status,
                           .requiresAttributes,
                           .compatibilities,
                           .registeredAt,
                           .registeredBy)' \
                      current-task-definition.json > new-task-definition.json

                    aws ecs register-task-definition \
                      --cli-input-json file://new-task-definition.json \
                      --region $AWS_REGION

                    aws ecs update-service \
                      --cluster ecs-fargate-cicd \
                      --service ecs-fargate-cicd-service \
                      --task-definition ecs-fargate-cicd \
                      --region $AWS_REGION

                    aws ecs wait services-stable \
                      --cluster ecs-fargate-cicd \
                      --services ecs-fargate-cicd-service \
                      --region $AWS_REGION

                    echo "ECS deployment completed successfully!"
                '''
            }
        }

    }

       
    post {
        success {
            echo 'CI pipeline completed successfully!'
        }

        failure {
            echo 'CI pipeline failed.'
        }
    }
}
