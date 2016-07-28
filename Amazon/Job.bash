#!/bin/bash

# install apt-get
curl -s https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | sudo bash

# install pandoc
#curl -s https://github.com/jgm/pandoc/releases/tag/1.17.2/pandoc-1.17.2-1-amd64.deb
#sudo dpkg pandoc-1.17.2-1-amd64.deb
#sudo apt-get install -f

# install git-lfs
cd /usr/bin
sudo apt-get install git-lfs

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
R -e 'install.packages(c("rmarkdown", "snowfall", "R2jags"))
Rscript -e "rmarkdown::render('occ_mod.Rmd')" &> run.txt

# push commits to local branch and push to github
git add --all
git commit -m "ec2 run complete"
git push -u origin $iid

# kill instance
sudo halt