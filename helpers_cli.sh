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

## function that take module name as arg ($1: module name)
generate_module(){
#sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
#sudo chmod 777 /usr/local/bin/yq

#git clone --single-branch --branch $1 https://gitlab.com/tekab-dev-team/testing/cli-testing.git $1
curl -s --request GET --header PRIVATE-TOKEN:glpat-SMWi7Y9TmbE1S6wBwnpi https://gitlab.com/api/v4/projects/43331160/repository/archive/ | tar -xz --wildcards */$1 --strip-components=1&
PID=$!
wait $PID
echo "done"
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

get_modules_names () {
res=$(curl -s --header "PRIVATE-TOKEN: glpat-SMWi7Y9TmbE1S6wBwnpi" "https://gitlab.com/api/v4/projects/43331160/repository/tree")
while read i; do
    type=$(jq '.type'<<< $i)
    path=$(jq '.path'<<< $i)
    if [[ "$type" == *"tree"* ]] && [[ "$path" != *"."* ]]; then
        modules_names+=("$path")
    fi
done < <(jq -c '.[]' <<< $res)
}

submenu() {
echo -ne "
$(greenprint '1) return to main menu')
$(redprint '0) Exit') 

Choose an option:"
    read -r ans
    case $ans in
    1)
        mainmenu
        ;;
    *)
        fn_bye
        ;;
    esac
}

mainmenu() {
echo -e "\nChoose a helper module to add"
for index in "${!modules_names[@]}";
do
    echo $(greenprint "$((index+1))) ${modules_names[$index]//\"/}")
done
echo -ne "$(redprint '0) Exit') 

Choose an option:  "
    read -r ans
    if [ $ans == 0 ]; then
        fn_bye
    elif  [ $ans -le ${#modules_names[@]} ]; then
        generate_module ${modules_names[$ans-1]}
    else
        fn_fail
        submenu
    fi
}

modules_names=()
echo -e "\n$(cyanprint '\{^_^}/ Tekab-dev Modules Generator.\n')"
get_modules_names
mainmenu


