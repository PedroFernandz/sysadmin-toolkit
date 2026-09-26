#!/bin/bash

## Personal access token for GitLab API
declare -r AccessToken="${GITLAB_ACCESS_TOKEN:-XXXXX}"

## GitLab instance hosting the container registry
declare -r GitDomain="${GITLAB_DOMAIN:-your.gitdomain.com}"

### Source and destination project paths for the migration
declare -r originProj="${GITLAB_ORIGIN_PROJECT_ID:-1306}"
declare -r originProjPath="${GITLAB_ORIGIN_PROJECT_PATH:-path/origin}"
declare -r destProjPath="${GITLAB_DEST_PROJECT_PATH:-path/dest}"

declare -A Repositories
declare -a Tags=()
declare -a Dockers=()

getReposList() {
    declare -a repos=( $(curl -s "https://${GitDomain}/api/v4/projects/${originProj}/registry/repositories?per_page=100&access_token=${AccessToken}"  | jq '.[] | "\(.id):\(.location)"  ' -r ) )

    for repo in ${repos[@]}; do
        Repositories[${repo%%:*}]=${repo#*:}
    done
    return 0
}

getTags() {
    Tags=( $(curl -s "https://${GitDomain}/api/v4/projects/${originProj}/registry/repositories/${repo}/tags?per_page=100&access_token=${AccessToken}"  | jq '.[].name' -r) )
    return 0
}

# Renames an image to the destination path, with special-case handling for
# legacy-app/php-version images and their -dev tag variants.
filterLegacyAppDockers() {
    [[ "${destDocker}" =~ ${destProjPath}/php-[0-9].[0-9] ]] \
        && destDocker=${destDocker/app-php-fpm/app-php-fpm/jail}

    [[ "${destDocker}" =~ ${destProjPath}/legacy-app ]] \
        && {
            phpVer=${destDocker##*:}
            tag=${phpVer/[0-9].[0-9]/}
            tag=${tag/dev-/}
            tag=${tag#.}

            destDocker="${destDocker/legacy-app-ssh:/ssh}"
            destDocker="${destDocker/legacy-app:/fpm}"
            destDocker="${destDocker%%[0-9].[0-9]*}"
            destDocker="${destDocker/dev-/}/${phpVer/.${tag:-latest}/}:${tag:-latest}"
        }

    [[ "${destDocker}" =~ ${destProjPath}/(ssh|fpm)/dev- ]] \
        && destDocker="${destDocker/\/dev-//}-dev"

    [[ "${destDocker}" =~ ${destProjPath}/(ssh|fpm|jail)/.*:[0-9]*-dev-[0-9]{8} ]] \
        && destDocker="${destDocker/-dev-/-}-dev"

    return 0
}

migrateDockers() {
    for d in ${Dockers[@]} ; do
        destDocker=${d/${originProjPath/\//\\\/}/${destProjPath}}
        filterLegacyAppDockers
        echo -e "${d} \t » ${destDocker}"

        docker pull ${d} || return 1
        docker tag ${d} ${destDocker}
        docker push ${destDocker} || return 1
        echo -e " * ${d} » ${destDocker} : Ok"
    done

    return 0
}

getReposList

for repo in ${!Repositories[@]} ; do
    getTags
    for tag in ${Tags[@]}; do
        Dockers+=( ${Repositories[$repo]}:${tag} )
    done
    echo -e "${#Dockers[@]}\t| $repo » ${Repositories[$repo]} \n\t|    »» ${Tags[@]} \n"
done

echo -e "\n\tMigrate Dockers (${#Dockers[@]}): \n"
migrateDockers
