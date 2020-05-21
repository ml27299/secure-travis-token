# Introduction

Travis is a great ci/cd tool, but when you want to securely add resources to your AWS account from travis, you must use AWS credentials. 
This cli makes it easier to securely add AWS keys and secrets to travis

# Important
A git token is required to log into travis via command line, you can generate one using these [instructions]( https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line)

The script will rely on 2 secrets from AWS Secrets Manager
- **GIT_TOKEN_SECRET** - this secret must be a key/value pair secret with at least 1 key named "token"
- **AWS_USER_SECRET** - this secret must be a key/value pair secret with at least 2 keys named "AWS_ACCESS_KEY_ID" and "AWS_SECRET_ACCESS_KEY"

# Requirements
This script relies on 3 cli packages to do its job
- aws cli ([Learn how to install](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)) 
- travis cli ([Learn how to install](https://github.com/travis-ci/travis.rb#installation))
- jq cli ([Learn how to install](https://stedolan.github.io/jq/download/))

# install
```shell script
curl https://raw.githubusercontent.com/ml27299/secure-travis-token/master/install.sh | sudo bash
```
alternatively you can just copy the contents of main.sh and put it in the root directory of the project you want to add the credentials for

# Getting started
Just execute the script like so
```shell script
secure-travis
```
This will ask you a series of questions, once all questions are answered, the script will add the key and secret to travis

By default the script will use the default AWS profile and region when grabbing the secrets. You can also specify these values via command line like so
```shell script
secure-travis -p myProfile -r us-east-2
#alternatively
secure-travis --profile --region us-east-2
```

If you'd like to use the defaults and tell the script to skip asking for them you can do like so
```shell script
secure-travis -d
#alternatively
secure-travis --default
```