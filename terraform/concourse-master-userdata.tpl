#!/bin/bash

aws ssm get-parameter --with-decryption --region=${REGION} --name=/github-deploy-key-priv | jq -r .Parameter.Value > /root/.ssh/id_rsa
chmod 0400 /root/.ssh/id_rsa

ansible-pull --purge --accept-host-key --force -U ${GIT_REPO} ansible/build-concourse-master.yml -C ${GIT_BRANCH} -i ansible/inventories/local -e ansible_python_interpreter=python3 --tags pullmode >> /var/log/ansible-pull.log