#!/bin/bash

# Personal access token and target GitLab project, overridable via
# environment variables.
declare -r AccessToken="${GITLAB_ACCESS_TOKEN:-XXXXXXXX}"
declare -r ProjectId="${GITLAB_PROJECT_ID:-219}"
declare -r GitDomain="${GITLAB_DOMAIN:-your.gitdomain.com}"

getDockerRepos() {
    curl -s "https://${GitDomain}/api/v4/projects/${ProjectId}/registry/repositories?per_page=100&private_token=${AccessToken}" | jq -r '.[] | .id'
}

getTagsFromRepo() {
    local repoId=$1

    curl -s "https://${GitDomain}/api/v4/projects/${ProjectId}/registry/repositories/${repoId}/tags?per_page=100&private_token=${AccessToken}" | jq -r '.[].location'
}

downloadDockerImages() {
    local repoId=$1
    local tags=($(getTagsFromRepo $repoId))

    for tag in "${tags[@]}"; do
        echo "Fetching tags from repository: $repoId"
        echo "Downloading image: ${tag}"
        docker pull "${tag}"
    done
}

main() {
    local repos=($(getDockerRepos))

    for repoId in "${repos[@]}"; do
        downloadDockerImages $repoId
    done
}

main
