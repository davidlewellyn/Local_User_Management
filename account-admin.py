#!/usr/bin/python
#-------------------------
# Script: account-admin.py
# Author: David Lewellyn
#
# Purpose: This script is designed to administer the 
# first stage of a user management system. The goal in mind for  
# this script will be to be implemented using crontab and will execute
# the following action:
# - Report All users that don't have passwords
# - Report expired accounts
# - Report the expiration date/time for all accounts
# - Report all accounts that do not expire
# The testing criteria for this was used by creating local user
# accounts that met met all or certain testing parameters to reduce
# the chance of a false positive.
# since this script is designed to run in a cron task it will report
# and automatically lock expired account or accounts without passwords
#------------------------------


#--Import Tools Needed--
import spwd #Used to access the spwd struc
import pwd #Used for access to the pdw struct
import os #This will be used for executing shell commands
import sys #This will be for opening and wrting to a file
import operator as op #This will be used for sorting my lists
import time as t #Used for time calculations
import datetime as dt #Used for date formatting

# Python provided modules for reading info from 
# both /etc/password and /etc/shadow. The internal
# *nix C structures have methods of accessing points of 
# data in those files that once you skim ove rthe documentation
# it make it much easier. I decided to try my hand in python 
# simply to change up my skills.

#--- Functions ---------

# The calcTime function will accept the value of the 
# spwd.sp_expire for the user and calculate the amount of days
# untile the account is expired. If the account is expired then
# the function will lock the account.
def calcTime(time):
    #Convert the seconds from Epoch to days for today
    today = int(t.time())
    exptime = time * 3600 * 24
    timedelta = exptime - today
    expiredate = today + timedelta
    #Now for fun lets convert it to Time and Day
    #date = dt.datetime.fromtimestamp(int(expiredate)).strftime('%Y-%m-%d %H:%M:%S')
    # Now lets add some logic so that we are reporting useful messages
    # By default if an expiration data it not set it will report a -1
    # In the shadow password file.
    if time == -1:
	date = "Date not Set"
    # It a date has been set then the Epoch time for that data will be in /etc/shadow
    elif time > -1 and timedelta < 0:
	#  If  the time has been set but our timedelta is in the negatives
        # that means the account has expired
	date = "Expired"
    #If all is well and the timedelts is in the positive range then we get the data we
    # Need by adding the delta to the epoch of today
    else:
        date = dt.datetime.fromtimestamp(int(expiredate)).strftime('%Y-%m-%d %H:%M:%S') 
    return  date
# The lockAccount function is triggered when events such as the account being expired 
# will cause the account to lock, if the account has no password set. Accounts without 
# expiration dates will be exempt from this role
def lockAccount(user):
    #Set the system commands to execute some shell. I chose to dump the stdout into /dev/null
    #Because it messed with the astetics of the script
    lockuser = "passwd -l %s >/dev/null 2>&1 " % (user)
    #Set the expiration to -1 to remove errors that occured after locking
    resetdate = "chage -E -1 %s >/dev/null 2>&1" % (user)
    os.system(lockuser)
    os.system(resetdate)
    status = "Locked"
    return status

#--- End Functions------

#--- Global Variables ---
# Here I am duping the contents of each file into a variable 
# that can be indexed. Not that is is needed since each struc
# provides a call to a particular value
#------------------------
all_user_data = pwd.getpwall()
all_user_pass = spwd.getspall()
# Since by defaul the UID of a user account is between 1000 and 
# 59999. I will set them up as static variables
FIRST_UID = 1000
LAST_UID = 59999
TODAY = dt.datetime.fromtimestamp(int(t.time())).strftime('%Y-%m-%d %H:%M:%S')
LOGFILE = sys.argv[1]

#---Open the logfile------

sys.stdout = open(LOGFILE,"w+")

 
# Using the operator module I was able the sort out the 
# UID of the users. This was after I determined which accounts 
# where user accounts. 
users = sorted((u for u in all_user_data 
                  if  u.pw_uid >= FIRST_UID and u.pw_uid <= LAST_UID),
                  key=op.attrgetter('pw_uid'))

# Since one of the requirements is for a report on all account
# a separate list of sorted sorted system account

systm = sorted((u for u in all_user_data
                  if u.pw_uid < FIRST_UID or u.pw_uid > LAST_UID),
                  key=op.attrgetter('pw_uid'))

# Find the longest lengths for a few fields and a few defined as well
ulength = max(len(u.pw_name) for u in users) + 1
slength = max(len(s.pw_name) for s in systm) + 1 
uilen =  6
hlength = max(len(u.pw_dir) for u in users) + 1
dlength = max(len(s.pw_dir) for s in systm) + 1
statlen = 10

#Create some setting for the header field
header = 74
center = header/2
hfmt = '%*s'
print '=' * header
print hfmt % (center,'User Accounts')
print '=' * header

#------User Account Report------------

# Print format for the local user accounts
fmt = '%-*s %-*s %-*s %-*s %s'
print fmt % (ulength, 'User', uilen, 'UID', hlength, 'Home Dir', statlen ,'Status', 'Expiration')
print '-' * ulength, '-' * uilen, '-' * hlength, '-' * statlen, '-' * 20

# Print the data for local user accounts
# by using a for-loop to loop ovee thw users 
# file this will make it easier to grab the information
# needed by querying each instance of the C struct

# To sort our the data here I will be using some counters 
# and lists
usercount = 0
userexpirecount = 0
usernoexpirecount = 0
userlockscount = 0 
# These lists will be used for reporting 
userlocksList = []
usernoexpireList = []
userexpireList = []  
for u in users:
    acct = spwd.getspnam(u.pw_name)
    expire = calcTime(acct.sp_expire)
    status = " "
    #This logic is to determine how to handle the account
    # No expirations date: The account and logged and locked
    if expire == "Date not Set":
	usernoexpireList.insert(usernoexpirecount, u.pw_name)
        usernoexpirecount += 1
        status = lockAccount(u.pw_name)
        userlocksList.insert(userlockscount, u.pw_name)
        userlockscount += 1
    #If the account is expired. The account is locked
    if expire == "Expired":
	userexpireList.insert(userexpirecount, u.pw_name)
        userexpirecount += 1
	status = lockAccount(u.pw_name)
	userlocksList.insert(userlockscount, u.pw_name)
        userlockscount += 1
    if acct.sp_pwd == "!":
        userlocksList.insert(userlockscount, u.pw_name)
        status = "Locked by Admin"
        userlockscount += 1
    usercount += 1
    print fmt % (ulength, u.pw_name, uilen , u.pw_uid, hlength, u.pw_dir, statlen,  status, expire)

print '=' * header
print hfmt % (center,'User Account Report')
print '=' * header

print("\nTotal User Accounts: %i" % (usercount))

# Now Loop over the lists to unroll them 
# This should match the number reported
print("\nAccount Locked: %i" % (userlockscount))
i = 0
while i < len(userlocksList):
    print userlocksList[i]
    i += 1
print("\nAccounts without Expiration Dates: %i" % (usernoexpirecount))
i = 0
while i < len(usernoexpireList):
    print usernoexpireList[i]
    i += 1
print("\nExpired Accounts: %i" % (userexpirecount))
i = 0
while i < len(userexpireList):
    print userexpireList[i]
    i += 1

print

#-----System Accounts Report-----#
# There isn't much to do as far as handling. As long as they are not passed to the addtional functions
# that handle accoutns there we are fine.

print '=' * header 
print hfmt % (center ,'System Accounts')
print '=' * header

print fmt % (slength, 'Account', uilen, 'UID', dlength, 'Directory', statlen ,'Status', 'Expiration')
print '-' * slength, '-' * uilen, '-' * dlength, '-' * statlen, '-' * 10

for s in systm:

    acct = spwd.getspnam(s.pw_name)
    expire = calcTime(acct.sp_expire)
    status = " "

    # The main account we have to check here is root
    if  acct.sp_nam  == "root":
        if  acct.sp_pwd == "!":
            status = "Locked - Fix Now!"
        else:
            status = " "
    else:
        status = " "


    print fmt % (slength, s.pw_name, uilen , s.pw_uid, dlength, s.pw_dir, statlen,  status, expire)
