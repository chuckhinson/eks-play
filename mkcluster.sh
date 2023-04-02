#!/bin/bash

# Script to create cluster using eksctl.  Note this script is obsolete now that I've got 
# everything setup in terraform.  I'm keeping this script for now since it'll make it easier
# to do experiments with eksctl to see what kind of cloud formation in generates for certain
# configurations

terraform -chdir=./terraform apply

AWS_PROFILE_NAME=$(terraform -chdir=./terraform output -json | jq -r '.aws_profile_name.value')
PROJECT_NAME=$(terraform -chdir=./terraform output -json | jq -r '.project_name.value')
PRIVATE_SUBNET1=$(terraform -chdir=./terraform output -json | jq -r '.private_subnet1.value')
PRIVATE_SUBNET2=$(terraform -chdir=./terraform output -json | jq -r '.private_subnet2.value')
PUBLIC_SUBNET1=$(terraform -chdir=./terraform output -json | jq -r '.public_subnet1.value')
PUBLIC_SUBNET2=$(terraform -chdir=./terraform output -json | jq -r '.public_subnet2.value')

# NOTE: if you want to do dry-run, you cant use --profile, so you willl need to set AWS_PROFILE env variable

eksctl create cluster  --profile ${AWS_PROFILE_NAME} --name ${PROJECT_NAME} --region us-gov-west-1  \
        --vpc-public-subnets "${PUBLIC_SUBNET1},${PUBLIC_SUBNET2}" --vpc-private-subnets "${PRIVATE_SUBNET1},${PRIVATE_SUBNET2}" \
        --node-private-networking
