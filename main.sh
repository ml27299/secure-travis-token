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

while read -r var
do
    export "${var?}"
done < "$HOME/.secure-travis/default.config"

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

trim() {
    local var="$*"
    # remove leading whitespace characters
    var="${var#"${var%%[![:space:]]*}"}"
    # remove trailing whitespace characters
    var="${var%"${var##*[![:space:]]}"}"
    printf '%s' "$var"
}

AskForParam() {
  local question="$1"
  read -rp "$question " REPLY
  echo "$(trim "$REPLY")"
}

AskIfParamOk() {
  read -rp "Is this information correct? " REPLY
  if [[ $REPLY =~ ^[Yy]$ ]]; then echo true;
	else echo false; fi
}

echo -e "${CYAN}This script securely adds an AWS user's ${NC}${BLUE}AWS_ACCESS_KEY_ID${NC}${CYAN} and ${NC}${BLUE}AWS_SECRET_ACCESS_KEY${NC}${CYAN} to Travis-ci using AWS Secrets Manager.${NC}"
echo -e "${CYAN}The script works by using your host machines AWS credentials to grab sensitive information, then it authenticates to Travis using your generated git token${NC}\n"
echo -e "${BO}To understand how to generate a git token, follow this link https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line${NC}\n"
echo -e "${RED}IMPORTANT:${NC} ${CYAN}The secret where your aws user credentials live must be a key/value pair secret with at least these two keys ${NC}${BLUE}AWS_ACCESS_KEY_ID${NC}${CYAN} and ${NC}${BLUE}AWS_SECRET_ACCESS_KEY${NC}"
echo -e "${RED}IMPORTANT:${NC} ${CYAN}The secret where your gittoken lives must be a key/value pair secret with at least these one key ${NC}${BLUE}token${NC}"
echo ""

if [[ -z $GIT_TOKEN_SECRET ]]; then
  GIT_TOKEN_SECRET=$(AskForParam "What is the id of your git token secret?")
  if [[ $GIT_TOKEN_SECRET == "" ]] || [[ -z $GIT_TOKEN_SECRET ]]; then
    echo "git token secret id not supplied" >&2
    exit 1
  fi
fi

if [[ -z $AWS_USER_SECRET ]]; then
  AWS_USER_SECRET=$(AskForParam "What is the id of your aws user secret?")
  if [[ $AWS_USER_SECRET == "" ]] || [[ -z $AWS_USER_SECRET ]]; then
    echo "aws user secret id is not supplied" >&2
    exit 1
  fi
fi

if [[ $USE_DEFAULTS != true ]]; then
  if [[ -z $AWS_REGION ]]; then
    AWS_REGION=$(AskForParam "What AWS region are your secrets located? (defaults to the default profile in ~/.aws/config)")
  fi
  if [[ -z $AWS_PROFILE ]]; then
    AWS_PROFILE=$(AskForParam "What is the AWS profile you'd like to use to access your secrets? (defaults to the default profile in ~/.aws/credentials)")
  fi
fi

if [[ $USE_DEFAULTS = true ]]; then
  if [[ -n $AWS_REGION ]]; then
    unset AWS_REGION
  fi
  if [[ -n $AWS_PROFILE ]]; then
    unset AWS_PROFILE
  fi
fi

echo "GIT_TOKEN_SECRET: $GIT_TOKEN_SECRET"
echo "AWS_USER_SECRET: $AWS_USER_SECRET"
if [[ -n $AWS_REGION ]]; then
    echo "AWS_REGION: $AWS_REGION"
  else
    echo "AWS_REGION: default"
fi
if [[ -n $AWS_PROFILE ]]; then
    echo "AWS_PROFILE: $AWS_PROFILE"
  else
    echo "AWS_PROFILE: default"
fi

if [[ $(AskIfParamOk) == false ]]; then
  GIT_TOKEN_SECRET=$(AskForParam "What is the id of your git token secret?")
  if [[ $GIT_TOKEN_SECRET == "" ]] || [[ -z $GIT_TOKEN_SECRET ]]; then
    echo "git token secret id not supplied" >&2
    exit 1
  fi
  AWS_USER_SECRET=$(AskForParam "What is the id of your aws user secret?")
  if [[ $AWS_USER_SECRET == "" ]] || [[ -z $AWS_USER_SECRET ]]; then
    echo "aws user secret id is not supplied" >&2
    exit 1
  fi
  if [[ $USE_DEFAULTS != true ]]; then
    AWS_REGION=$(AskForParam "What AWS region are your secrets located? (defaults to the default profile in ~/.aws/config)")
    AWS_PROFILE=$(AskForParam "What is the AWS profile you'd like to use to access your secrets? (defaults to the default profile in ~/.aws/credentials)")
  fi
  echo "GIT_TOKEN_SECRET: $GIT_TOKEN_SECRET"
  echo "AWS_USER_SECRET: $AWS_USER_SECRET"
  if [[ -n $AWS_REGION ]]; then
      echo "AWS_REGION: $AWS_REGION"
    else
      echo "AWS_REGION: default"
  fi
  if [[ -n $AWS_PROFILE ]]; then
      echo "AWS_PROFILE: $AWS_PROFILE"
    else
      echo "AWS_PROFILE: default"
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
  echo "$BASE --secret-id $SECRET | jq -r '.SecretString'"
}

GITTOKENRESPONSE=$(generateCommand "$GIT_TOKEN_SECRET")
GITTOKEN=$(eval "$GITTOKENRESPONSE | jq -r '.token'")
if [[ $GITTOKEN == "" ]] || [[ -z $GITTOKEN ]]; then
  echo "Did not find git token from ${GIT_TOKEN_SECRET}, stopping" >&2
  exit 1
fi

AWS_RESPONSE=$(generateCommand "$AWS_USER_SECRET")
AWS_KEY=$(eval "$AWS_RESPONSE | jq -r '.AWS_ACCESS_KEY_ID'")
AWS_SECRET=$(eval "$AWS_RESPONSE | jq -r '.AWS_SECRET_ACCESS_KEY'")
if [[ $AWS_KEY == "" ]] || [[ -z $AWS_KEY ]]; then
  echo "Did not find aws key from $AWS_USER_SECRET, stopping" >&2
  exit 1
fi
if [[ $AWS_KEY == "" ]] || [[ -z $AWS_KEY ]]; then
  echo "Did not find aws secret from $AWS_USER_SECRET, stopping" >&2
  exit 1
fi

eval "travis login --pro --github-token $GITTOKEN"
eval "travis env set gittoken $GITTOKEN"
eval "travis env set AWS_ACCESS_KEY_ID $AWS_KEY"
eval "travis env set AWS_SECRET_ACCESS_KEY $AWS_SECRET"