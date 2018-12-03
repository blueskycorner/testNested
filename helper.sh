#!/bin/bash

# Variables 
STDOUT_RED="\033[0;31m"
STDOUT_YELLOW="\033[0;33m"
STDOUT_DEFAULT="\033[0m"

# generic
#AWS_PROFILE="default"
AWS_PROFILE="iolab"
TEMPLATE_BUCKET="iolab-deployment"
PROJECT_NAME="AppMigration"
STACK_NAME="app-migration"
TEMPLATE_NAME="iolab-root.yaml"

usage()
{
    echo -e "${STDOUT_RED}$1"
    echo -e "${STDOUT_YELLOW}Usage: $0  <upload | cb | validate | deploy>"
    exit 1
}

upload()
{
    aws s3 cp ./Cloudformation s3://${TEMPLATE_BUCKET}/stack --recursive  --exclude "iolab-root.yaml" --include "*.yaml" --profile ${AWS_PROFILE}
    # aws s3 cp ./StartScheduledInstances.zip s3://${TEMPLATE_BUCKET}/lambda/StartScheduledInstances.zip --profile ${AWS_PROFILE}
    # aws s3 cp ./StopScheduledInstances.zip s3://${TEMPLATE_BUCKET}/lambda/StopScheduledInstances.zip --profile ${AWS_PROFILE}
}

create_bucket()
{
    aws s3 mb s3://${TEMPLATE_BUCKET} --profile ${AWS_PROFILE}
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

if [ $1 == "cb" ]; then 
    # Create bucket 
    create_bucket
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
                              ProjectName=${PROJECT_NAME} \
        --capabilities CAPABILITY_IAM \
         --profile ${AWS_PROFILE} \

    echo -e "\a"
    exit $?
fi

usage "Failed script execution!"