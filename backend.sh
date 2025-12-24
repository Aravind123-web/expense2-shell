#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.LOG
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
echo "please enter DB server password:"
read -s mysql_root_password

VALIDATE(){

    if [ $1 -ne 0 ]
    then 
      echo -e "$2...$R FAILURE $N"
      exit 1
    else
      echo -e "$2...$G SUCCESS $N"
    fi
}
if [ $USERID -ne 0 ]
then
    echo "Please run this script as root user"
    exit 2
else
    echo "You are root user, you can proceed"
fi

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Disable Nodjs module"
dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabling Nodjs 20 module"
dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Installing Nodjs"

id expense &>>$LOGFILE
if [ $? -ne 0 ]
then
     useradd expense &>>&LOGFILE
     VALIDATE $? "Creating expense user"
else
     echo  -e "Expense user already created...$Y Skipping $n"
fi

#CREATING APPLICATION DIRECTORY

mkdir -p /app &>>$LOGFILE
VALIDATE $? "Creating app directory"

# downloading application code from GIT HUB

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOGFILE
VALIDATE $? "Downloading application/backend code"

cd /app
unzip /tmp/backend.zip &>>$LOGFILE
VALIDATE $? "Unzipping application code/Extract backend code"

#installing nodejs dependencies
npm install &>>$LOGFILE
VALIDATE $? "Installing nodejs dependencies"

cp /home/ec2-user/expense2-shell/backend.service /etc/systemd/system/backend.service &>>$LOGFILE
VALIDATE $? "copied backend service file"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Demon reload"

systemctl start backend &>>$LOGFILE
VALIDATE $? "Starting backend service"

systemctl enable backend &>>$LOGFILE
VALIDATE $? "Enabling backend service"

dnf install mysql -y &>>$LOGFILE
VALIDATE $? "Installing mysql"

#Load the Schema
mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -p${mysql_root_password} < /app/schema/backend.sql &>>$LOGFILE
VALIDATE $? "Loading schema to mysql database"

systemctl restart backend &>>$LOGFILE
VALIDATE $? "Restarting backend service"
