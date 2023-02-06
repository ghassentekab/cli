#!/bin/bash

backup_folder_path=~/db_backups


file_name="dump-"`date "+%Y-%m-%d"`".dump"

read -p 'Database_Container_Name: ' Database_Container_Name
read -p 'Database_Name: ' Database_Name
read -sp 'Database_Password:' Database_Password
echo
read -p 'Database_User_Name: ' Database_User_Name

# ensure the location exists
mkdir -p ${backup_folder_path}


#change database name, username and docker container name
dbname=postgres
username=postgres
container=supabase-db


backup_file=${THEIA_WORKSPACE_ROOT}/${GITPOD_WORKSPACE_ID}/DATABASE_BACKUP/${file_name}
dump_path=./${file_name}

docker exec -it -e PGPASSWORD=${Database_Password} -e Database_User_Name=${Database_User_Name} -e Database_Name=${Database_Name} -e dump_path=${dump_path} -e file_name=${file_name} ${Database_Container_Name} sh -c "pg_dump -Fc -U ${Database_User_Name} -h localhost -d ${Database_Name} > ${dump_path}"
docker cp ${Database_Container_Name}:${dump_path} ${backup_file}
docker exec -ti ${Database_Container_Name} sh -c "rm -rf ${dump_path}"
echo "Dump successful , you can check your goole drive"

