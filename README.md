# Introduction

Travis is a great ci/cd tool, but when you want to securely add resources to your AWS account from travis, you must use AWS credentials. 
This cli makes it easier to securely add AWS keys and secrets to travis

IMPORTANT:
A git token is required to log into travis via command line, you can generate one using these [instructions]( https://help.github.com/en/github/authenticating-to-github/creating-a-personal-access-token-for-the-command-line)

#install
```shell script
sudo curl https://raw.githubusercontent.com/ml27299/secure-travis-token/master/install.sh | sudo bash
```
alternatively you can just copy the contents of main.sh and put it in the root directory of the project you want to add the credentials for

# Getting started
Just execute the script like so
```shell script
secure-travis
```
This will ask you a series of questions, one all questions are answered, the script will add the key and secret to travis

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