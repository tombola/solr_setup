# from webikon - bit.ly/1L7pSBl

echo 'install Oracle Java 7'
sudo apt-get purge oracle-java6-installer
sudo apt-get install software-properties-common python-software-properties
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java7-installer

echo 'get Tomcat'
sudo apt-get install tomcat7 tomcat7-admin

echo 'Solr 4.7'
cd ~
wget http://archive.apache.org/dist/lucene/solr/4.7.0/solr-4.7.0.tgz
tar -xzvf solr-4.7.0.tgz
sudo mv solr-4.7.0 /usr/share/solr
cd /usr/share/solr/example
sudo cp webapps/solr.war multicore/solr.war
cd /usr/share
sudo cp -r solr/example/lib/ext/* tomcat7/lib/
sudo cp -r solr/example/resources/log4j.properties tomcat7/lib/

echo 'Configure the following'
echo 'solr.log=/usr/share/solr'
read -sn 1 -p "(Press any key to proceed)"
sudo nano /usr/share/tomcat7/lib/log4j.properties
echo 'add the following'
echo '<Context docBase="/usr/share/solr/example/multicore/solr.war" debug="0" crossContext="true">
  <Environment name="solr/home" type="java.lang.String" value="/usr/share/solr/example/multicore" override="true" />
</Context>'
read -sn 1 -p "(Press any key to proceed)"
sudo nano /etc/tomcat7/Catalina/localhost/solr.xml
echo 'add the following'
echo '<tomcat-users>
  <role rolename="manager-gui"/>
  <user username="admin" password="mysecretpassword" roles="manager-gui"/>
</tomcat-users>'
read -sn 1 -p "(Press any key to proceed)"
sudo nano /etc/tomcat7/tomcat-users.xml

# set JAVA_HOME (add to .profile? y/n)
read -p "set JAVA_HOME? [y/n]" answer
if [[ $answer = y ]] ; then
    echo "Uncomment JAVA_HOME and set to correct path"
    echo "eg JAVA_HOME=/usr/lib/jvm/java-7-oracle"
    sudo nano /etc/default/tomcat7
fi

read -p "set up drupal site solr config? [y/n]" answer
if [[ $answer = y ]] ; then
    echo -n "what is the path to your drupal site? (no trailing slash)" 
    read drupalpath

    read -p "apply patch and missing files? (hacky) [y/n] (todo: amend repo)" answer
    if [[ $answer = y ]] ; then
        # This patch may not always need to be applied
        cd $drupalpath/sites/all/modules/apachesolr
        sudo wget https://www.drupal.org/files/apachesolr-remove-duplicate-parameter-definition-2107417-5.patch
        sudo patch -p1 < apachesolr-remove-duplicate-parameter-definition-2107417-5.patch

        # get some missing conf files - solve by updating?
        cd ~
        drush dl apachesolr
        rsync -r --ignore-existing ~/apachesolr/solr-conf/solr-4.x/ $drupalpath/sites/all/modules/apachesolr/solr-conf/solr-4.x
        sudo rm -rf apachesolr
    fi

    sudo cp $drupalpath/sites/all/modules/apachesolr/solr-conf/solr-4.x/* /usr/share/solr/example/multicore/core0/conf
fi


sudo chown -R tomcat7 /usr/share/solr/example/multicore
sudo service tomcat7 restart

echo ''
echo 'see webikon article for steps taken - bit.ly/1L7pSBl'
echo ''
echo "to check if Solr is running, go to mysite:8080/solr"
echo "you may have to vagrant reload"
