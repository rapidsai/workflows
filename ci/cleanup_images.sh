#!/bin/bash
set -euo pipefail

org="rapidsai"
repo="staging"

delete_image() {
    local org=$1
    local repo=$2
    local tag=$3

    curl --fail-with-body -i -X DELETE \
        -H "Accept: application/json" \
        -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/repositories/$org/$repo/tags/$tag/"
    
    echo "Deleted image $org/$repo:$tag"
}

fetch_tags() {
    local org=$1
    local repo=$2
    local page=$3

    curl --fail-with-body -i \
        -H "Accept: application/json" \
        -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/namespaces/$org/repositories/$repo/tags?page=$page&page_size=100"
}

tags_json=$(fetch_tags "$org" "$repo" 1)
next_page=$(echo "$tags_json" | jq -r '.next')

while [ ! -z "$next_page" ] && [ "$next_page" != "null" ]; do
    echo "$tags_json" | jq -c '.results[]' | while read -r tag_info; do
        last_pushed=$(echo "$tag_info" | jq -r '.tag_last_pushed')
        last_pushed_ts=$(date --date="$last_pushed" +%s)

        # age in days
        current_time=$(date +%s)
        age=$(( (current_time - last_pushed_ts) / 86400 ))

        if [ "$age" -gt 30 ]; then
            tag_name=$(echo "$tag_info" | jq -r '.name')
            delete_image "$org" "$repo" "$tag_name"
        fi
    done

    # Extract next page number
    next_page_num=$(echo "$next_page" | grep -o 'page=[0-9]*' | cut -d "=" -f 2)
    
    # Load next page
    tags_json=$(fetch_tags "$org" "$repo" "$next_page_num")
    next_page=$(echo "$tags_json" | jq -r '.next')
done
