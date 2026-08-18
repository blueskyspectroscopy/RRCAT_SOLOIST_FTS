MODULE MC1808X_DLM
DESCRIPTION Measurement Computing 18bit Simultaneous ADC, synchronous I/O
VERSION 1.0
SOURCE Jacob Groeneveld

#add functions here in alphabetical order 
#FUNCTION FUNCTIONNAME MINARG MAXARG OPTIONS

#Analog input scan.
FUNCTION MC1808X_AIN 6 6 

#Analog output scan.
FUNCTION MC1808X_AOUT 7 7 

#Set AIn mode to diff or single ended. A wrapper for the API function cbAInputMode.
FUNCTION MC1808X_CBAINPUTMODE 2 2 

#release DAQ.
FUNCTION MC1808X_CLOSE 1 1 

#synchronous input scan.
FUNCTION MC1808X_DAQIN 8 8 

#synchronous output scan.
FUNCTION MC1808X_DAQOUT 8 8 

#A wrapper for the API function cbDAQSETTRIGGER.
FUNCTION MC1808X_DAQSETTRIGGER 9 9

#Function to determine all the devices currently connected.
FUNCTION MC1808X_DEVICEDISCOVERY 2 2

#read digital bit. Uses cbDBitIn().
FUNCTION MC1808X_DIN 2 2 

#write digital bit. Uses cbDBitOut().
FUNCTION MC1808X_DOUT 3 3 

#dump data from windows buffer.
FUNCTION MC1808X_DUMP 2 2 

#initalize communications with DAQ. 
FUNCTION MC1808X_INIT 1 1 

#Returns the state of current operations. A wrapper for the API function cbAGetStatus.
FUNCTION MC1808X_READY 5 5 

#A wrapper for the API function cbSETCONFIG.
FUNCTION M1808XC_SETCONFIG  5 5

#A wrapper for the API function cbSETTRIGGER.
FUNCTION MC1808X_SETTRIGGER 4 4

#Returns the status of the board and C-Level errors.
FUNCTION MC1808X_STATUS 2 2

#Stop background operations. A wrapper for the API function cbStopBackground.
FUNCTION MC1808X_STOP 2 2 