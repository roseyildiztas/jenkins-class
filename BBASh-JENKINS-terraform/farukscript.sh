# bash -c "$(curl https://bucket-to-check-aws-tasks.s3.amazonaws.com/AWS/scripts/shared_scripts/jenkins_menu.sh)"

#!/bin/bash

rs=`tput sgr0`    # reset
g=`tput setaf 2`  # green
y=`tput setaf 3`  # yellow
r=`tput setaf 1`  # red
b=`tput bold`     # bold
u=`tput smul`     # underline
nu=`tput rmul`    # no-underline

echo "
[${y}1${rs}] Build a Jenkins environment
[${y}2${rs}] Destroy a Jenkins environment
"
read -p "What would you like to do? : " RESPONSE
if [ $RESPONSE == 1 ] 2>/dev/null;
then
  echo ""
  echo "${g}It might take up to ${y}5 minutes${g} to build jenkins environment, please wait a moment${rs}."
  echo ""
  cd
  sleep 5
  mkdir -p .jenkins
  cd .jenkins
  wget -c https://releases.hashicorp.com/terraform/0.14.7/terraform_0.14.7_linux_amd64.zip
  unzip -o terraform_0.14.7_linux_amd64.zip
  curl https://bucket-to-check-aws-tasks.s3.amazonaws.com/AWS/scripts/shared_scripts/jenkins_environment.sh > provider.tf
  ./terraform init
  ./terraform plan
  ./terraform apply --auto-approve
elif [ $RESPONSE == 2 ] 2>/dev/null;
then
  cd
  cd .jenkins
  ./terraform destroy --auto-approve
  cd ..
  rm -rf .jenkins
else
  echo "${r}Something broke, please run the script again${rs}."
fi: No such file or directory