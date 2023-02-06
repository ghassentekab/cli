#!/bin/bash

echo choose a dump file from your google drive

rclone ls google_drive:${THEIA_WORKSPACE_ROOT}/DATABASE_BACKUP 

read -p 'your dumpfile: ' dump_file 

read -p 'Database_Container_Name: ' Database_Container_Name
read -p 'Database_Name: ' Database_Name
read -sp 'Database_Password: ' Database_Password
echo
read -p 'Database_User_Name: ' Database_User_Name



docker cp ${THEIA_WORKSPACE_ROOT}/${GITPOD_WORKSPACE_ID}/DATABASE_BACKUP/${dump_file} ${Database_Container_Name}:/ 

docker exec -ti -e PGPASSWORD=${Database_Password} -e Database_Name=${Database_Name} -e Database_User_Name=${Database_User_Name} -e dump_file=${dump_file} ${Database_Container_Name} sh -c "pg_restore -d ${Database_Name} -U ${Database_User_Name} -h localhost --clean ${dump_file}"

echo "database restored successfully"

# pg_restore -d postgres -U postgres -h localhost --clean dump-2022-05-23.dump 
# your-super-secret-and-long-postgres-password