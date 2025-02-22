set -e

source .env


export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
export AWS_SESSION_TOKEN=$(aws configure get aws_session_token)

docker compose --profile spark-node up --remove-orphans -d  --build