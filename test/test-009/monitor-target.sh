delay=${maddog_oopsdelay:-1}

sleep $delay
echo BYE 1>&3

sleep $delay
echo "This control message is not receiced." 1>&3
sleep $delay
sleep $(printf '%1.1f' $(echo "scale=1; 2 - $delay - $delay" | bc))

exit 0
