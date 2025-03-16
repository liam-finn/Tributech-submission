#!/bin/bash

# Define the path to the Helm chart
CHART_PATH="../tributech-assignment-chart/"

# Read the latest version number from the Chart.yaml file
LATEST_VERSION=$(cat ./new_version.txt)
echo "Latest version from new_version.txt is $LATEST_VERSION"

# Increment the minor version number
IFS='.' read -r major minor patch <<< "$LATEST_VERSION"
minor=$((minor + 1))
NEW_VERSION="$major.$minor.0"
echo "New version is $NEW_VERSION"
# Write the new version to a file
echo "$NEW_VERSION" > ./new_version.txt

# Package the Helm chart
helm package $CHART_PATH -u

# Find the packaged chart file with the new version number
CHART_FILE=$(ls *-$NEW_VERSION.tgz)

# Install the Helm chart
helm install tributech-assignment $CHART_FILE

# Clean up the packaged chart file
rm $CHART_FILE

echo "Helm chart packaged and installed successfully."