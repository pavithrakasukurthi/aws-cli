#!/bin/bash

#creating instances

for instance in $@
do
    echo "Creating $instance..."
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-0220d79f3f480ecf5 --instance-type t3.micro --security-group-ids sg-03b68898754661942 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${instance}}]" --query 'Instances[0].InstanceId' --output text)
    
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID

    if [ "$instance" == "frontend" ]; then
        echo "getting Public IP adress of $instance"
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    else
        echo "getting Private IP adress of $instance"
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    fi

    #updating Route 53 records
     
    echo "Updating Route 53 records"

    RECORD_NAME="${instance}.pavithra.sbs"

    cat <<EOF > route53.json
{
  "Comment": "Updating record set",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "${RECORD_NAME}",
      "Type": "A",
      "TTL": 1,
      "ResourceRecords": [{
        "Value": "${IP}"
      }]
    }
  }]
}
EOF

aws route53 change-resource-record-sets \
      --hosted-zone-id Z0034753Q3D37U6HFEYZ \
      --change-batch file://route53.json

done