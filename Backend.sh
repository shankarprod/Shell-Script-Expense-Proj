#!/bin/bash

logs_folder="/var/log/shell-script"
script_name=${0%.*}
timestamp=$(date +%Y-%m-%d-%H-%M-%S)
log_file="$logs_folder/$script_name-$timestamp.log"

mkdir -p $logs_folder

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

userid=$(id -u)
check_root() {
    if [ $userid -ne 0 ]
    then
        echo "not a root user. try with Root privelege" | tee -a $log_file
        exit 1
    fi
}

validate() {
    if [ $1 -ne 0 ]
    then
        echo -e " $2 has $R failed $N" | tee -a $log_file
        exit 1
    else
        echo -e "$2 is $G success $N"  | tee -a $log_file
    fi
}

echo "script started executing at $(date)" | tee -a $log_file
check_root

dnf module disable nodejs -y &>> $log_file
validate $? "disable nodejs"

dnf module enable nodejs:20 -y &>> $log_file
validate $? "enabling nodejs20"

dnf install nodejs -y &>> $log_file
validate $? "installing nodejs" &>> $log_file
# 5 mins till here
#640 start

id expense &>>$log_file
if [ $? -ne 0 ]
then
    echo -e " $R user expense does not exist, $G adding now $N" | tee -a $log_file
    useradd expense &>>$log_file
    validate $? "adding user expense"
else
    echo -e "user expense exists. $Y skipping $N"
fi 

mkdir -p /app $>> $log_file
validate $? "creating app folder" 

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>> $log_file
validate $? "downloading backend application code"

cd /app
rm -rf /app/* #removes existing code/deletes all files

unzip /tmp/backend.zip &>>$log_file
validate $? "Extracting backend application code"

npm install  &>> $log_file
validate $? "installing packages via npm"

#chance the folder name here
cp /home/ec2-user/Shell-Script-Expense-Proj/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>> $log_file
validate $? "installing mysql cli"

mysql -h mysql.shankart.online -uroot -pExpenseApp@1 < /app/schema/backend.sql  &>>$log_file
validate $? "loading schema to mysql server"

systemctl daemon-reload  &>>$log_file
validate $? "reload daemon" 

systemctl enable backend &>>$log_file
validate $? "enable backend service"

systemctl restart backend &>>$log_file
validate $? "restarting backend service"

