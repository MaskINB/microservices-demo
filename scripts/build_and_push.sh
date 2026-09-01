#!/usr/bin/env bash
set -euo pipefail

AWS_ACCOUNT_ID="271033481922"
AWS_REGION="ap-south-1"
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
GIT_SHA=$(git rev-parse --short HEAD)

# service_name:dockerfile_context:dockerfile_path
SERVICES=(
  "adservice:src/adservice:src/adservice/Dockerfile"
  "cartservice:src/cartservice/src:src/cartservice/src/Dockerfile"
  "checkoutservice:src/checkoutservice:src/checkoutservice/Dockerfile"
  "currencyservice:src/currencyservice:src/currencyservice/Dockerfile"
  "emailservice:src/emailservice:src/emailservice/Dockerfile"
  "frontend:src/frontend:src/frontend/Dockerfile"
  "loadgenerator:src/loadgenerator:src/loadgenerator/Dockerfile"
  "paymentservice:src/paymentservice:src/paymentservice/Dockerfile"
  "productcatalogservice:src/productcatalogservice:src/productcatalogservice/Dockerfile"
  "recommendationservice:src/recommendationservice:src/recommendationservice/Dockerfile"
  "shippingservice:src/shippingservice:src/shippingservice/Dockerfile"
  "shoppingassistantservice:src/shoppingassistantservice:src/shoppingassistantservice/Dockerfile"
)

echo "==> Logging in to ECR ($ECR_REGISTRY)..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_REGISTRY"

for entry in "${SERVICES[@]}"; do
  IFS=':' read -r name context dockerfile <<< "$entry"

  echo ""
  echo "==> Building $name..."
  docker build -t "${name}:${GIT_SHA}" -f "$dockerfile" "$context"

  echo "==> Tagging $name..."
  docker tag "${name}:${GIT_SHA}" "${ECR_REGISTRY}/${name}:${GIT_SHA}"

  echo "==> Checking if ${name}:${GIT_SHA} already exists in ECR..."
  if aws ecr describe-images --repository-name "$name" --image-ids imageTag="$GIT_SHA" --region "$AWS_REGION" >/dev/null 2>&1; then
    echo "==> ${name}:${GIT_SHA} already exists in ECR, skipping push for this tag."
  else
    echo "==> Pushing $name:$GIT_SHA..."
    docker push "${ECR_REGISTRY}/${name}:${GIT_SHA}"
  fi

  # 'latest' tag: force-move it by deleting the old one first (immutable tags block overwriting otherwise)
  aws ecr batch-delete-image --repository-name "$name" --image-ids imageTag=latest --region "$AWS_REGION" >/dev/null 2>&1 || true
  docker tag "${name}:${GIT_SHA}" "${ECR_REGISTRY}/${name}:latest"
  docker push "${ECR_REGISTRY}/${name}:latest"

  echo "==> Done: $name"
done

echo ""
echo "All 12 images built and pushed successfully."