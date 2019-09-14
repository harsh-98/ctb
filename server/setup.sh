# Removing previous keys
# enrolling new one for admin
# then registering user for org1

rm -rf wallet && node newadmin.js org1 && node newuser.js tester org1

