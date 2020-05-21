#!/bin/bash

if ! [ -x "$(command -v travis)" ]; then
  echo 'Error: travis is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v aws)" ]; then
  echo 'Error: aws is not installed.' >&2
  exit 1
fi

if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  exit 1
fi

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
  -d | --default)
    USE_DEFAULTS=true
    shift
    ;;
  -p | --profile)
    AWS_PROFILE="$2"
    shift
    ;;
  -r | --region)
    AWS_REGION="$2"
    shift
    ;;
  esac
  shift
done

BO="\033[0;33m"
BLUE="\033[1;34m"
CYAN="\033[1;36m"
RED="\033[0;31m"
NC="\033[0m"

AskForParam() {
  local question="$1"
  read -rp "$question" REPLY
  echo REPLY
}

echo -e "${CYAN}This script securely adds an AWS user's ${NC}${BLUE}AWS_ACCESS_KEY_ID${NC}${CYAN} and ${NC}${BLUE}AWS_SECRET_ACCESS_KEY${NC}${CYAN} to Travis-ci using AWS Secrets Manager.${NC}"
echo -e "${CYAN}The script works by using your host machines AWS credentials to grab sensitive information, then it authenticates to Travis using your generated git token${NC}\n"
echo -e "${BO}To understand how to generate a git token, follow this link https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line${NC}\n"
echo -e "${RED}IMPORTANT:${NC} ${CYAN}The secret where your aws user credentials live must be a key/value pair secret with at least these two keys ${NC}${BLUE}AWS_ACCESS_KEY_ID${NC}${CYAN} and ${NC}${BLUE}AWS_SECRET_ACCESS_KEY${NC}"
echo -e "${RED}IMPORTANT:${NC} ${CYAN}The secret where your gittoken lives must be a key/value pair secret with at least these one key ${NC}${BLUE}token${NC}"
echo ""

GITTOKEN_SECRET=$(AskForParam "What is the id of the secret where your git token lives?")
if [[ $GITTOKEN_SECRET == "" ]] || [[ -z $GITTOKEN_SECRET ]]; then
  echo "git token secret id not supplied" >&2
  exit 1
fi

TRAVIS_USER_SECRET=$(AskForParam "What is the id of the secret where your aws user credentials live?")
if [[ $TRAVIS_USER_SECRET == "" ]] || [[ -z $TRAVIS_USER_SECRET ]]; then
  echo "aws user secret id is not supplied" >&2
  exit 1
fi

if [[ $USE_DEFAULTS != true ]]; then
  if [[ -z $AWS_REGION ]]; then
    AWS_REGION=$(AskForParam "What is the AWS region your secrets live? (defaults to the default profile in ~/.aws/config)")
  fi
  if [[ -z $AWS_PROFILE ]]; then
    AWS_PROFILE=$(AskForParam "What is the AWS profile you'd liek to use to access your secrets? (defaults to the default profile in ~/.aws/credentials)")
  fi
fi

generateCommand() {
  local SECRET="$1"
  local BASE="aws secretsmanager"
  if [[ -n $AWS_PROFILE ]]; then
    BASE="$BASE --profile $AWS_PROFILE"
  fi
  BASE="$BASE get-secret-value"
  if [[ -n $AWS_REGION ]]; then
    BASE="$BASE --region $AWS_REGION"
  fi
  echo "$BASE --secret-id $SECRET | jq -r '.SecretString"
}

GITTOKENRESPONSE=$(eval generateCommand "$GITTOKEN_SECRET")
GITTOKEN=$(eval "$GITTOKENRESPONSE | jq -r '.token'")
if [[ $GITTOKEN == "" ]] || [[ -z $GITTOKEN ]]; then
  echo "Did not find git token from ${GITTOKEN_SECRET}, stopping" >&2
  exit 1
fi

AWS_RESPONSE=$(eval generateCommand "$TRAVIS_USER_SECRET")
AWS_KEY=$(eval "$AWS_RESPONSE | jq -r '.key'")
AWS_SECRET=$(eval "$AWS_RESPONSE | jq -r '.secret'")
if [[ $AWS_KEY == "" ]] || [[ -z $AWS_KEY ]]; then
  echo "Did not find aws key for travis user, stopping" >&2
  exit 1
fi
if [[ $AWS_KEY == "" ]] || [[ -z $AWS_KEY ]]; then
  echo "Did not find aws secret for travis user, stopping" >&2
  exit 1
fi

eval "travis login --pro --github-token $GITTOKEN"
eval "travis env set gittoken $GITTOKEN"
eval "travis env set AWS_ACCESS_KEY_ID $AWS_KEY"
eval "travis env set AWS_SECRET_ACCESS_KEY $AWS_SECRET"