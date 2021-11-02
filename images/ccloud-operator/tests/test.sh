#!/usr/bin/env bash

source ../hooks/lib/common.sh

name="ShellOperatorTest"
env_id="yb1"

function ccloud::env::apply_env_id_configmap() {
  local name
  local id
  local "${@}"
  local env_name=$(common::to_lower_case string_to_lower="$name")
  echo $env_name
  #kubectl create configmap "cc.env.$env_name" --from-literal="id"="$id" --dry-run=client -o yaml | kubectl label -f - --dry-run=client -o yaml --local resource_id=$id | kubectl apply -f - >/dev/null 2>&1
}

result=$(ccloud::env::apply_env_id_configmap name="$name" id="$env_id")
#result=$(common::to_lower_case string_to_lower="cc.env.$env.kafka.nic-test-1")
expected="shelloperatortest"

if [[ "${result}" == "${expected}" ]]; then
  echo "Test passed!"
else
  echo "Test failed!"
  exit 1
fi

