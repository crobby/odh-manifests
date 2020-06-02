#!/bin/bash

echo "Installing kfDef from test directory"

set -x
## Install the opendatahub-operator
## Debugging pause
echo "Debugging pause for 3 hours"
sleep 180m
pushd /peak
echo "Here is the operatorsetup file:"
cat /peak/operatorsetup
./setup.sh -o /peak/operatorsetup 2>&1
echo "Pausing 1 minute to allow operator to start"
sleep 1m
popd
## Grabbing and applying the patch in the PR we are testing
pushd /src/odh-manifests
curl -O -L https://github.com/${REPO_OWNER}/${REPO_NAME}/pull/${PULL_NUMBER}.patch
echo "Applying followng patch:"
cat ${PULL_NUMBER}.patch
git apply ${PULL_NUMBER}.patch
popd
## Point kfctl_openshift.yaml to the manifests in the PR
pushd /kfdef
echo "Setting manifests in kfctl_openshift to use sha: $PULL_PULL_SHA"
sed -i "s#uri: https://github.com/opendatahub-io/odh-manifests/tarball/master#uri: /src/odh-manifests#" ./kfctl_openshift.yaml
echo "Creating the following KfDef"
cat ./kfctl_openshift.yaml
oc create -f ./kfctl_openshift.yaml
set +x
if [ "$?" -ne 0 ]; then
    echo "The installation failed"
    exit $?
fi
popd

echo "Pausing 300 seconds to allow services to spin-up"
sleep 300s
