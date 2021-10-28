if [ -n "$LIB_CCLOUD_SCHEMA" ]; then return; fi
LIB_CCLOUD_SCHEMA=`date`

source $SHELL_OPERATOR_HOOKS_DIR/lib/common.sh

function ccloud::schema::apply_list() {
	local kafka_id schema
	local "${@}"

	for SCHEMA_ENCODED in $(echo schema | jq -c -r '.[] | @base64'); do

		SCHEMA=$(echo "${SCHEMA_ENCODED}" | base64 -d)

		local subject=$(echo $SCHEMA | jq -r .subject)
		local type=$(echo $SCHEMA | jq -r .type)
		local schema_file=$(echo $SCHEMA | jq -r .schema_file)

		ccloud::schema::apply kafka_id="$kafka_id" subject="$subject" type="$type" schema_file="$schema_file"

	done
}

function ccloud::schema::apply() {
	local kafka_id subject type schema_file
	local "${@}"

	local subject_flag=$([[ $subject == "null" ]] && echo "" || echo "--subject $subject");
	local type_flag=$([[ "$type" == "null" ]] && echo "" || echo "--type ${type}");
	local schema_file_flag=$([[ "$schema_file" == "null" ]] && echo "" || echo "--schema ${schema_file}");

	local version_flag="--version latest"

	retry 30 ccloud schema-registry schema create $subject_flag $schema_file_flag $type_flag &> /dev/null && {

		retry 60 ccloud schema-registry schema describe $subject_flag $version_flag &> /dev/null || {
			echo "Could not obtain description for schema $subject"
			exit 1
		}

		# Experienced some issues with back to back create and the describe of topics
		# 	So the `retry` above waits until the describe returns a valid return code
		#		But them I'm calling it again to properly capture the output in json
		#		form so we can process the description of the topic
		#result=$(ccloud kafka topic describe $name --cluster "$kafka_id" -o json)
		#local current_config=$(echo $result | jq -r -c '.config')
		#[[ "$config" == "null" ]] || ccloud::schema::update name="$name" kafka_id="$kafka_id" config="$config" current_config="$current_config"

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
