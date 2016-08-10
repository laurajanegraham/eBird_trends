#!/bin/bash

# install apt-get
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash

# install git-lfs and pandoc
cd /usr/bin
sudo apt-get update
sudo apt-get -y install git-lfs
sudo apt-get -y install pandoc

# clone repository and set GitHub credentials
cd /home
echo 'Host github.com
  StrictHostKeyChecking no' > ~/.ssh/config
git clone git@github.com:laurajanegraham/eBird_trends.git

# checkout new branch named after the instance id
cd eBird_trends
iid=$(ec2metadata --instance-id)
git checkout -b $iid

# install required packages and run the job script
R -e 'install.packages(c("rmarkdown", "snowfall", "R2jags", "abind", "R2WinBUGS"))'
Rscript -e 'rmarkdown::render("occ_mod.Rmd")' &> run.txt

# push commits to local branch and push to github
git add --all
git commit -m "ec2 run complete"
git push -u origin $iid

# kill instance
sudo halt