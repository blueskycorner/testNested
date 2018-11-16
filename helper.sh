#!/bin/bash

# Variables 
STDOUT_RED="\033[0;31m"
STDOUT_YELLOW="\033[0;33m"
STDOUT_DEFAULT="\033[0m"

# generic
AWS_PROFILE="default"
TEMPLATE_BUCKET="behlers-test"
STACK_NAME="iolab-test"
TEMPLATE_NAME="iolab-root.yaml"
KEY_PAIR_NAME="vygon-bastion-dev"
BASTION_INSTANCE_TYPE="t2.micro"
SERVER_INSTANCE_TYPE="t2.micro"
DB_MASTER_PASSWORD="master1234"

usage()
{
    echo -e "${STDOUT_RED}$1"
    echo -e "${STDOUT_YELLOW}Usage: $0  <upload | validate | deploy>"
    exit 1
}

upload()
{
    aws s3 cp ./Cloudformation s3://${TEMPLATE_BUCKET}/stack --recursive  --exclude "iolab-root.yaml" --include "*.yaml" --profile ${AWS_PROFILE}
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -p|--profile)
        export AWS_PROFILE=$2
        shift # past argument
        shift # past value
        ;;
        *)
        POSITIONAL+=("$1")
        shift # past command
        ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ $1 == "upload" ]; then 
    # Upload Cfn templates to S3 bucket 
    upload
    exit $?
fi

if [ $1 == "validate" ]; then 
    # Validate Root template
    for filename in ./Cloudformation/*.yaml ; do
        echo -e ${STDOUT_YELLOW}validating $filename template...${STDOUT_DEFAULT}
        aws cloudformation validate-template --template-body file://$filename
    done
    exit $?
fi

if [ $1 == "deploy" ]; then 
    # upload templates
    upload

    # Deploy stack
    aws cloudformation deploy  \
        --stack-name $STACK_NAME \
        --template-file ./Cloudformation/${TEMPLATE_NAME}  \
        --parameter-overrides TemplateBucket=${TEMPLATE_BUCKET} \
                              KeyPairName=${KEY_PAIR_NAME} \
                              bastionInstanceType=${BASTION_INSTANCE_TYPE} \
                              serverInstanceType=${SERVER_INSTANCE_TYPE} \
                              dbMasterPassword=${DB_MASTER_PASSWORD} \
        --capabilities CAPABILITY_IAM \
         --profile ${AWS_PROFILE} \

    echo -e "\a"
    exit $?
fi

usage "Failed script execution!"