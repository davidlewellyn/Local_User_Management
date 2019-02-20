# user-nuggets
Contents of this repo
- README.txt: This is a set of user intructions on how to use the application.
- account-admin.py: A Python driven application that will identify local accounts.
- user-admin.sh: A BASH driven script that will allow the user to Add,Modify, and Delete local accounts with needed to know
  all the commands needed to do so.
- Process_Test.txt: This file outlines the testing procedures for this application.
- Test_Results.txt: This file contains the results of the tests conducted.
  
 # Purpose
 This application was driven by the academic requirements for a class assignment. Maintaining a source of version controll allows me the ability to roll back to a previous working state, and to also improve upon this work at a later time if needed.
 
 # Requirments 
Create a script that can be run from the crontab or the command line that helps you administer accounts. The
script should allow accounts to be created, modified and account status to be reported. The script should be able
to do the following:
- Report all the users that don’t have a password.
- If an account does not have a password, the program will automatically lock the account and
  report that the account has been locked.
- Report all expired accounts.
- Report the expiration date/time for all accounts.
- Report all accounts that do not expire.
- Unlock or Lock user accounts specified on the command line.
- Add a user account to the system (interactive only – not run from the crontab).
- Specify the username, home directory, user’s full name, password, and expiration date.

- You should be able to specify the usernames to be created on the command line or from a
  file specified on the command line. The script should either query for the detailed
  information or read it from the file.
- When adding an account, the user should have to reset their password upon first login into the
  system.
- Change the expiration date for users specified on the command line.
- Do not allow the root account to have an expiration date.
- The script should be able to write the results to a log file specified on the command line.
