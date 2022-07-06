#!/bin/bash

#yum update -y
#yum install -y httpd.x86_64
#systemctl start httpd.service
#systemctl enable httpd.service
#echo Hello World from $(hostname -f) > /var/www/html/index.html

sudo yum install httpd -y
sudo yum install php -y
sudo systemctl start httpd
sudo systemctl start php
systemctl enable httpd.service
systemctl enable httpd.service
cd /var/www/html
sudo wget https://wordpress.org/latest.zip
sudo unzip latest.zip