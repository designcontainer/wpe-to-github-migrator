#!/bin/bash -e

scriptpath="$(dirname $0)"

set -a # automatically export all variables
source $scriptpath/.env
set +a

migrateSites() {
    arr=("$@")
    for install in "${arr[@]}";
    do
        echo "Migrating: $install ..."
        
        # site vars
        repo="designcontainer/$install"
        topic="sites"
        
        cd $ENV_FOLDER_PATH
        
        # Clone from WPE
        git clone git@git.wpengine.com:production/$install.git
        cd $install
        git remote rename origin wpengine
        
        # install fresh wp core
        curl -O https://wordpress.org/latest.tar.gz
        tar -zxvf latest.tar.gz
        cd wordpress
        rm -rf wp-content
        cp -rf . ..
        cd ..
        rm -R wordpress
        
        mkdir wp-content/uploads
        chmod 777 wp-content/uploads
        rm latest.tar.gz
        
        # Remove plugins folder and get them from ssh instead, cause vendor files are not in git sometimes
        cd wp-content
        rm -rf plugins
        rsync -e "ssh" -r $install@$install.ssh.wpengine.net:/sites/$install/wp-content/plugins $PWD
        cd ..
        
        # Create a workflow file
        mkdir .github
        cd .github
        mkdir workflows
        cd workflows
        
        echo "name: Deploy to WP Engine"                                         > main.yml
        echo ""                                                                 >> main.yml
        echo "on:"                                                              >> main.yml
        echo "  push:"                                                          >> main.yml
        echo "    branches:"                                                    >> main.yml
        echo "      - master"                                                   >> main.yml
        echo ""                                                                 >> main.yml
        echo "jobs:"                                                            >> main.yml
        echo "  build:"                                                         >> main.yml
        echo ""                                                                 >> main.yml
        echo "    runs-on: ubuntu-latest"                                       >> main.yml
        echo ""                                                                 >> main.yml
        echo "    steps:"                                                       >> main.yml
        echo "    - uses: actions/checkout@v2"                                  >> main.yml
        echo "    - name: GitHub Deploy to WP Engine"                           >> main.yml
        echo "      uses: wpengine/github-action-wpe-site-deploy@main"          >> main.yml
        echo "      env: "                                                      >> main.yml
        echo "        WPE_ENV_NAME: $install"                                   >> main.yml
        echo '        WPE_SSHG_KEY_PUBLIC: ${{ secrets.WPE_PUBLIC_KEY_NAME }}'  >> main.yml
        echo '        WPE_SSHG_KEY_PRIVATE: ${{ secrets.WPE_PRIVATE_KEY_NAME }}'>> main.yml
        
        cd ../..
        
        # Add readme.md if it doesn't exist
        if [ ! -f README.md ]; then
            echo "# $install"                                                                                        > README.md
            echo "Short summary of the main functionality and purpose of the project."                              >> README.md
            echo "## Domains"                                                                                       >> README.md
            echo "#### CNAME"                                                                                       >> README.md
            echo "[$install.wpengine.com](https://$install.wpengine.com)"                                           >> README.md
            echo "#### WP Engine Admin"                                                                             >> README.md
            echo "https://my.wpengine.com/installs/$install"                                                        >> README.md
            echo "## How to build"                                                                                  >> README.md
            echo "## Deployment"                                                                                    >> README.md
        fi
        
        # Create a new GH repo for the site
        gh repo create $repo -y --private --description "Site repo for $install."
        
        # Get the env type
        env_type=$( jq '.results[]  | select(.name == "dc2017") | .environment' $ENV_FOLDER_PATH/sites.json )
        
        # Add topics
        curl \
        --request PUT \
        --user $ENV_GH_USER:$ENV_GH_TOKEN \
        --header "Accept: application/vnd.github.mercy-preview+json" \
        "https://api.github.com/repos/designcontainer/$install/topics" \
        --data '{"names":["site", "wpengine", '"$env_type"']}'
        
        # Set SSH secrets
        #   Edit: It turns out you can have global secrets.
        # gh secret set WPE_PUBLIC_KEY_NAME --body "$pub" --repo $repo
        # gh secret set WPE_PRIVATE_KEY_NAME --body "$priv" --repo $repo
        
        # Push to github
        git add --all
        git commit -m "Initial Github Commit"
        git push origin master
        
        cd $ENV_FOLDER_PATH
        rm -rf $install
        
    done
    
}

all_sites=$(curl -X GET "https://api.wpengineapi.com/v1/installs?limit=200" -u $ENV_WPE_USER:$ENV_WPE_TOKEN)
echo $all_sites > $ENV_FOLDER_PATH/sites.json;

IFS=', ' read -r -a installs <<< $ENV_SITE_LIST
migrateSites "${installs[@]}"

rm $ENV_FOLDER_PATH/sites.json

echo 'Done!'

# Written by Rostislav Melkumyan 2021