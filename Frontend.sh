
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

dnf install nginx -y $>> $log_file
validate $? "installing nginx"

systemctl enable nginx $>> $log_file
validate $? "enabling nginx"

systemctl start nginx $>> $log_file
validate $? "starting nginx"

rm -rf /usr/share/nginx/html/*
VALIDATE $? "Removing default website"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>> $log_file
VALIDATE $? "Downloding frontend code"

cd /usr/share/nginx/html

unzip /tmp/frontend.zip &>> $log_file
validate $? "Extract frontend code"

#CHANGE THE FILE -JAN-SHELL
cp /home/ec2-user/Shell-Script-Expense-Proj/expense.conf /etc/nginx/default.d/expense.conf
validate $? "Copied expense conf"

systemctl restart nginx &>>$log_file
validate $? "Restart Nginx" 
#710 start- 718 till the end of file - 