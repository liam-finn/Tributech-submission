#!/bin/bash

# Function to parse the argument for version increment type
parse_increment_type() {
    local increment_type=$1
    if [[ -z "$increment_type" ]]; then
        increment_type="m"
    fi
    if [[ "$increment_type" != "M" && "$increment_type" != "m" && "$increment_type" != "p" ]]; then
        echo "Invalid increment type. Use 'M' for major, 'm' for minor, or 'p' for patch."
        exit 1
    fi
    echo "$increment_type"
}

# Function to read the latest version number from the file
read_latest_version() {
    if [[ ! -s ./new_version.txt ]]; then
        echo "0.1.0"
    else
        cat ./new_version.txt
    fi
}

# Function to increment the version number
increment_version() {
    local version=$1
    local increment_type=$2
    IFS='.' read -r major minor patch <<< "$version"
    case "$increment_type" in
        M)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        m)
            minor=$((minor + 1))
            patch=0
            ;;
        p)
            patch=$((patch + 1))
            ;;
    esac
    echo "$major.$minor.$patch"
}

# Function to package and install the Helm chart
package_and_install_chart() {
    local chart_path=$1
    local new_version=$2
    helm package "$chart_path" -u --version "$new_version"
    local chart_file
    chart_file=$(ls *-"$new_version".tgz)
    helm install tributech-assignment "$chart_file"
    rm "$chart_file"
    echo "Helm chart packaged and installed successfully."
}

# Main script execution
INCREMENT_TYPE=$(parse_increment_type "$1")
CHART_PATH="../tributech-assignment-chart/"
LATEST_VERSION=$(read_latest_version)
echo "Latest version from new_version.txt is $LATEST_VERSION"
NEW_VERSION=$(increment_version "$LATEST_VERSION" "$INCREMENT_TYPE")
echo "New version is $NEW_VERSION"
echo "$NEW_VERSION" > ./new_version.txt
package_and_install_chart "$CHART_PATH" "$NEW_VERSION"