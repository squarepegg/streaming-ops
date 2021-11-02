if [ -n "$LIB_AWS_SECRETS_MANAGER" ]; then return; fi
LIB_AWS_SECRETS_MANAGER=`date`

source $SHELL_OPERATOR_HOOKS_DIR/lib/common.sh

function aws::secrets_manager::write_secret() {
  local secret
  local "${@}"

  local result=$(aws secretsmanager create-secret --region us-west-2 --name nic/test --secret-string "$secret")
  echo "$result"
}
