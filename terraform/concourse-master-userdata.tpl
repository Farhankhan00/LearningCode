#!/bin/bash

ansible-pull --purge --accept-host-key --force -U ${GIT_REPO} ansible/build-concourse-master.yml -C ${GIT_BRANCH} -i ansible/inventories/local --tags pullmode >> /var/log/ansible-pull.log