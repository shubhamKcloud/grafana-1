sudo su
apt update
snap install docker

cd /home/ubuntu
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
apt install unzip -y
unzip awscliv2.zip
./aws/install
rm -rf awscliv2.zip

export AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY/>
export AWS_SECRET_ACCESS_KEY=<AWS_SECRET_KEY/>

docker login -u AWS -p $(aws ecr get-login-password --region eu-central-1) 250373516626.dkr.ecr.eu-central-1.amazonaws.com
docker pull 250373516626.dkr.ecr.eu-central-1.amazonaws.com/lightsail:latest
docker images >> test.txt
docker run -d -p 3000:3000 250373516626.dkr.ecr.eu-central-1.amazonaws.com/lightsail:latest