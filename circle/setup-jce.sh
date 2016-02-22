#!/usr/bin/env bash

# Downloads the java 8 JCE Unlimited Policy and installs it

set -e

curl -b oraclelicense=accept-securebackup-cookie -L https://edelivery.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip -o jce_policy-8.zip
unzip jce_policy-8.zip
sudo cp UnlimitedJCEPolicyJDK8/* /usr/lib/jvm/jdk1.8.0/jre/lib/security/