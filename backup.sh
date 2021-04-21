#!/bin/bash
backup_file=/home/karthi/python_scripts 
backup_directory=/home/karthi/Desktop
d=`date`
cp -r --backup $backup_file $backup_directory
echo "took backup of scripting file on $d"

zip $date.zip $backup_file
