#!/usr/bin/env bash

### Colors ##
ESC=$(printf '\033') RESET="${ESC}[0m" BLACK="${ESC}[30m" RED="${ESC}[31m"
GREEN="${ESC}[32m" YELLOW="${ESC}[33m" BLUE="${ESC}[34m" MAGENTA="${ESC}[35m"
CYAN="${ESC}[36m" WHITE="${ESC}[37m" DEFAULT="${ESC}[39m"

### Color Functions ##

greenprint() { printf "${GREEN}%s${RESET}\n" "$1"; }
blueprint() { printf "${BLUE}%s${RESET}\n" "$1"; }
redprint() { printf "${RED}%s${RESET}\n" "$1"; }
yellowprint() { printf "${YELLOW}%s${RESET}\n" "$1"; }
magentaprint() { printf "${MAGENTA}%s${RESET}\n" "$1"; }
cyanprint() { printf "${CYAN}%s${RESET}\n" "$1"; }

fn_bye() { echo "$(magentaprint 'Tekab-dev Modules Generator: EXIT')"; exit 0; }
fn_fail() { echo "$(redprint 'Wrong option.')"; }

generate_module(){
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod 777 /usr/local/bin/yq
git clone --single-branch --branch $1 https://gitlab.com/tekab-dev-team/testing/cli-testing.git $1
updatable=( "app.module.json" "docker-compose.yml" "package.json" ".env" "grants.json" "schema.prisma" )
ignore=("/.git/")
cd $1
files=$(find . -type f -print)
for file in $files; do
    file_name="${file##*/}"
    if [[ "$file" != *"/.git/"* ]]; then
        if [[ " ${updatable[*]} " == *" $file_name "* ]]; then
            if [[ $file_name == "package.json" ]]; then
                path="client-ui"
                if [[ "$file" == *"/server/"* ]]; then
                    path="server"
                fi
                jq -s '.[0] * .[1]' $path/package.json ../$path/package.json > ../$path/package.tmp.json
                mv ../$path/package.tmp.json ../$path/package.json
            fi
            if [[ $file_name == "docker-compose.yml" ]]; then
                yq eval-all '. as $item ireduce ({}; . *+ $item )' ../docker-compose.yml docker-compose.yml  > merged.yml
                mv  merged.yml ../docker-compose.yml
            fi
            if [[ $file_name == "app.module.json" ]]; then
                imports=$(jq '.imports' $file)
                jq -r '.import[]' $file | cat - ../server/src/app.module.ts > temp.txt && mv temp.txt ../server/src/app.module.ts
                for module in $(echo $imports | jq -r '.[]'); do
                    sed -i -e "0,/imports: \[/s//imports: \[ \n\t$module,/" ../server/src/app.module.ts
                done
            fi
            if [[ $file_name == ".env" ]]; then
                touch env.tmp
                while read line; do
                    if [[ $line == *"="* ]]; then
                        key=${line%%=*}
                        if grep -q $key $file; then
                            extracted_line=$(grep -m 1 $key $file)
                            echo $extracted_line >> env.tmp
                            sed -i "/${key}/d" $file
                        else
                            echo $line >> env.tmp
                        fi
                    else
                        echo $line >> env.tmp
                    fi
                done < ../$file
                mv env.tmp ../$file
                cat $file >> ../$file
                grep -v '^[ \t]*$'  ../$file | sed -e '$!N;/#.*#/D' -e 'P;D' | sed '${/#/d;}' >> env.tmp
                mv env.tmp ../$file
            fi
            if [[ $file_name == "grants.json" ]]; then
                jq -s add server/src/grants.json ../server/src/grants.json > ../server/src/grants.tmp.json
                mv ../server/src/grants.tmp.json ../server/src/grants.json
            fi
            if [[ $file_name == "schema.prisma" ]]; then
                sed -i "/^model User {/e cat server/prisma/schema.prisma" ../server/prisma/schema.prisma
            fi
        else
            cp --parents ${file} ../
        fi
    fi
done
cd ..
rm -rf $1
API_URL=$(grep "API_URL" .env | cut -d '=' -f2)
sudo rm -rf server/node_modules
sudo rm -rf client-ui/node_modules
api_url=$API_URL ./generate-open-api.sh
sudo docker-compose cp vue-app-dev:/app/node_modules ./client-ui/
sudo docker-compose cp server-dev:/app/node_modules ./server/

}

submenu() {
echo -ne "
$(greenprint '1) return to main menu')
$(redprint '0) Exit') 
Choose an option:"
    read -r ans
    case $ans in
    1)
        generate_module "shareSocialMedia"
        ;;
    0)
        fn_bye
        ;;
    *)
        fn_fail
        submenu
        ;;
    esac
}
mainmenu() {
echo -ne "
$(cyanprint '\{^_^}/ Tekab-dev Modules generator.')

$(magentaprint 'MAIN MENU')
$(greenprint '1) Social Media Sharer')
$(greenprint '2) E-mail')
$(greenprint '3) E-mail with invitation')
$(greenprint '4) Server Upload')
$(greenprint '5) ImageKit')
$(greenprint '6) merge-yaml-wip')
$(redprint '0) Exit') 
Choose an option:  "
    read -r ans
    case $ans in
    1)
        generate_module "shareSocialMedia"
        ;;
    2)
        generate_module "E-email"
        ;;
    3)
        generate_module "email-with-invitation"
        ;;
    4)
        generate_module "server-upload"
        ;;
    5)
        generate_module "imageKit"
        ;;
    6)
        generate_module "merge-yaml-wip"
        ;;
    0)
        fn_bye
        ;;
    *)
        fn_fail
        submenu
        ;;
    esac
}

mainmenu