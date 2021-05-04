#!/bin/bash

pscount=`docker ps | wc -l`

if [[ $pscount -eq 1 ]]
then
  echo "Starting all containers"
else
  echo "all containers up. Exiting"
  exit 0
fi


#my_array=(documends-website_web_1  documends_web-api_1   documends_adminer_1  documends_db_1)

your_array=(focused_nightingale modest_colden beautiful_engelbart)

for i in "${your_array[@]}";
do
CON=`docker ps -af "name =$i" | awk 'NR==2, NR==10' | cut -d " " -f 1`

docker start $CON;
echo "$i"

done


