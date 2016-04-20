#!/usr/bin/env bash

set -euo pipefail

BUILDDIR=core-builds

function showUsage () {
  cat <<EOF
Usage: $0 [-h|--help] [<branch>|<commit>|<tag>]
EOF
}

function showHelp () {
  echo ""
  showUsage
  echo ""
  cat <<EOF
Builds core at given <branch>, <commit>, or <tag> under
${BUILDDIR} in the current working directory.

By default, the master branch gets built.
The commit can be the 7-character commit ID.
A tag must begin with tags/ (e.g., tags/v0.97.3).
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    -h | --help )
      showHelp
      exit 0
      ;;
    * )
      break
      ;;
  esac
done

if [ $# -gt 1 ]; then
  showUsage
  exit 1
elif [ $# -eq 0 ]; then
  REF=master
else
  REF=$1
fi

BASEDIR="${BUILDDIR}/${REF}"
mkdir -p "${BASEDIR}"
BASEDIR="$(realpath "${BASEDIR}")"

SRCDIR="${BASEDIR}/src"

function checkout () {

  # Check if given "ref" is a (remote) branch, and prepend origin/ if it is.
  # Otherwise, git-checkout will complain about updating paths and switching
  # branches at the same time.
  if [ `git branch -r | grep "^\\s*origin/${REF}$"` ]; then
    REMOTEREF="origin/${REF}"
  else
    REMOTEREF="${REF}"
  fi

  git checkout "${REMOTEREF}"
}

if [ ! -d "${SRCDIR}" ]; then
  git clone git@github.com:realm/realm-core.git "${SRCDIR}"
  cd "${SRCDIR}"
  checkout
  sh build.sh clean
  sh build.sh config "${BASEDIR}"
else
  cd "${SRCDIR}"
  git fetch
  checkout
fi

sh build.sh build
sh build.sh install
