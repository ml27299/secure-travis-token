TAG=$1

if [[ $TAG == "" ]] || [[ -z $TAG ]]; then
  TAG="secure-travis"
fi

if ((EUID != 0)); then
  echo "Please run command as root."
  exit
fi

FILE="https://raw.githubusercontent.com/ml27299/secure-travis-token/master/main.sh"

if [[ -f  "/usr/local/bin/$TAG" ]]; then
  rm  /usr/local/bin/$TAG
fi

curl -sL -o- ${FILE} > /usr/local/bin/$TAG

chmod a+x /usr/local/bin/$TAG

echo "Installed secure-travis-token!"