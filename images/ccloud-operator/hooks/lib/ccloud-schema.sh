if [ -n "$LIB_CCLOUD_SCHEMA" ]; then return; fi
LIB_CCLOUD_SCHEMA=`date`

source $SHELL_OPERATOR_HOOKS_DIR/lib/common.sh
source $SHELL_OPERATOR_HOOKS_DIR/lib/ccloud-api-key.sh

function ccloud::schema::apply_list() {
	local schema service_account_name resource_id
	local "${@}"

	local secret_name=$(ccloud::api_key::build_api_key_secret_name service_account_name="$service_account_name" resource_id="$resource_id")
	local existing_secret=$(kubectl get secrets/"$secret_name" -o json 2>/dev/null)
	local ccloud_api_key=$(echo "$existing_secret" | jq -r -c '.data."ccloud-api-key"')
  local ccloud_api_key_secret=$(echo "${ccloud_api_key}" | base64 -d)
  local key=$(echo "$ccloud_api_key_secret" | jq -r .key)
  local secret=$(echo "$ccloud_api_key_secret" | jq -r .secret)

	for SCHEMA_ENCODED in $(echo "$schema" | jq -c -r '.[] | @base64'); do

		SCHEMA=$(echo "${SCHEMA_ENCODED}" | base64 -d)

		local subject=$(echo "$SCHEMA" | jq -r .subject)
		local type=$(echo "$SCHEMA" | jq -r .type)
		local schema_file=$(echo "$SCHEMA" | jq -r .schema_file)

		ccloud::schema::apply subject="$subject" type="$type" schema_file="$schema_file" key="$key" secret="$secret"

	done
}

function ccloud::schema::apply() {
	local subject type schema_file key secret
	local "${@}"

	echo "$schema_file" > /usr/schema.file

	retry 30 ccloud schema-registry schema create --subject $subject --type $type --schema /usr/schema.file --api-key $key --api-secret "$secret" &> /dev/null && {

    rm /usr/schema.file

		retry 60 ccloud schema-registry schema describe --subject $subject --version latest --api-key $key --api-secret "$secret" &> /dev/null || {
			echo "Could not obtain description for schema $subject"
			exit 1
		}

		echo "configured schema: $schema"

	} || {
		retcode=$?
		echo "Error creating schema $subject"
		return $retcode
	}
}

function ccloud::schema::update() {
	local name kafka_id config current_config
	local "${@}"

	diff=
	while IFS=',' read -ra cfgs; do
		for c in "${cfgs[@]}"; do
			IFS='=' read -r key value <<< "$c"
			current_value=$(echo "$current_config" | jq -r '."'"$key"'"')
			[[ "$current_value" != "$value" ]] && diff=true
		done
	done <<< "$config"

	[[ "$diff" == "true" ]] && {
		echo "topic: $name updating config"
		ccloud kafka topic update $name --cluster $kafka_id --config $config
	} || echo "topic: $name no change"
}
