#!/bin/bash

#                  _            _            
#  _ __  _ __ ___ | |_ ___   __| | _____   __
# | '_ \| '__/ _ \| __/ _ \ / _` |/ _ \ \ / /
# | |_) | | | (_) | || (_) | (_| |  __/\ V / 
# | .__/|_|  \___/ \__\___/ \__,_|\___| \_/  
# |_|
# 

## Copyright ##################################################################
#
# Copyright © 2016 Gerik Bonaert <dev@adaxisoft.be>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Functions ##################################################################

set -eu

Info () {
	echo "I: ${*}" >&2
}

Error () {
	echo "E: ${*}" >&2
}

## Configuration ##############################################################

SOURCE="$(dpkg-parsechangelog | awk '/^Source:/ { print $2 }')"
VERSION="$(dpkg-parsechangelog | awk '/^Version:/ { print $2 }')"
CHANGELOG_DISTRIBUTION="$(dpkg-parsechangelog | awk '/^Distribution:/ { print $2 }')"

Info "Starting build of ${SOURCE} using protodev"

PROTODEV_BUILD_DIR="${PROTODEV_BUILD_DIR:-/build}"
PROTODEV_TARGET_DIR="${PROTODEV_TARGET_DIR:-../}"
PROTODEV_NETWORK_ENABLED="${PROTODEV_NETWORK_ENABLED:-false}"
PROTODEV_INCREMENT_VERSION_NUMBER="${PROTODEV_INCREMENT_VERSION_NUMBER:-false}"
PROTODEV_DEBIAN_MIRROR="${PROTODEV_DEBIAN_MIRROR:-http://ftp.de.debian.org/debian}"
PROTODEV_UBUNTU_MIRROR="${PROTODEV_UBUNTU_MIRROR:-http://archive.ubuntu.com/ubuntu}"
PROTODEV_DEBIAN_SECURITY_MIRROR="${PROTODEV_DEBIAN_SECURITY_MIRROR:-http://security.debian.org/}"
PROTODEV_UBUNTU_SECURITY_MIRROR="${PROTODEV_UBUNTU_SECURITY_MIRROR:-http://security.ubuntu.com/ubuntu}"
PROTODEV_GENERATE_BINTRAY_DESCRIPTOR="${PROTODEV_GENERATE_BINTRAY_DESCRIPTOR:-true}"

#### Distribution #############################################################

PROTODEV_BACKPORTS="${PROTODEV_BACKPORTS:-false}"
PROTODEV_EXPERIMENTAL="${PROTODEV_EXPERIMENTAL:-false}"

if [ "${PROTODEV_DISTRIBUTION:-}" = "" ]
then
	Info "Automatically detecting distribution"

	if [ "${TRAVIS_TAG:-}" = "" ]
	then
		PROTODEV_DISTRIBUTION="${TRAVIS_BRANCH:-}"
		PROTODEV_INCREMENT_VERSION_NUMBER="${PROTODEV_INCREMENT_VERSION_NUMBER:-true}"
		case "${PROTODEV_DISTRIBUTION}" in
			debian/*)
				PROTODEV_DISTRIBUTION="${PROTODEV_DISTRIBUTION##debian/}"
				;;
			ubuntu/*)
				PROTODEV_DISTRIBUTION="${PROTODEV_DISTRIBUTION##ubuntu/}"
				;;
		esac
	else
		PROTODEV_DISTRIBUTION="${CHANGELOG_DISTRIBUTION:-}"
	fi

	# Detect backports
	case "${PROTODEV_DISTRIBUTION}" in
		*-backports)
			PROTODEV_BACKPORTS="true"
			PROTODEV_DISTRIBUTION="${PROTODEV_DISTRIBUTION%%-backports}"
			;;
		backports/*)
			PROTODEV_BACKPORTS="true"
			PROTODEV_DISTRIBUTION="${PROTODEV_DISTRIBUTION##backports/}"
			;;
	esac

	# Detect codenames
	case "${PROTODEV_DISTRIBUTION}" in
		oldstable)
			PROTODEV_DISTRIBUTION="wheezy"
			;;
		stable)
			PROTODEV_DISTRIBUTION="jessie"
			;;
		testing)
			PROTODEV_DISTRIBUTION="stretch"
			;;
		unstable|master)
			PROTODEV_DISTRIBUTION="sid"
			;;
		experimental)
			PROTODEV_DISTRIBUTION="sid"
			PROTODEV_EXPERIMENTAL="true"
			;;
	esac
fi

case "${PROTODEV_DISTRIBUTION}" in
	lucid)
		PROTODEV_DOCKER_BOX="${PROTODEV_DOCKER_BOX:-phusion/ubuntu-lucid-32}"
		PROTODEV_MIRROR="${PROTODEV_MIRROR:-http://old-releases.ubuntu.com/ubuntu}"
		PROTODEV_GIT_BUILDPACKAGE="${PROTODEV_GIT_BUILDPACKAGE:-git-buildpackage}"
		PROTODEV_GIT_BUILDPACKAGE_OPTIONS="${PROTODEV_GIT_BUILDPACKAGE_OPTIONS:---git-ignore-new}"
		PROTODEV_EXTRA_COMPONENTS="${PROTODEV_EXTRA_COMPONENTS:-universe}"
		PROTODEV_AUTOPKGTEST_RUN="${PROTODEV_AUTOPKGTEST_RUN:-adt-run}"
		PROTODEV_AUTOPKGTEST_SEPARATOR="${PROTODEV_AUTOPKGTEST_SEPARATOR:----}"
		PROTODEV_UPDATES="${PROTODEV_UPDATES:-true}"
		PROTODEV_SECURITY_UPDATES="${PROTODEV_SECURITY_UPDATES:-false}"
		;;
	precise)
		PROTODEV_DOCKER_BOX="${PROTODEV_DOCKER_BOX:-ubuntu:${PROTODEV_DISTRIBUTION}}"
		PROTODEV_MIRROR="${PROTODEV_MIRROR:-${PROTODEV_UBUNTU_MIRROR}}"
		PROTODEV_EXTRA_COMPONENTS="${PROTODEV_EXTRA_COMPONENTS:-universe}"
		PROTODEV_GIT_BUILDPACKAGE="${PROTODEV_GIT_BUILDPACKAGE:-git-buildpackage}"
		PROTODEV_GIT_BUILDPACKAGE_OPTIONS="${PROTODEV_GIT_BUILDPACKAGE_OPTIONS:---git-ignore-branch}"
		PROTODEV_AUTOPKGTEST_RUN="${PROTODEV_AUTOPKGTEST_RUN:-adt-run}"
		PROTODEV_AUTOPKGTEST_SEPARATOR="${PROTODEV_AUTOPKGTEST_SEPARATOR:----}"
		PROTODEV_UPDATES="${PROTODEV_UPDATES:-true}"
		PROTODEV_SECURITY_UPDATES="${PROTODEV_SECURITY_UPDATES:-true}"
		PROTODEV_SECURITY_MIRROR="${PROTODEV_SECURITY_MIRROR:-${PROTODEV_UBUNTU_SECURITY_MIRROR}}"
		PROTODEV_SECUTIRY_DISTRIBUTION=${PROTODEV_DISTRIBUTION}-security
		;;
	trusty)
		PROTODEV_DOCKER_BOX="${PROTODEV_DOCKER_BOX:-ubuntu:${PROTODEV_DISTRIBUTION}}"
		PROTODEV_MIRROR="${PROTODEV_MIRROR:-${PROTODEV_UBUNTU_MIRROR}}"
		PROTODEV_GIT_BUILDPACKAGE="${PROTODEV_GIT_BUILDPACKAGE:-gbp buildpackage}"
		PROTODEV_GIT_BUILDPACKAGE_OPTIONS="${PROTODEV_GIT_BUILDPACKAGE_OPTIONS:---git-ignore-branch}"
		PROTODEV_EXTRA_COMPONENTS="${PROTODEV_EXTRA_COMPONENTS:-universe}"
		PROTODEV_AUTOPKGTEST_RUN="${PROTODEV_AUTOPKGTEST_RUN:-adt-run}"
		PROTODEV_AUTOPKGTEST_SEPARATOR="${PROTODEV_AUTOPKGTEST_SEPARATOR:----}"
		PROTODEV_UPDATES="${PROTODEV_UPDATES:-true}"
		PROTODEV_SECURITY_UPDATES="${PROTODEV_SECURITY_UPDATES:-true}"
		PROTODEV_SECURITY_MIRROR="${PROTODEV_SECURITY_MIRROR:-${PROTODEV_UBUNTU_SECURITY_MIRROR}}"
		PROTODEV_SECUTIRY_DISTRIBUTION=${PROTODEV_DISTRIBUTION}-security
		;;
	xenial)
		PROTODEV_DOCKER_BOX="${PROTODEV_DOCKER_BOX:-ubuntu:${PROTODEV_DISTRIBUTION}}"
		PROTODEV_MIRROR="${PROTODEV_MIRROR:-${PROTODEV_UBUNTU_MIRROR}}"
		PROTODEV_GIT_BUILDPACKAGE="${PROTODEV_GIT_BUILDPACKAGE:-gbp buildpackage}"
		PROTODEV_GIT_BUILDPACKAGE_OPTIONS="${PROTODEV_GIT_BUILDPACKAGE_OPTIONS:---git-ignore-branch}"
		PROTODEV_EXTRA_COMPONENTS="${PROTODEV_EXTRA_COMPONENTS:-universe}"
		PROTODEV_AUTOPKGTEST_RUN="${PROTODEV_AUTOPKGTEST_RUN:-adt-run}"
		PROTODEV_AUTOPKGTEST_SEPARATOR="${PROTODEV_AUTOPKGTEST_SEPARATOR:----}"
		PROTODEV_UPDATES="${PROTODEV_UPDATES:-true}"
		PROTODEV_SECURITY_UPDATES="${PROTODEV_SECURITY_UPDATES:-true}"
		PROTODEV_SECURITY_MIRROR="${PROTODEV_SECURITY_MIRROR:-${PROTODEV_UBUNTU_SECURITY_MIRROR}}"
		PROTODEV_SECUTIRY_DISTRIBUTION=${PROTODEV_DISTRIBUTION}-security
		;;
	wheezy)
		PROTODEV_DOCKER_BOX="${PROTODEV_DOCKER_BOX:-debian:${PROTODEV_DISTRIBUTION}}"
		PROTODEV_MIRROR="${PROTODEV_MIRROR:-${PROTODEV_DEBIAN_MIRROR}}"
		PROTODEV_GIT_BUILDPACKAGE="${PROTODEV_GIT_BUILDPACKAGE:-git-buildpackage}"
		PROTODEV_GIT_BUILDPACKAGE_OPTIONS="${PROTODEV_GIT_BUILDPACKAGE_OPTIONS:---git-ignore-branch}"
		PROTODEV_AUTOPKGTEST_RUN="${PROTODEV_AUTOPKGTEST_RUN:-adt-run}"
		PROTODEV_AUTOPKGTEST_SEPARATOR="${PROTODEV_AUTOPKGTEST_SEPARATOR:----}"
		PROTODEV_SECURITY_UPDATES="${PROTODEV_SECURITY_UPDATES:-true}"
		PROTODEV_SECURITY_MIRROR="${PROTODEV_SECURITY_MIRROR:-${PROTODEV_DEBIAN_SECURITY_MIRROR}}"
		PROTODEV_SECUTIRY_DISTRIBUTION=${PROTODEV_DISTRIBUTION}/updates
		;;
	jessie)
		PROTODEV_DOCKER_BOX="${PROTODEV_DOCKER_BOX:-debian:${PROTODEV_DISTRIBUTION}}"
		PROTODEV_MIRROR="${PROTODEV_MIRROR:-${PROTODEV_DEBIAN_MIRROR}}"
		PROTODEV_GIT_BUILDPACKAGE="${PROTODEV_GIT_BUILDPACKAGE:-gbp buildpackage}"
		PROTODEV_GIT_BUILDPACKAGE_OPTIONS="${PROTODEV_GIT_BUILDPACKAGE_OPTIONS:---git-ignore-branch}"
		PROTODEV_AUTOPKGTEST_RUN="${PROTODEV_AUTOPKGTEST_RUN:-adt-run}"
		PROTODEV_AUTOPKGTEST_SEPARATOR="${PROTODEV_AUTOPKGTEST_SEPARATOR:----}"
		PROTODEV_SECURITY_UPDATES="${PROTODEV_SECURITY_UPDATES:-true}"
		PROTODEV_SECURITY_MIRROR="${PROTODEV_SECURITY_MIRROR:-${PROTODEV_DEBIAN_SECURITY_MIRROR}}"
		;;
	stretch|sid)
		PROTODEV_DOCKER_BOX="${PROTODEV_DOCKER_BOX:-debian:${PROTODEV_DISTRIBUTION}}"
		PROTODEV_MIRROR="${PROTODEV_MIRROR:-${PROTODEV_DEBIAN_MIRROR}}"
		PROTODEV_GIT_BUILDPACKAGE="${PROTODEV_GIT_BUILDPACKAGE:-gbp buildpackage}"
		PROTODEV_GIT_BUILDPACKAGE_OPTIONS="${PROTODEV_GIT_BUILDPACKAGE_OPTIONS:---git-ignore-branch}"
		PROTODEV_AUTOPKGTEST_RUN="${PROTODEV_AUTOPKGTEST_RUN:-autopkgtest}"
		PROTODEV_AUTOPKGTEST_SEPARATOR="${PROTODEV_AUTOPKGTEST_SEPARATOR:---}"
		PROTODEV_SECURITY_UPDATES="${PROTODEV_SECURITY_UPDATES:-false}"
		PROTODEV_SECURITY_MIRROR="${PROTODEV_SECURITY_MIRROR:-${PROTODEV_DEBIAN_SECURITY_MIRROR}}"
		PROTODEV_SECUTIRY_DISTRIBUTION=${PROTODEV_DISTRIBUTION}-security
		;;
	*)
		Error "Unknown distribution: '${PROTODEV_DISTRIBUTION}'"
		exit 2
		;;
esac

## Detect autopkgtest tests ###################################################

if [ -e "debian/tests/control" ] || grep -E '^(XS-)?Testsuite: autopkgtest' debian/control
then
	PROTODEV_AUTOPKGTEST="${PROTODEV_AUTOPKGTEST:-true}"
else
	PROTODEV_AUTOPKGTEST="${PROTODEV_AUTOPKGTEST:-false}"
fi

## Print configuration ########################################################

Info "Using distribution: ${PROTODEV_DISTRIBUTION}"
Info "Backports enabled: ${PROTODEV_BACKPORTS}"
Info "Experimental enabled: ${PROTODEV_EXPERIMENTAL}"
Info "Security updates enabled: ${PROTODEV_SECURITY_UPDATES}"
Info "Will use extra repository: ${PROTODEV_EXTRA_REPOSITORY:-<not set>}"
Info "Extra repository's key URL: ${PROTODEV_EXTRA_REPOSITORY_GPG_URL:-<not set>}"
Info "Will build under: ${PROTODEV_BUILD_DIR}"
Info "Will store results under: ${PROTODEV_TARGET_DIR}"
Info "Using mirror: ${PROTODEV_MIRROR}"
Info "Network enabled during build: ${PROTODEV_NETWORK_ENABLED}"
Info "Builder command: ${PROTODEV_GIT_BUILDPACKAGE}"
Info "Increment version number: ${PROTODEV_INCREMENT_VERSION_NUMBER}"
Info "Run autopkgtests after build: ${PROTODEV_AUTOPKGTEST}"
Info "DEB_BUILD_OPTIONS: ${DEB_BUILD_OPTIONS:-<not set>}"

## Increment version number ###################################################

if [ "${PROTODEV_INCREMENT_VERSION_NUMBER}" = true ]
then
	cat >debian/changelog.new <<EOF
${SOURCE} (${VERSION}+travis${TRAVIS_BUILD_NUMBER}) UNRELEASED; urgency=medium

  * Automatic build.

 -- protodev <nobody@nobody>  $(date --utc -R)

EOF
	cat <debian/changelog >>debian/changelog.new
	mv debian/changelog.new debian/changelog
	git add debian/changelog
	git commit -m "Incrementing version number."
fi

## Build ######################################################################

cat >Dockerfile <<EOF
FROM ${PROTODEV_DOCKER_BOX} 
RUN echo "deb ${PROTODEV_MIRROR} ${PROTODEV_DISTRIBUTION} main ${PROTODEV_EXTRA_COMPONENTS}" > /etc/apt/sources.list
RUN echo "deb-src ${PROTODEV_MIRROR} ${PROTODEV_DISTRIBUTION} main ${PROTODEV_EXTRA_COMPONENTS}" >> /etc/apt/sources.list
EOF

if [ "${PROTODEV_UPDATES}" = true ]
then
	cat >>Dockerfile <<EOF
RUN echo "deb ${PROTODEV_MIRROR} ${PROTODEV_DISTRIBUTION}-updates main ${PROTODEV_EXTRA_COMPONENTS}" >> /etc/apt/sources.list
RUN echo "deb-src ${PROTODEV_MIRROR} ${PROTODEV_DISTRIBUTION}-updates main ${PROTODEV_EXTRA_COMPONENTS}" >> /etc/apt/sources.list
EOF
fi

if [ "${PROTODEV_BACKPORTS}" = true ]
then
	cat >>Dockerfile <<EOF
RUN echo "deb ${PROTODEV_MIRROR} ${PROTODEV_DISTRIBUTION}-backports main" >> /etc/apt/sources.list
RUN echo "deb-src ${PROTODEV_MIRROR} ${PROTODEV_DISTRIBUTION}-backports main" >> /etc/apt/sources.list
EOF
fi

if [ "${PROTODEV_SECURITY_UPDATES}" = true ]
then
	cat >>Dockerfile <<EOF
RUN echo "deb ${PROTODEV_SECURITY_MIRROR} ${PROTODEV_SECURITY_DISTRIBUTION} main" >> /etc/apt/sources.list
RUN echo "deb-src ${PROTODEV_SECURITY_MIRROR} ${PROTODEV_SECURITY_DISTRIBUTION} main" >> /etc/apt/sources.list
EOF
fi

if [ "${PROTODEV_EXPERIMENTAL}" = true ]
then
	cat >>Dockerfile <<EOF
RUN echo "deb ${PROTODEV_MIRROR} experimental main" >> /etc/apt/sources.list
RUN echo "deb-src ${PROTODEV_MIRROR} experimental main" >> /etc/apt/sources.list
EOF
fi

EXTRA_PACKAGES=""

case "${PROTODEV_EXTRA_REPOSITORY:-}" in
	https:*)
		EXTRA_PACKAGES="${EXTRA_PACKAGES} apt-transport-https"
		;;
esac

if [ "${PROTODEV_EXTRA_REPOSITORY_GPG_URL:-}" != "" ]
then
	EXTRA_PACKAGES="${EXTRA_PACKAGES} wget gnupg"
fi

cat >>Dockerfile <<EOF
RUN apt-get update && apt-get dist-upgrade --yes
RUN apt-get install --yes --no-install-recommends build-essential equivs devscripts git-buildpackage ca-certificates pristine-tar ${EXTRA_PACKAGES}

WORKDIR $(pwd)
COPY . .
EOF

if [ "${PROTODEV_EXTRA_REPOSITORY_GPG_URL:-}" != "" ]
then
	cat >>Dockerfile <<EOF
RUN wget -O- "${PROTODEV_EXTRA_REPOSITORY_GPG_URL}" | apt-key add -
EOF
fi

# We're adding the extra repository only after the essential tools have been
# installed, so that we have apt-transport-https if the repository needs it.
if [ "${PROTODEV_EXTRA_REPOSITORY:-}" != "" ]
then
	cat >>Dockerfile <<EOF
RUN echo "deb ${PROTODEV_EXTRA_REPOSITORY}" >> /etc/apt/sources.list
RUN echo "deb-src ${PROTODEV_EXTRA_REPOSITORY}" >> /etc/apt/sources.list
RUN apt-get update
EOF
fi

if [ "${PROTODEV_BACKPORTS}" = "true" ]
then
        cat >>Dockerfile <<EOF
RUN echo "Package: *" >> /etc/apt/preferences.d/protodev
RUN echo "Pin: release a=${PROTODEV_DISTRIBUTION}-backports" >> /etc/apt/preferences.d/protodev
RUN echo "Pin-Priority: 500" >> /etc/apt/preferences.d/protodev
EOF
fi

cat >>Dockerfile <<EOF
RUN env DEBIAN_FRONTEND=noninteractive mk-build-deps --install --remove --tool 'apt-get --no-install-recommends --yes' debian/control

RUN rm -f Dockerfile
RUN git checkout .travis.yml || true
RUN mkdir -p ${PROTODEV_BUILD_DIR}

RUN git config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
RUN git fetch
RUN for X in \$(git branch -r | grep -v HEAD); do git branch --track \$(echo "\${X}" | sed -e 's@.*/@@g') \${X} || true; done

CMD ${PROTODEV_GIT_BUILDPACKAGE} ${PROTODEV_GIT_BUILDPACKAGE_OPTIONS} --git-export-dir=${PROTODEV_BUILD_DIR} --git-builder='debuild -i -I -uc -us -sa'
EOF

Info "Using Dockerfile:"
sed -e 's@^@  @g' Dockerfile

TAG="protodev/${SOURCE}"

Info "Building Docker image ${TAG}"
docker build --tag=${TAG} .

Info "Removing Dockerfile"
rm -f Dockerfile

CIDFILE="$(mktemp)"
ARGS="--cidfile=${CIDFILE}"
rm -f ${CIDFILE} # Cannot exist

if [ "${PROTODEV_NETWORK_ENABLED}" != "true" ]
then
	ARGS="${ARGS} --net=none"
fi

Info "Running build"
docker run --env=DEB_BUILD_OPTIONS="${DEB_BUILD_OPTIONS:-}" ${ARGS} ${TAG}

pwd

Info "Copying build artefacts to ${PROTODEV_TARGET_DIR}"
mkdir -p "${PROTODEV_TARGET_DIR}"
docker cp "$(cat ${CIDFILE}):${PROTODEV_BUILD_DIR}"/ - \
	| tar xf - -C "${PROTODEV_TARGET_DIR}" --strip-components=1

if [ "${PROTODEV_AUTOPKGTEST}" = "true" ]
then
	docker run --volume "$(readlink -f "${PROTODEV_TARGET_DIR}"):${PROTODEV_BUILD_DIR}" --interactive ${TAG} /bin/sh - <<EOF
set -eu

apt-get install --yes --no-install-recommends autopkgtest autodep8

${PROTODEV_AUTOPKGTEST_RUN} ${PROTODEV_BUILD_DIR}/*.changes ${PROTODEV_AUTOPKGTEST_SEPARATOR} null
EOF
fi

Info "Removing container"
docker rm "$(cat ${CIDFILE})" >/dev/null
rm -f "${CIDFILE}"

Info "Build successful"
sed -e 's@^@  @g' "${PROTODEV_TARGET_DIR}"/*.changes

if [ "${PROTODEV_GENERATE_BINTRAY_DESCRIPTOR}" = "true" ]
then

	SUBJECT="${TRAVIS_REPO_SLUG%/*}"
	RELEASED="$(date +%Y-%m-%d)"

	for DEBIAN_PACKAGE in ../*.deb; do
		DEBIAN_PACKAGE="$(basename $DEBIAN_PACKAGE)"
		DEBIAN_PACKAGE_NO_EXTENSION="${DEBIAN_PACKAGE%.deb}"
		ARCHITECTURE="${DEBIAN_PACKAGE_NO_EXTENSION#*${VERSION}_}"
		FILE_LIST="$FILE_LIST $(cat <<EOF
		{
			"includePattern": "\.\./(${ESCAPED_DEBIAN_PACKAGE//\./\\.})$",
			"uploadPattern": "\$1",
			"matrixParams": {
			"deb_distribution": "${PROTODEV_DISTRIBUTION}",
			"deb_component": "main",
			"deb_architecture": "${ARCHITECTURE}"
		}
	},
EOF
)"
	done
	FILE_LIST="${FILE_LIST%,}"

	cat >> bintray-descriptor.json <<EOF
{
	"package": {
		"name": "${SOURCE}",
		"repo": "${PROTODEV_DISTRIBUTION}",
		"subject": "${SUBJECT}",
		"desc": "",
		"website_url": "https://github.com/${TRAVIS_REPO_SLUG}",
		"issue_tracker_url": "https://github.com/${TRAVIS_REPO_SLUG}/issues",
		"vcs_url": "https://github.com/${TRAVIS_REPO_SLUG}.git",
		"github_use_tag_release_notes": false,
		"github_release_notes_file": "RELEASE.txt",
		"licenses": [],
		"labels": [],
		"public_download_numbers": false,
		"public_stats": false,
		"attributes": []
	},

	"version": {
		"name": "${VERSION}",
		"desc": "",
		"released": "${RELEASED}",
		"vcs_tag": "${TRAVIS_TAG}",
		"attributes": [],
		"gpgSign": false
	},

	"files": [ $FILE_LIST ],
	"publish": true
}
EOF

fi

