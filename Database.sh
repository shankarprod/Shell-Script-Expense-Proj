#!/bin/bash


logs_folder="/var/log/shell-script"
script_name=${0%.*}
timestamp=$(date +%Y-%m-%d-%H-%M-%S)
log_file="$logs_folder/$script_name-$timestamp.log"

mkdir -p $logs_folder

$R="\e[31m"
$G="\e[32m"
$Y="\e[33m"
$N="\e[0m"

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

dnf install mysql-server -y &>> $log_file
validate $? "installing mysql server"

systemctl enable mysqld &>> $log_file
validate $? "enable mysqld"

systemctl start mysqld &>> $log_file
validate $? "starting mysqld"

mysql -h mysql.shankart.online -u root -pExpenseApp@1 -e "show databases;" &>> $log_file
if [ $? -ne 0 ]
then
    echo "Mysql root password is not setup. setting up now" | tee -a $log_file
    mysql_secure_installation --set-root-pass ExpenseApp@1
    validate $? "settingup root password"
else
    echo -e "MySQL root password is already setup...$Y SKIPPING $N" | tee -a $log_file
fi

