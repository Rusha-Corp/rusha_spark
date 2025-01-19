set -e

source .env
output=$(aws sts assume-role \
  --role-arn $AWS_ROLE_ARN \
  --role-session-name contabo-thrift-server \
  --duration-seconds 36000)

echo "Access Key ID: $(echo $output | jq -r '.Credentials.AccessKeyId')"
echo "Secret Access Key: $(echo $output | jq -r '.Credentials.SecretAccessKey')"
echo "Session Token: $(echo $output | jq -r '.Credentials.SessionToken')"

export AWS_ACCESS_KEY_ID=$(echo $output | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $output | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $output | jq -r '.Credentials.SessionToken')

docker compose up -d --remove-orphans --build --force-recreate