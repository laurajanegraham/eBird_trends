#!/bin/bash

# install apt-get
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash

# install git-lfs
cd /usr/bin
sudo apt-get install git-lfs

# clone repository and set GitHub credentials
cd /home
echo 'Host github.com
  StrictHostKeyChecking no' > ~/.ssh/config
git clone git@github.com:laurajanegraham/ec2test.git

# checkout new branch named after the instance id
cd ec2test
iid=$(ec2metadata --instance-id)
git checkout -b $iid

# run the job script
Rscript -e "rmarkdown::render('occ_mod.Rmd')" &> run.txt

# push commits to local branch and push to github
git add --all
git commit -m "ec2 run complete"
git push -u origin $iid

# kill instance
sudo halt