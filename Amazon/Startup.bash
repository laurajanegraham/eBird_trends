#!bin/bash

# launch the EC2 instance from the terminal
instance_id=$(aws ec2 run-instances --image-id ami-ca149fb9 --security-group-ids sg-00763967 --count 1 --instance-type m4.xlarge --key-name GrahamAmazon --instance-initiated-shutdown-behavior terminate --query 'Instances[0].{d:InstanceId}' --output text)

# wait until the instance is running before doing anything else
aws ec2 wait instance-running --instance-ids $instance_id

# save the public DNS of the instance
dns=$(aws ec2 describe-instances --instance-ids $instance_id --query 'Reservations[*].Instances[*].PublicDnsName' --output text | grep a)
echo $dns

# wait until port 22 is available on the instance
wait_for_port() {
  local port=22
  local host=$dns
  while ! nc -z "$host" "$port" >/dev/null; do
  sleep 5
  done
}
wait_for_port

# Set up Github access key forwarding 
echo 'Host *.eu-west-1.compute.amazonaws.com
   ForwardAgent yes' > ~/.ssh/config
  
# use SSH to remotely change the ownership of home and R library location so that we can make changes
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/GrahamAmazon.pem ubuntu@$dns "sudo chown -R ubuntu:ubuntu /home"
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/GrahamAmazon.pem ubuntu@$dns "sudo chown -R ubuntu:ubuntu /usr/local/lib/R/site-library/"

# secure copy Job.bash which contains everything we want to run on the AWS instance
scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/GrahamAmazon.pem ~/Documents/eBird_trends/Amazon/Job.bash ubuntu@$dns:/home

# run Job.bash
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/.ssh/GrahamAmazon.pem ubuntu@$dns "bash /home/Job.bash"
