#!/bin/bash
#--------------------------
# Script: userAdmin.sh
# Author: David Lewellyn
#
# Purpose: The purpose of this script is to 
# accomidate the account-admin.py. While the 
# account-admin.py file is meant to run in a cron tab
# this script is designed to be invoked by the admin
# to correct or create user accounts. This script is in 
# BASH because i didn't find a concrete python module to 
# handle *nix user management. I could have used a wrapper
# script but that would have been more trouble than its worth
#
# Deliverabled:
# - Create a User
# - Specify:
#   - username
#   - home directory
#   - full name
#   - Allow user to set password upon login
#   - Account expiration date
#   - Do not allow root to have an expiration set
#
# Testing Criteria will include the ability to create
# a local user. Modify and existing user. Unlock as exitsing 
# users account, and finally attempt to modify root with this application
#------------------------------
# Setting debug mode
#set -x
#------Global Constants-------
SCRIPT="userAdmin.sh"
VERSION=".v1"
AUTHOR="David Lewellyn"

#---Account Creations Vars-----
fname=""
lname=""
user=""
timestamp=$(date +%F)
logdir="/tmp/"
#-----Functions -------

function addUser { 

#Function Requirements as per assignment:
# -Enter First Name
# -Enter Last Name
# -Enter Username
#  *Added validation
# -Enter home directory
#  *Added dir check for existence
#  *Added mkdir to create directory
# -Enter password
#  * Handled by a random generated function
#  * This enforces policy that the admin should
#    not know the users password.

echo -n "Please enter First Name[ENTER]: "
read fname
echo -n "Please enter Last Name[ENTER]: " 
read lname
echo -n "Please enter Username[ENTER]: " 
read user

# Pass the username to the validate function
# to ensure that the user name doesn't 
# already exist
validate $user 
homedefault="/home/$user"
# Checking to besure the right values are in place
# I generally take a unit test approach to my application
# and script development. It may be slower, but debugging 
# is less painfull rather than write the whole script 
# and play find the missing quote

printf "Please enter the home directory.\nExample: /dev/%s\nDefault: %s\n[Enter]: " "$user" "$homedefault"
read homedir

#Using the val-dir funtion to ensure that the home directory
#provided is not a system level directory
val-dir $homedir
#Generate a random password for the user
gen-pass

#printf "\nuseradd -c '%s %s' -d %s -p %s -e %s %s\n" "$fname" "$lname" "$homedir" "$password" "$timestamp" "$user"

useradd -c "$fname $lname" -d $homedir -p $password -e $timestamp $user
printf "\nCommitting User Information\n"
progress-bar 4
#Set ownership to the home dir of the user
chown -R $user:$user $homedir
printf "\n Setting permissions for %s\n" "$homedir"
progress-bar 4
#modify the passwd database
usermod -d $homedir $user &> /dev/null

#Now lets create a log of the events for this
#Grab all the information from the /etc/passwd
printf "\nGenerating log file in: %s\n" "$logdir"
progress-bar 5
entry=$(getent passwd | grep -w $user) 
# Now we slice it up to what we need
printf "Account: %s\n" "$user" >>$logdir$timestamp"_"$user

userdir=$(echo $entry | cut -d: -f6) 
echo "Home Directory: $userdir" >> $logdir$timestamp"_"$user
usershell=$(echo $entry | cut -d: -f7)
echo "Default shell: $usershell" >> $logdir$timestamp"_"$user
username=$(echo $entry | cut -d: -f5) 
echo "$Account Owner: $username">> $logdir$timestamp"_"$user
echo 
chage -l $user >>$logdir$timestamp"_"$user
printf "\nPassword: %s\nThe account is currently locked:\nPending user login\n" "$password" >> $logdir$timestamp"_"$user


}

# The modUser function provides the funtionality needed to provide 
# the user with a new password, account expiration date, unlocking 
# and the locking of accounts

function modUser {

printf "Please enter Username[Enter]: "
read user

checkuid $user

printf "What would like to do?:\n(1)Generate a New Password\n(2)Set Expiration Date\n(3)Unlock\n(4)Lock\n(5)Main\n"
read answer

case $answer in

	1 ) 	echo "Generating a new  password for $user"
		gen-pass
			printf "User Name: %s\nPassword: %s\n" "$user" "password" >> $logdir$timestamp"_"$user
	        usermod -p $password $user
		menu
		;;

	2 )	echo "Set a new expiration date for $user"
		echo "Enter YYYY: "
		read YYYY
		echo "Enter MM: "
		read MM
		echo "Enter DD: "
		read DD
		expdate=$YYYY-$MM-$DD
		chage -E $expdate $user
		menu
		;;

	3)	echo "Unlocking account: $user"
		usermod --unlock $user
		menu
		;;

	4 ) 	echo "$timestamp Locking account: $user" 
		usermod --lock $user >> $logdir$timestamp"_"$user
		menu
		;;

	5 ) 	menu
		;;

	*) 	echo "Invalid selection: No action occured"
esac		
}

function delUser {

echo -n "Please enter Username[ENTER]: " 
read user

checkuid $user

printf "Is this a full(F) user delete or just the (L)local account?\n(F)Removes Home Directories and Mail Tokens\n(L)Local Delete only.\n"
read answer

case $answer in

	L|l) userdel $user  >> $logdir$timestamp"_"$user
	     printf "Local account: %s has been deleted\n" "$user"
	     ;;
	F|f) userdel -r $user >> $logdir$timestamp"_"$user
   	     printf "A recursive delete of %s has occured\n" "$user"
	     ;;
	*) printf "Invalid choice. No acction Occured."
	   
esac

}

# The checkuid function ensures that the
# user exists with in the /etc/passwd file
# if the user doesn't exist it will exit
function checkuid {

	user=$1
	if [ "$user" == "root" ]
	then
		printf "\nFailure: User %s cannot be altered\n" "$user"
  		exit 255
	fi
	# be sure to use the -w with grep for an exact match
	user=$(grep -w $user /etc/passwd | cut -d: -f1)
	if [ -z "$user" ]
	then
		printf "\nUser: %s does not exist. Exiting\n" "$1" 
		menu
	fi
}

function validate {
	user=$1
	if [ "$user" == "root" ]
	then
		printf "\nFailure: Did you seriously try to create a UID named: %s...you deserve this\" "$user"
		#chage -l $(whoami)
		#logout  # This would be just pure evil, but if someone attemted this I would...very quickly
		exit 255
	fi

	check="N"

	while [ "$check" == "N" ]
	do
	usertest=$(grep -w $user /etc/passwd | cut -d: -f1)
		if  [ ! -z "$usertest" ]
		then
			printf "\nUsername: %s already exits. Please try again.\n" "$user"
			echo -n "Username: " 
			read user
		else
		   printf "\nChecking Availability.\n"
		   progress-bar 3
		   printf "\nUsername: %s is valid.\n" "$user"
		   user=$user
		   check="Y"
		fi 
	done
}
# This function is designed to validate a home directory 
# set for the user. If there is a directory specified that 
# exists and either belongs to root or other system functions
# then the function will halt and set to default to 
# prevent any tomfoolery

function val-dir {
	dir=$1
	check="N"
	# If the entry is left blank then assume that the default is set
	if [ -z "$dir" ]
	then
		dir="$homedefault"
	fi

	fsdircheck=$(echo $dir | cut -d/ -f2)
	for i in $(ls /)
        do
	  if [[ "$i" == "$fsdircheck" ]] && [[ "$i" != "home" ]]
	  then
		printf "%s already exists and is a system folder.\n Setting to default\n" "$i"
		homedir="$homedefault"
		return 1
	  fi
	done
	while [ "$check" == "N" ]
	do
		if [[ ! -e $dir ]]
		then
		printf "\nDirectory: %s does not exist.\nWould you like to create it?[Y/N]\n" "$dir"
		read  answer
		case $answer in
			Y|y) mkdir -p  $dir
				if [[  -e $dir ]]
				then
				     printf "\nDirectory %s created\n" "$dir"
				     homedir="$dir"	  
				     check="Y"
				else
				     printf "Directory not created.\n"
				fi
				;;

			N|n) printf "Setting home directory to default\n"
			     homedir="$homedefault"
			     check="Y"
			     ;;

			*)  printf"Please enter a Y or N\n"
			    ;;
		esac
		else
			printf "Directory: %s is a valid location\n" "$dir"
			check="Y"
		fi
	done  
}
gen-pass() {

#This generates a random password  by using SHA to hash the current date.
# Then it runs it through base64 ans the leaves us with the first 10 characters

password=$(date +%s | sha256sum | base64 | head -c 10)

}

# This is not a function I made for this application. It is a chunk of code that I keep on hand
# for interactive shell sessions maintly to slow them down at times and it can be 
# more for UX then anything. Credit for this goes to: https://github.com/edouard-lopez/progress-bar.sh
# I have decent BASH skills but I haven't quite honed them this far 
progress-bar() {
  local duration=${1}


    already_done() { for ((done=0; done<$elapsed; done++)); do printf "▇"; done }
    remaining() { for ((remain=$elapsed; remain<$duration; remain++)); do printf " "; done }
    percentage() { printf "| %s%%" $(( (($elapsed)*100)/($duration)*100/100 )); }
    clean_line() { printf "\r"; }

  for (( elapsed=1; elapsed<=$duration; elapsed++ )); do
      already_done; remaining; percentage
      sleep 1
      clean_line
  done
  clean_line
}


function menu {

printf "Welcome: %s\nPlease select from the following:\n(1) Add User\n(2) Modify Existing User\n(3) Delete User\n(4) Quit\n"  "$admin"  
#----Greeter-----
# I am opening up with a case statement to make the 
# choices very narrow in order to take the play
# out of this particular script
read select

case $select in 

        1 ) addUser;;

        2 ) modUser;;

        3 ) delUser;;

        4 ) echo "Goodbye" ;;

        *) echo "Not a valid option.Please select [1-4]" 
       
esac

}
#----------------------

# Since this method will be interactive I will maintain as strict order
# and flow to the script. I don't want people to be able to skip over a 
# particular step or run in batch. Running in batch has the potential for 
# errors that you may not catch.

admin=$(whoami)

#--- Main ------

if [ $# -ne 0 ]
then 
   printf "Script: %s\nVersion: %s\nAuthor: %s\nUsage: ./userAdmin.sh -No Arguments-\n" "$SCRIPT" "$VERSION" "$AUTHOR"
   exit 255 
fi

menu

