# Introduction

Travis is a great ci/cd tool, but when you want to securely add resources to your AWS account from travis, you must use AWS credentials. 
This cli makes it easier to securely add AWS keys and secrets to travis

# Important
A git token is required to log into travis via command line, you can generate one using these [instructions]( https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line). 
Once you have a git token, add it to AWS Secrets Manager

The script will rely on 2 secrets from AWS Secrets Manager
- **GIT_TOKEN_SECRET** - this secret must be a key/value pair secret with at least 1 key named "token"
- **AWS_USER_SECRET** - this secret must be a key/value pair secret with at least 2 keys named "AWS_ACCESS_KEY_ID" and "AWS_SECRET_ACCESS_KEY"

# Requirements
- aws cli ([Learn how to install](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)) 
- travis cli ([Learn how to install](https://github.com/travis-ci/travis.rb#installation))
- jq cli ([Learn how to install](https://stedolan.github.io/jq/download/))

NOTE:
The install may not work for Windows machines

# Install
```shell script
curl https://raw.githubusercontent.com/ml27299/secure-travis-token/master/install.sh | sudo bash
```
alternatively you can just copy the contents of main.sh and put it in the root directory of the project you want to add the credentials for

When the script installs it will add itself to /usr/local/bin and create a file in $HOME/.secure-travis/default.config, use this file to set environment variables

# Environment variables
You can get around having to answer questions or passing options to the script by filling out the $HOME/.secure-travis/default.config file

$HOME/.secure-travis/default.config
```editorconfig
AWS_USER_SECRET=awsUserSecretId
GIT_TOKEN_SECRET=gitTokenSecretId
AWS_REGION=us-east-2
AWS_PROFILE=myAwsProfile
```

# Getting started
Just go to the root directory of your git project and execute the script like so
```shell script
cd /path/to/git/project
secure-travis
```
This will ask you a series of questions, once all questions are answered, the script will add the key and secret to travis

By default the script will ask you to enter an AWS profile and region to use when grabbing the secrets. You can also specify these values via command line like so, this will cause the script to not ask those questions
```shell script
secure-travis -p myProfile -r us-east-2
#alternatively
secure-travis --profile --region us-east-2
```

If you'd like to use the defaults located in **~/.aws/config** and **~/.aws/credentials** and tell the script to skip asking for them you can do like so
```shell script
secure-travis -d
#alternatively
secure-travis --default
```