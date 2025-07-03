#!/bin/bash

LOCAL_VERSION=""
REPO_VERSION=""
LOCAL_FORMATTED_VERSION=""
REPO_FORMATTED_VERSION=""
REPO_APPIMAGE_URL="https://github.com/liriliri/aya/releases/download/v%version%/AYA-%version%-linux-x86_64.AppImage"


# format version AA.B.C.DDD-E to AABBCCDDDDEE
getformattedversion() {
    version=$1
    IFS='.-' read -r -a parts <<< "$version"
    formatted_version=$(printf "%02d%02d%02d%04d%02d" "${parts[0]}" "${parts[1]}" "${parts[2]}" "${parts[3]}" "${parts[4]}")
    echo "$formatted_version"
}

# get formatted version from PKGBUILD
getlocalversion() {
    version=$(cat .SRCINFO | grep 'pkgver = ' | cut -d '=' -f 2 | sed "s/_/-/" | sed "s/ //")
    echo "$version"
}

# get formatted version from repo
getrepoversion() {
    html=$(curl -ks "https://api.github.com/repos/liriliri/aya/releases/latest")
    version=$(echo $html | sed -E 's/.*"tag_name": "v([^"]+)".*/\1/')
    echo "$version"
}

updatelocalrepo() {
    pkgversion=$(echo "$REPO_VERSION" | sed "s/-/_/")
    sed -i "s/$LOCAL_VERSION/$REPO_VERSION/g" PKGBUILD
    sed -i "s/^_pkgver=.*/_pkgver=$REPO_VERSION/" PKGBUILD
    sed -i "s/^pkgver=.*/pkgver=$pkgversion/" PKGBUILD
    sed -i "s/^sha256sums=.*/sha256sums=\(\""$sha256"\"\)/" PKGBUILD
    sed -i "s/$LOCAL_VERSION/$REPO_VERSION/g" .SRCINFO
    sed -i "s/pkgver = .*/pkgver = $pkgversion/" .SRCINFO
    sed -i "s/sha256sums = .*/sha256sums = "$sha256"/" .SRCINFO
}

LOCAL_VERSION=$(getlocalversion)
REPO_VERSION=$(getrepoversion)
LOCAL_FORMATTED_VERSION=$(getformattedversion $LOCAL_VERSION)
REPO_FORMATTED_VERSION=$(getformattedversion $REPO_VERSION)
REPO_APPIMAGE_URL=$(echo $REPO_APPIMAGE_URL | sed "s/\%version\%/$REPO_VERSION/g")
echo "Local version: $LOCAL_VERSION"
echo "Repo version: $REPO_VERSION"
echo "Local formatted version: $LOCAL_FORMATTED_VERSION"
echo "Repo formatted version: $REPO_FORMATTED_VERSION"
echo "Repo AppImage url: $REPO_APPIMAGE_URL"

if [[ $LOCAL_FORMATTED_VERSION != $REPO_FORMATTED_VERSION ]]; then
    echo "New version detected. Updating local repo ..."
    updatelocalrepo
    echo "REPO_VERSION=$REPO_VERSION" >> "$GITHUB_OUTPUT"
else
    echo "No new version detected."
fi
