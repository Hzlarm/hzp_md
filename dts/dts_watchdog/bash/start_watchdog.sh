#!/bin/sh
reg w 10000120 0x03e80000
reg w 10000124 0x2710
reg w 10000120 0x03e80090     
echo "--------auto-----------" >> ~/dog_log 
/root/cat_reg.sh
echo "--------auto-----------" >> ~/dog_log
