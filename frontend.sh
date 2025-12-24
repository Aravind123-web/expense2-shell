USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.LOG
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

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

dnf install nginx -y &>>$LOGFILE
VALIDATE $? "Installing Nginx web server"

systemctl enable nginx &>>$LOGFILE
VALIDATE $? "Enabling Nginx service"

systemctl start nginx &>>$LOGFILE
VALIDATE $? "Starting Nginx service"

rm -rf /usr/share/nginx/html/* &>>$LOGFILE # Removing default Nginx content
VALIDATE $? "Removing default Nginx content"
# Downloading frontend application code
curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.    
VALIDATE $? "Downloading frontend application code"
# Moving to html directory and unzipping the code
cd /usr/share/nginx/html &>>$LOGFILE
unzip /tmp/frontend.zip &>>$LOGFILE
VALIDATE $? "Unzipping frontend application code"

cp /home/ec2-user/expense2-shell/expense.conf /etc/nginx/default.d/expense.conf &>>$LOGFILE
VALIDATE $? "Copying Nginx config file"

systemctl restart nginx &>>$LOGFILE
VALIDATE $? "Restarting Nginx service"