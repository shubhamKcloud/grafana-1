#!/usr/bin/env bash

set -e

PREFIX=$1
if [ -z "${PREFIX}" ]; then
    echo "Usage .github/tvarit/deploy_to_dev_sk.sh <PREFIX>"
    exit 1
fi

check_lightsail_instance() {
    instance_name="$1"

    # Get the instance information
    instance_info=$(aws lightsail get-instance --instance-name "$instance_name" 2>/dev/null)

    # Check if the instance exists
    if [[ -n "$instance_info" ]]; then
        echo "Lightsail instance with same name $instance_name already exists."
        return 0
    else
        echo "Lightsail instance $instance_name does not exist."
        return 1
    fi
}

check_lightsail_static_ip_name() {
    ip_name="$1"

    # Get the static IPs information
    static_ips_info=$(aws lightsail get-static-ips --query "staticIps[*].name" --output text)

    # Check if the IP name exists in the list of static IPs
    if echo "$static_ips_info" | grep -q "$ip_name"; then
        echo "Lightsail static IP with same name $ip_name already exists."
        return 0
    else
        echo "Lightsail static IP name $ip_name does not exist."
        return 1
    fi
}

aws lightsail get-certificates --certificate-name ${PREFIX}-tvarit-com > /dev/null

echo "Creating production database..."
aws lightsail create-relational-database \
  --relational-database-name ${PREFIX}-grafana-db \
  --availability-zone ${AWS_DEFAULT_REGION}a \
  --relational-database-blueprint-id mysql_8_0 \
  --relational-database-bundle-id micro_1_0 \
  --preferred-backup-window 00:00-00:30 \
  --preferred-maintenance-window Sun:01:00-Sun:01:30 \
  --master-database-name grafana \
  --master-username grafana \
  --no-publicly-accessible || :

echo "Waiting for database to be available..."
for run in {1..60}; do
  state=$(aws lightsail get-relational-database --relational-database-name ${PREFIX}-grafana-db --output text --query 'relationalDatabase.state')
  if [ "${state}" == "available" ]; then
    break
  fi
  echo "Waiting for database to be available..."
  sleep 60
done

if [ "${state}" != "available" ]; then
  echo "Database not created in 60 mins"
  exit 1
fi

echo "Creating staging database..."
aws lightsail create-relational-database-from-snapshot \
  --relational-database-name ${PREFIX}-next-grafana-db \
  --source-relational-database-name ${PREFIX}-grafana-db \
  --use-latest-restorable-time || :

echo "Waiting for database to be available..."
for run in {1..60}; do
  state=$(aws lightsail get-relational-database --relational-database-name ${PREFIX}-next-grafana-db --output text --query 'relationalDatabase.state')
  if [ "${state}" == "available" ]; then
    break
  fi
  echo "Waiting for database to be available..."
  sleep 60
done

if [ "${state}" != "available" ]; then
  echo "Database not created in 60 mins"
  exit 1
fi

DB_ENDPOINT=$(aws lightsail get-relational-database --relational-database-name ${PREFIX}-next-grafana-db --output text --query 'relationalDatabase.masterEndpoint.address')
DB_PASSWORD=$(aws lightsail get-relational-database-master-user-password --relational-database-name ${PREFIX}-next-grafana-db --output text --query masterUserPassword)
#SIGNING_SECRET=$(aws secretsmanager get-secret-value --secret-id grafana-signing-secret --output text --query SecretString)
#AWS-030
echo "Testing!!!!!!!!!!!!!!!!!!!!!!!!"
AWS_ACCESS_KEY=$(aws secretsmanager get-secret-value --secret-id /credentials/grafana-user/access-key --output text --query SecretString)
AWS_SECRET_KEY=$(aws secretsmanager get-secret-value --secret-id /credentials/grafana-user/secret-key --output text --query SecretString)
echo $DB_ENDPOINT
echo $AWS_ACCESS_KEY
echo $AWS_SECRET_KEY

# echo "Create Lightsail container service if not exists..."
# (aws lightsail create-container-service \
#   --service-name  "${PREFIX}-next-grafana" \
#   --power nano \
#   --scale 1 \
#   --region "${AWS_DEFAULT_REGION}" \
#   --public-domain-names ${PREFIX}-tvarit-com=next-${PREFIX}.tvarit.com && sleep 10) || :

echo "Building docker image..."
# docker build --tag grafana/grafana:next-${PREFIX} .

# cd .github/tvarit/conf/prod/
# echo "Downloading plugins..."
# rm -rf plugins
# aws s3 sync s3://com.tvarit.grafana.artifacts/grafana-plugins plugins
# find plugins/ -type f -name *.tar.gz -exec bash -c 'cd $(dirname $1) && tar -xf $(basename $1) && rm $(basename $1); cd -' bash {} \;

# echo "Finalising docker image..."
# cp grafana.ini.template grafana.ini
# sed -i "s#<DOMAIN/>#next-${PREFIX}.tvarit.com#g" grafana.ini
# sed -i "s#<ROOT_URL/>#https://next-${PREFIX}.tvarit.com/#g" grafana.ini
# sed -i "s#<SIGNING_SECRET/>#${SIGNING_SECRET}#g" grafana.ini
# sed -i "s#<DB_ENDPOINT/>#${DB_ENDPOINT}#g" grafana.ini
# sed -i "s#<DB_PASSWORD/>#$(echo ${DB_PASSWORD} | sed 's/#/\\#/g' | sed 's/&/\\&/g')#g" grafana.ini
# sed -i "s#<OAUTH_CLIENT_ID/>#${OAUTH_CLIENT_ID}#g" grafana.ini
# sed -i "s#<OAUTH_CLIENT_SECRET/>#${OAUTH_CLIENT_SECRET}#g" grafana.ini
# sed -i "s#<SMTP_HOST/>#${SMTP_HOST}#g" grafana.ini
# sed -i "s#<SMTP_USER/>#${SMTP_USER}#g" grafana.ini
# sed -i "s#<SMTP_PASSWORD/>#${SMTP_PASSWORD}#g" grafana.ini
# sed -i "s#<SMTP_FROM/>#[BETA] Tvarit AI Platform#g" grafana.ini

# cp cloudwatch.json.template cloudwatch.json
# sed -i "s#<DOMAIN/>#next-${PREFIX}.tvarit.com#g" cloudwatch.json

# cp Dockerfile.template Dockerfile
# sed -i "s#<BASE_IMAGE/>#grafana/grafana:next-${PREFIX}#g" Dockerfile
# sed -i "s#<AWS_ACCESS_KEY/>#${AWS_ACCESS_KEY}#g" Dockerfile
# sed -i "s#<AWS_SECRET_KEY/>#${AWS_SECRET_KEY}#g" Dockerfile
# sed -i "s#<AWS_REGION/>#${AWS_DEFAULT_REGION}#g" Dockerfile
docker build --tag grafana/grafana:next-${PREFIX} .

#push Docker image to ECR
echo "push docker image to ECR........."
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 047870419389.dkr.ecr.eu-central-1.amazonaws.com
docker tag grafana/grafana:next-${PREFIX} 047870419389.dkr.ecr.eu-central-1.amazonaws.com/lightsail:latest
docker push 047870419389.dkr.ecr.eu-central-1.amazonaws.com/lightsail:latest

#Create Lightsail instance
echo "create lightsail instance..."

# Check if instance and static IP with same name already exist
instance_name=grafana-${PREFIX}
static_ip_name=grafana-ip-${PREFIX}

check_lightsail_instance "$instance_name"
instance_exit_code=$?

if [ $instance_exit_code -eq 0 ]; then
    echo "Lightsail instance with same name $instance_name already exists."
    
else
    echo "lightsail instance does not exist. Creating instance!!!!!!"
    #AWS_ACCESS_KEY_ID=$(aws secretsmanager get-secret-value --secret-id /credentials/grafana-user/access-key --output text --query SecretString)
    #AWS_SECRET_ACCESS_KEY=$(aws secretsmanager get-secret-value --secret-id /credentials/grafana-user/secret-key --output text --query SecretString)
    # sed -i "s#<AWS_ACCESS_KEY/>#${AWS_ACCESS_KEY}#g" lightsail.sh
    # sed -i "s#<AWS_SECRET_KEY/>#${AWS_SECRET_KEY}#g" lightsail.sh
    cat lightsail.sh
    aws lightsail create-instances --instance-names grafana-${PREFIX} --availability-zone eu-central-1a --blueprint-id ubuntu_22_04 --bundle-id nano_2_0 --user-data file://lightsail.sh
  
    check_lightsail_static_ip_name "$static_ip_name"
    staticip_exit_code=$?
    if [ $staticip_exit_code -eq 0 ]; then
      echo "Lightsail static IP with same name $ip_name already exists."
    else
      echo "IP name does not exist. Creating it for your instance!!!!!"
      aws lightsail allocate-static-ip --static-ip-name grafana-ip-${PREFIX}
      echo "waiting for server to up and running!!!!!!!!!!!"
      sleep 300
      aws lightsail attach-static-ip  --static-ip-name grafana-ip-${PREFIX} --instance-name grafana-${PREFIX}
      aws lightsail open-instance-public-ports --port-info fromPort=3000,toPort=3000,protocol=TCP --instance-name grafana-${PREFIX}
    fi
fi





