if [ -n "$LIB_AWS_SECRETS_MANAGER" ]; then return; fi
LIB_AWS_SECRETS_MANAGER=`date`

function aws::secrets_manager::write_secret() {
  local secret_name secret_string
  local "${@}"

  local result

  local existing_secret=$(aws secretsmanager list-secrets | jq -r '.[]' | jq '.[] | select(.Name == "'"$secret_name"'")')

  if [[ -z "$existing_secret" ]]; then
    result=$(aws secretsmanager create-secret --region us-west-2 --name "$secret_name" --secret-string "$secret_string")
    echo "AWS Secrets Manager Secret $secret_name created"
  else
    result=$(aws secretsmanager update-secret --region us-west-2 --secret-id "$secret_name" --secret-string "$secret_string")
    echo "AWS Secrets Manager Secret $secret_name updated"
  fi

  echo "$result"
}
