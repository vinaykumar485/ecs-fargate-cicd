#!/bin/bash
set -e

AWS_REGION="us-east-1"
CLUSTER="ecs-fargate-cicd"
SERVICE="ecs-fargate-cicd-service"
TASK_FAMILY="ecs-fargate-cicd"
ECR_REPO="273263084701.dkr.ecr.us-east-1.amazonaws.com/ecs-fargate-cicd"

IMAGE_TAG=$(git rev-parse --short HEAD)

echo "Deploying image: $ECR_REPO:$IMAGE_TAG"

echo "Getting current task definition..."
aws ecs describe-task-definition \
  --task-definition "$TASK_FAMILY" \
  --region "$AWS_REGION" \
  --query taskDefinition > current-task-definition.json

echo "Updating container image..."
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

echo "Registering new task definition..."
aws ecs register-task-definition \
  --cli-input-json file://new-task-definition.json \
  --region "$AWS_REGION"

echo "Updating ECS service..."
aws ecs update-service \
  --cluster "$CLUSTER" \
  --service "$SERVICE" \
  --task-definition "$TASK_FAMILY" \
  --region "$AWS_REGION"

echo "Waiting for ECS service to stabilize..."
aws ecs wait services-stable \
  --cluster "$CLUSTER" \
  --services "$SERVICE" \
  --region "$AWS_REGION"

echo "Deployment completed successfully!"
