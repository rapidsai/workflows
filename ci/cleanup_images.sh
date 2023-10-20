#!/bin/bash

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

    curl --fail-with-body -i \
        -H "Accept: application/json" \
        -H "Authorization: JWT $HUB_TOKEN" \
        "https://hub.docker.com/v2/namespaces/$org/repositories/$repo/tags"
}

tags_json=$(fetch_tags "$org" "$repo")

echo "$tags_json" | jq -c '.results[]' | while read -r tag_info; do
    last_pushed=$(echo "$tag_info" | jq -r '.tag_last_pushed')
    last_pushed_ts=$(date --date="$last_pushed" +%s)

    #age in days
    current_time=$(date +%s)
    age=$(( (current_time - last_pushed_ts) / 86400 ))

    if [ "$age" -gt 30 ]; then
        tag_name=$(echo "$tag_info" | jq -r '.name')
        delete_image "$org" "$repo" "$tag_name"
    fi
done
