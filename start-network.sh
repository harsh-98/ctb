# For generating crypto materials and channel configuration transactions,
# starting the members (docker images) of network 
# instantiating chaincode on channel.

./ctb.sh down <<< "Y" &&  ./ctb.sh generate <<< "Y" && ./ctb.sh up  <<< "Y"  && ./ctb.sh test <<< "Y"
