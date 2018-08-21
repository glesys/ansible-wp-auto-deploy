# GleSYS API/Ansible Demo


## This repo demonstrates how you can automate a wp installation at GleSYS

you can choose to try a clustered installation or single server installation.

## Installation : 

#### Step 1 – API Key
  * create a GleSYS API key with IP, DOMAIN and SERVER privilegies (Permissions / Allow all on Domain, IP, load balancer, filestorage and Server)
  * use a domain which is maintained on your GleSYS project  (record should not pre-exist) if it does it wouldn't be changed.
  * If the domain is not maintained on your GleSYS project you will need to an A record for this cluster manulally.

#### Step 2 - Requirements (where you initiate the script)
  * Ansible 2
  * Sshpass
  * PWGen
  * XMLStarlet
  * Curl
  * Python Passlib Library
  * Nmap
  * Git-core

Below are installation instructions for Debian/Ubuntu and MacOS X. However, it's possible to keep on using your preferred OS, just find the above packages and you'll be good to go.

##### Install these on Debian/Ubuntu

	apt-get install python-dev build-essential python-pip pwgen xmlstarlet curl sshpass nmap python-passlib
	pip install ansible

##### Install these on MacOS X (using Homebrew)

	brew install ansible
	brew install xmlstarlet
	brew install nmap
	brew install pwgen
	brew create https://sourceforge.net/projects/sshpass/files/sshpass/1.06/sshpass-1.06.tar.gz --force
	brew install sshpass
	brew install python
	pip install passlib


### Step 3 - Download and run the script
First download the script:

	git clone https://github.com/GleSYS/wp-auto-deploy.git

## Now go into "cluser" or "single" folder and read README.md for more informations about Installation in each project


#Support
If you need further help send an email to support@glesys.se

