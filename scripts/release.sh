#!/usr/bin/env bash -e

. gradle.properties
. local.properties

version=${VERSION_NAME%*-SNAPSHOT}
baseVersion=${version%*.*}
nextBuild=$((${version##*.} + 1))
nextVersion="${baseVersion}.${nextBuild}-SNAPSHOT"

echo "Starting release for logback-ext-${version} ..."

fail() {
    echo "error: $1" >&2
    exit 1
}

# Run Git integrity checks early (gradle-release-plugin does this
# after we update the readme) to avoid premature push of new readme
[[ "$(git rev-parse master)" != "$(git rev-parse origin/master)" ]] && fail "branches out of sync"
[[ -n "$(git status -u -s)" ]] && fail "found unstaged changes"

# gradle-release-plugin prompts for your Nexus credentials
# with "Please specify username" (no mention of Nexus).
# Use our own prompt to remind the user where they're
# logging into to.
user=${NEXUS_USERNAME}
pass=${NEXUS_PASSWORD}
[ -z "$user" ] && read -p "Nexus username: " user
[ -z "$pass" ] && read -p "Nexus password: " -s pass

#bintray_user=${BINTRAY_USER}
#bintray_key=${BINTRAY_KEY}
#[ -z "$bintray_user" ] && read -p "Bintray username: " bintray_user
#[ -z "$bintray_key" ] && read -p "Bintray API key: " bintray_key
#echo ''

./gradlew   -Prelease.useAutomaticVersion=true  \
            -Prelease.releaseVersion=${version} \
            -Prelease.newVersion=${nextVersion} \
            -Pversion=${version}                \
            -PVERSION_NAME=${version}           \
            -PNEXUS_USERNAME=${user}            \
            -PNEXUS_PASSWORD=${pass}            \
            -Ppush                              \
            -x test                             \
            clean                               \
            readme                              \
            release                             \
            uploadArchives

#./gradlew   -PBINTRAY_USER=${BINTRAY_USER}      \
#            -PBINTRAY_KEY=${BINTRAY_KEY}        \
#            bintrayUpload

# To deploy archives without git transactions (tagging, etc.),
# replace the `release` task above with `assembleRelease`.

echo -e "\n\n"

# FIXME: In test repo, this can't checkout 'gh-pages' -- no error provided
#./gradlew   uploadDocs
echo TODO: upload javadocs to gh-pages with:
echo scripts/deploydocs.sh ${version}

# FIXME: hub is no longer able to find tagged releases for some reason.
#hub release edit -m '' v_${version} -a build/logback-extensions-${version}.jar
echo TODO: attach uber jar to release at:
echo https://github.com/qos-ch/logback-extensions/releases/tag/v_${version}
