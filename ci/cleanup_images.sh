#!/bin/bash
set -euo pipefail

org="rapidsai"
repo="staging"

delete_image() {
    local org=$1
    local repo=$2
    local tag=$3

    curl --silent --fail-with-body -X DELETE \
        --retry 5 --retry-all-errors \
        -H "Accept: application/json" \
        -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/repositories/$org/$repo/tags/$tag/"

    echo "Deleted image $org/$repo:$tag"
}

fetch_tags() {
    local org=$1
    local repo=$2
    local page=$3

    curl --silent -L --fail-with-body \
        --retry 5 --retry-all-errors \
        -H "Accept: application/json" \
        -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/namespaces/$org/repositories/$repo/tags?page=$page&page_size=100"
}

page=1
next_page="non-null"

while [ "$next_page" != "null" ]; do
    tags_json=$(fetch_tags "$org" "$repo" "$page")
echo "$tags_json" | jq -c '.results[]' | while read -r tag_info; do
        tag_name=$(echo "$tag_info" | jq -r '.name')
        last_pushed=$(echo "$tag_info" | jq -r '.tag_last_pushed')
        last_pushed_ts=$(date --date="$last_pushed" +%s)

        current_time=$(date +%s)
        age_in_days=$(( (current_time - last_pushed_ts) / 86400 )) # 86400 seconds in one day

        if [ "$age_in_days" -gt 30 ]; then
            delete_image "$org" "$repo" "$tag_name"
            sleep 1s
        else
            echo "${tag_name} is less than 30 days old. Not deleting."
        fi
    done

    page=$((page + 1))
    next_page=$(echo "$tags_json" | jq -r '.next')
done
