sudo su
apt update
snap install docker

cd /home/ubuntu
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt install unzip -y
unzip awscliv2.zip
./aws/install
sleep 300
rm -rf awscliv2.zip

# export AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY/>
# export AWS_SECRET_ACCESS_KEY=<AWS_SECRET_KEY/>
# export AWS_ACCESS_KEY_ID=AKIAQWJKMUG6VSEUIM54
# export AWS_SECRET_ACCESS_KEY=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
touch beforecred
aws configure set aws_access_key_id AKIAQWJKMUG6VSEUIM54
aws configure set aws_secret_access_key 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
touch aftercred
sleep 30
docker login -u AWS -p $(aws ecr get-login-password --region eu-central-1) 047870419389.dkr.ecr.eu-central-1.amazonaws.com
docker pull 047870419389.dkr.ecr.eu-central-1.amazonaws.com/lightsail:latest
docker images >> test.txt
docker run -d -p 3000:3000 047870419389.dkr.ecr.eu-central-1.amazonaws.com/lightsail:latest