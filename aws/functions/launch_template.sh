#!/bin/bash

# constants


# sources

# functions
create_launch_template() {
    local template_name="$1"
    local description="$2"
    local image_id="$3"
    local instance_type="$4"
    local key_name="$5"
    local name_tag="$6"
    local security_groups_ids_arr=("${@:7}")

    if [[ -z "$template_name" ]]; then
        echo "invalid function call: 'create_launch_template' is called with no template_name" >&2
        return 1
    fi

    if [[ -z "$description" ]]; then
        echo "invalid function call: 'create_launch_template' is called with no description" >&2
        return 1
    fi

    if [[ -z "$image_id" ]]; then
        echo "invalid function call: 'create_launch_template' is called with no image_id" >&2
        return 1
    fi

    if [[ -z "$instance_type" ]]; then
        echo "invalid function call: 'create_launch_template' is called with no instance_type" >&2
        return 1
    fi

    if [[ -z "$key_name" ]]; then
        echo "invalid function call: 'create_launch_template' is called with no key_name" >&2
        return 1
    fi

    if [[ -z "$name_tag" ]]; then
        echo "invalid function call: 'create_launch_template' is called with no name_tag" >&2
        return 1
    fi

    if [[ ${#security_groups_ids_arr[@]} -eq 0 ]]; then
        echo "invalid function call: 'create_launch_template' is called with no security_groups_ids" >&2
        return 1
    fi

    local security_groups_ids_string
    security_groups_ids_string=$(printf '"%s",' "${security_groups_ids_arr[@]}")

    local template_id
    template_id=$(aws ec2 create-launch-template \
                    --launch-template-name "$template_name" \
                    --version-description "$description" \
                    --query "LaunchTemplate.LaunchTemplateId" \
                    --output text \
                    --launch-template-data "$(cat << EOF
{
    "ImageId": "$image_id", 
    "InstanceType": "$instance_type",
    "KeyName": "$key_name",
    "TagSpecifications": [
        {
            "ResourceType": "instance",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "$name_tag"
                }
            ]
        },
        {
            "ResourceType": "volume",
            "Tags": [
                {
                    "Key": "Name",
                    "Value": "disk-$name_tag"
                }
            ]
        }
    ],
    "SecurityGroupIds": [${security_groups_ids_string%,}]
}
EOF
)" 
                ) || return "$?"

    echo "$template_id"
}