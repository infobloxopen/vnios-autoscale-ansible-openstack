!/bin/bash


echo "Please wait while we setup and update the apt-repo for you"
apt-get install pv -y >/dev/nul
sudo apt-add-repository ppa:ansible/ansible
apt-get update|pv --timer > /dev/null
while [ $? == 0 ] ; do
echo "We have updated the apt-repo."
 break
if [  $? -ne 0 ]; then
echo "apt-repo update unsuccessful,we are exiting."
exit 1
fi
done


package_check()
{
which $1  && which $2  && which $3 && which $4
if [ $? == 0 ]
then

echo  "$1 $2 $3 $4  installed"
else
echo  "$1  $2 $3 $4 not installed"
sleep 1
echo  "We will now install $1 $2 $3 $4 for you"
sudo apt-get install $1 -y && sudo apt-get install $2 -y && sudo apt-get install python-pip &&  pip install $3  &&  pip install $4
if [ $? == 0 ];then 
echo "We have successfully installed $1 $2 $3 $4 "; else
echo"Package installation unsuccessful, exiting"
exit 1
fi
 
fi
}

package_check $@

