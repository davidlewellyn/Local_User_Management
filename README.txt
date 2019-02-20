README

Author: David Lewellyn

Purpose: This document is to server as a description on how to use the following 
application files:
- account-admin.py
- userAdmin.sh

account-admin.py is a Python driven application with the design in mind to automate
the administration of user accounts. It does this by accessing the internal shadow and
passwd databases contained in a *nix system. These databases are used for the purpose of 
retaining user information. By utilizing the C Structures account-admin.py is able to 
query the information of each account individually.

How to Run:

Since the design was meant to be automatic account-admin.py was designed to have no 
user interactions and only requires the name of the output log file as its only argument.
With this the only application outlined per the requirements of this project, was to have
this application run in the systems crontab. This can be accomplished by performing the
following steps:

After logging into your host, and assuming you are an admin: 

1. Create a folder where to put the log files. Generally /var/log/ is used for that 
   purpose:
   
username@workstation:~$ sudo mkdir /var/log/account_logs/

2. Open CRONTAB

username@workstation:~$ sudo crontab -e

This will open up the crontab which you will have to select an editor:

Select an editor.  To change later, run 'select-editor'.
  1. /bin/nano        <---- easiest
  2. /usr/bin/vim.tiny
  3. /bin/ed

Since it isn't within scope to show how crontab works below is an example of an entry
in crontab setting this script to run every night at 2300.

23 * * * * /root/account-admin.py /var/log/account_logs/user_log_nightly.txt

- The first argument in the crontab entry is the script itself while the second argument
  the file created by the script itself. 
  
What it Does:

During its run operations the account-admin.py will look over the password database and 
the shadow database in order to determine the following:
 - Is this account a USER account:
 	If it is:
 	- Does it have a password set?
 	- Does it have an expiration day set?
 	- Is the account expired?

If any of these three questions are answered the application will lock the account.
The number of discrepancies are annotated by each of those categories in the log file.

--Redacted for Brevity--- 
==========================================================================
                  User Account Report
==========================================================================

Total User Accounts: 6

Account Locked: 2

Accounts without Expiration Dates: 2

Expired Accounts: 0
--Redacted for Brevity---

userAdmin.sh is a BASH driven application that utilizes the *nix build in C applications 
to manage the user accounts. This script provides three main areas of application:
 - Create a new user
 - Modify an existing user
 	- Generate a new password for the user
 	- Set the new expiration dat for the user
 	- Unlock the user account
 	- Delete the user account (locally and recursively)
 - Delete a user account
 
 Due to the nature and potential impact user management has this application is highly 
 driven and the only input accepted is when the user is prompted for it. 
 
 How To Run userAdmin.sh
 
 Assuming that you have admin permissions execute the following:
 
 username@workstation:~$ sudo ./userAdmin.sh <no arguments>
 
 The script will prompt you on the steps that you have chosen, and since data validation
 is key to any application, if there is any attempt to add an account named "root", create
 an account of the same name, or set a home directory to a system folder. You will not be 
 allowed to and the application will kick you out. The option is even in the script to lock
 account and logout the user that attempts this.
 
 
 userAdmin.sh Run Operations
 
 - Add User
 
 	This selection allows you to create a new user without needed to know the exact line.
 	After selecting this option you will be presented with a series of steps that will
 	outlined step by step
 	
 		1. Enter the users FIRST NAME
 		2. Enter the users LAST NAME
 			- These entries are concatenated to for the -c or --comment parameter in 
 			  the useradd command. This will help in account identification
 			  
 		3. Enter the username
 		    - This can be specified by tha admin and is not auto generated. After the
 		      admin hits enter the name is then compared to the rest of the names in
 		      the /etc/password file. If the name matches it will prompt the admin for 
 		      a different user name.
 		      
 		4. Enter the user's home directory
 		   - By default the user's home directory is set to /home/, however this option 
 		   grants the admin to give the user a home directory else where, just so long as
 		   it isn't a system occupied directory such as /root/. If the admin attempts that 
 		   then they will be prompted to enter a different one. If they choose to leave it
 		   blank it will default to /home/. Either way the application will create the
 		   user's home directory.
 		   
 		5. After the final data point is collected the user's information is committed to
 		   to the system. The users directory is set to be owned by the user, and finally
 		   the log file is generated and placed into /tmp for review. This file contains 
 		   the information need for both the user and admin. Most importantly it contains 
 		   a randomly generated password for the user to access their account for the first
 		   time. By default no expiration data is set on the account and the user will have 
 		   to change their password on the first login.
 		   
  - Modify Existing User
  
  	Upon selecting this the admin will be prompted to enter the username of the account
  	which will then be validated against the entries found in the /etc/passwd file. Then
  	the admin will be met with the following choices.
  	
  		1.  Generate a new password
  			- By using the same mechanism used when creating a user, this option
  			  supplied and new randomly generated password to the users account 
  			  utilizing the usermod command. The generate password is then saved to
  			  a log file created in tmp.
  			  
  	    2. Set expiration date
  	    	- Prior to unlocking and account the expiration date must be set. This option
  	    	   will prompt the admin for a YYYY MM DD that will be the new expiration date
  	    	   set for the account. This is achieved by concatenating the input from the 
  	    	   admin and using: chage -E <expire_date> 
  	    	   
  	    3. Unlock Account
  	    	- This option is in place to unlock the users account if they had improperly
  	    	  entered a password of if the account is still locked after the expire date
  	    	  has been changed. After which the account is unlocked using the command: 
  	    	  usermod --unlock <username>
  	    	  
  	    4. Lock Account
  	    	- In the event that an account needs to be locked prior to the time set by the
  	    	  script or if it passed through the account-admin.py parameters without an
  	    	  issue then the admin can lock the account manually through this selection.
  	    	  After selecting this option the user's account will be locked using the 
  	    	  command: usermod --lock <username>
  	
   - Delete User
   
     Upon selecting this the admin will be prompted to enter the username of the account
  	 which will then be validated against the entries found in the /etc/passwd file. Then
  	 the admin will be met with the following choices.
  	 
  	 	1. Delete User account
  	 		
  	 		- This option will simply remove the user's information for the shadow and 
  	 		   passwd databases. The home folders for these users will still be intact.
  	 		   
  	 	2. Delete User Recursively
  	 	
  	 		- This option is will not only remove the user's information form the shadow
  	 		  and passwd databases, but will also delete the user's home directory as
  	 		  well.
  	 		  
Please enjoy using this application, and if you feel there are any improvement that can be 
made please feel free to comment on the repository.