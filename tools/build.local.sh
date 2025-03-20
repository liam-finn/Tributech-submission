#!/bin/bash
# Function to check and install required tools
check_and_install_tools() {
    local tools=("docker" "helm" "jq")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            echo "$tool is not installed. Installing..."
            case "$tool" in
                docker)
                    curl -fsSL https://get.docker.com -o get-docker.sh
                    sh get-docker.sh
                    rm get-docker.sh
                    ;;
                helm)
                    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                    ;;
                jq)
                    sudo apt-get update && sudo apt-get install -y jq
                    ;;
            esac
        else
            echo "$tool is already installed."
        fi
    done
}

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
# Function to build and push Docker image
build_and_push_docker_image() {
    local new_version=$1
    local image_name="liamfinn/tributech-frontend:$new_version"
    local dockerfile_path="/mnt/e/git-repos/tributech-ui-oauth-sample/"
    echo "Building Docker image $image_name"
    docker build -t "$image_name" "$dockerfile_path"
    docker push "$image_name"
    echo "Docker image pushed successfully."
}

# Function to package and install the Helm chart
package_and_install_chart() {
    local chart_path=$1
    local new_version=$2
    local update_flag=""
    if [[ "$3" == "--update" ]]; then
        update_flag="-u"
    fi
    helm package "$chart_path" $update_flag --version "$new_version"
    local chart_file=$(ls *-"$new_version".tgz)
    
    if helm ls --namespace tributech --all --short | grep -q "^tributech-assignment$"; then
        helm upgrade tributech-assignment "$chart_file" --namespace tributech --set frontend.image.tag="$new_version"
        echo "Helm chart upgraded successfully."
    else
        helm install tributech-assignment "$chart_file" --namespace tributech --set frontend.image.tag="$new_version"
        echo "Helm chart installed successfully."
    fi
    
    #rm "$chart_file"
}
# Arguments
# $1: Increment type (M, m, p)
# $2: Optional flag to build Docker image
# $3: Optional flag to update Helm chart dependencies

# Main script execution
INCREMENT_TYPE=$(parse_increment_type "$1")
CHART_PATH="../tributech-assignment-chart/"
LATEST_VERSION=$(read_latest_version)
echo "Latest version is $LATEST_VERSION"
NEW_VERSION=$(increment_version "$LATEST_VERSION" "$INCREMENT_TYPE")
echo "New version is $NEW_VERSION"
echo "$NEW_VERSION" > ./new_version.txt

# Check and install required tools
#check_and_install_tools

# Build and push Docker image if the --build flag is provided
if [[ "$2" == "--build" ]]; then
    build_and_push_docker_image "$NEW_VERSION"
else
    NEW_VERSION="0.53.2"
fi

# Package and install Helm chart
package_and_install_chart "$CHART_PATH" "$NEW_VERSION" "$3"