#!/bin/bash
sudo yum update
sudo yum -y install nginx
sudo systemctl start nginx
sudo systemctl enable nginx