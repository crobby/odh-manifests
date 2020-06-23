#!/bin/bash

source $TEST_DIR/common

MY_DIR=$(readlink -f `dirname "${BASH_SOURCE[0]}"`)

source ${MY_DIR}/../util

os::test::junit::declare_suite_start "$MY_SCRIPT"

AI_LIBRARY_CR="${MY_DIR}/../resources/ai_library_cr.yaml"

function create_ai_lib_cr() {
    os::cmd::expect_success "oc create -f ${AI_LIBRARY_CR}"
    header "The AI Library Opeator should create seldondeployments and a dc for the UI, wait for them to show up"
    os::cmd::try_until_not_text "oc get seldondeployment flakes-predict" "not found" odhdefaulttimeout
    os::cmd::try_until_not_text "oc get seldondeployment regression-predict" "not found" odhdefaulttimeout
    os::cmd::try_until_not_text "oc get deploymentconfig ai-library-ui" "not found" odhdefaulttimeout
}

function delete_ai_lib_cr() {
    os::cmd::expect_success "oc delete -f ${AI_LIBRARY_CR}"
    header "The AI Library Opeator should delete seldondeployments and a dc for the UI, wait for them to disappear"
    os::cmd::try_until_text "oc get seldondeployment flakes-predict" "not found" odhdefaulttimeout
    os::cmd::try_until_text "oc get seldondeployment regression-predict" "not found" odhdefaulttimeout
    os::cmd::try_until_text "oc get deploymentconfig ai-library-ui" "not found" odhdefaulttimeout
}

function verify_functionality() {
    header "Verifying that the SeldonDeployments are up and running"
    os::cmd::try_until_text 'oc get seldondeployment flakes-predict -o jsonpath="{$.status.state}"' "Available" odhdefaulttimeout
    os::cmd::try_until_text 'oc get seldondeployment regression-predict -o jsonpath="{$.status.state}"' "Available" odhdefaulttimeout

    # Check that the UI is indeed up by curling the route
    uiroute=$(oc get route ui -o jsonpath="{$.status.ingress[0].host}")
    os::cmd::try_until_text "curl -k https://$uiroute" "AI Library"
}

function test_ai_library_functionality() {
    header "Testing AI Library functionality"
    os::cmd::expect_success "oc project ${ODHPROJECT}"
    create_ai_lib_cr
    verify_functionality
    delete_ai_lib_cr
}

test_ai_library_functionality

os::test::junit::declare_suite_end
