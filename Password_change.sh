_l="/etc/login.defs"
_p="/etc/passwd"
 
## get mini UID limit ##
l=$(grep "^UID_MIN" $_l)
 
## get max UID limit ##
l1=$(grep "^UID_MAX" $_l)

users=`awk -F':' -v "min=${l##UID_MIN}" -v "max=${l1##UID_MAX}" '{ if ( $3 >= min && $3 <= max  && $7 != "/sbin/nologin" ) print $1 }' "$_p"`

for i in $users
do
    current=`echo $(( $(date +%s)/3600/24 ))`
    toexp=`chage -l $i | grep "Password expires" | awk -F':' '{print $2}'`
    expire=`echo $(( $(date -d "$toexp" +%s)/3600/24 ))`
    diff=`echo $(( (expire - current) ))`
    key=`cat /home/$i/.ssh/authorized_keys`
    
    if [[ $key == "" ]]; 
    then 
        echo "empty key user: $i"
    else 
        echo "not empty key user: $i"
        if [[ $diff -le 6 ]];
        then
            echo "$i needs change $diff days"
            NPASS=$( tr -dc "[:graph:]"  < /dev/urandom  | head -c 32)
            (echo $NPASS ; echo $NPASS) | passwd  $i
            unset NPASS
        else
            echo "$i does not need change $diff days left"
        fi 
    fi
done
