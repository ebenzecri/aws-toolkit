# aws-toolkit
Amazon Web Services (AWS) tools

## cleanmyami.sh
Clean an EC2 instance before create a new AMI

### Usage
#### As non root user
[Hit the spacebar] set +o history

history -c

sudo -i

#### As root user
[Hit the spacebar] set +o history

history -c

bash <(curl -s https://raw.githubusercontent.com/ebenzecri/aws-toolkit/master/cleanmyami.sh)

### What this script does?

* Delete files or directories you specify
* Delete SSH keys from all users
* Clean cached packages
* Clean logs
* Clean bash history for all users
