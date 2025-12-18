#!/bin/bash

set -e

# Help function
show_help() {
    echo "Usage: $0 <version|patch|minor|major>"
    echo "Example: $0 v1.0.0"
    echo "         $0 patch"
    exit 1
}

if [ -z "$1" ]; then
    show_help
fi

TYPE_OR_VERSION=$1

# Ensure we are on main and clean
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "Error: Releases must be made from the 'main' branch."
    exit 1
fi

if [[ -n $(git status --porcelain | grep -v "pyproject.toml") ]]; then
    echo "Error: Working directory is not clean. Commit or stash changes first."
    exit 1
fi

# Determine if we are incrementing or setting an explicit version
if [[ "$TYPE_OR_VERSION" =~ ^(patch|minor|major)$ ]]; then
    echo "Incrementing version ($TYPE_OR_VERSION)..."
    poetry version "$TYPE_OR_VERSION"
    NEW_VERSION="v$(poetry version -s)"
else
    # Treat as explicit version
    if [[ ! "$TYPE_OR_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Version must be patch/minor/major or follow v1.2.3 format."
        exit 1
    fi
    NEW_VERSION=$TYPE_OR_VERSION
    poetry version "${NEW_VERSION#v}"
fi

echo "New version: $NEW_VERSION"

# Commit the version change in pyproject.toml
git add pyproject.toml
git commit -m "chore: bump version to $NEW_VERSION" || echo "Version already updated in pyproject.toml"

# Push the commit to main
echo "Pushing changes to main..."
git push origin main

# Create GitHub Release (this also creates the tag)
echo "Creating GitHub Release $NEW_VERSION..."
gh release create "$NEW_VERSION" \
    --title "Release $NEW_VERSION" \
    --generate-notes

echo "GitHub Release $NEW_VERSION created and pushed."

# Trigger the build and push to internal registry
echo "Starting internal registry push..."
./local/build.sh "$NEW_VERSION"

echo "Release $NEW_VERSION completed successfully."
