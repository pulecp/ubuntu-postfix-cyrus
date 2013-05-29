ubuntu-postfix-cyrus
====================

#### How to install Postfix with Cyrus and SASL authentication on Ubuntu 12.04 + Web-cyradm + MySQL

## Own DNS server 

For own DNS server execute `bind.sh` script, where change following:

    ip="x.x.x.x"            #ip address of your server
    domain="example.com"    #domain of your server

## Postfix + Cyrus + SASL + MySQL

**To use this mail server configure your e-mail client as see below**

IMAP: port 143, connection security: none, authentication: name/password

SMTP: port 465, connection security: STARTTLS, authentication: name/password

### Install needed packages

##### 1) apt-get -y install cyrus-admin cyrus-clients cyrus-imapd sasl2-bin postfix mysql-server mysql-client libpam-mysql postfix-mysql

### Edit following configuration files

##### 1) /etc/imapd.conf 

    admins: cyrus                             #edit line, nod add!!! (otherwise create mailbox “cm user.name” ends with permision denied)
    altnamespace: yes      		              #edit line, not add!!!
    allowplaintext: yes				          #edit line, not add!!!
    sasl_mech_list: pam 				      #edit line, not add!!!
    sasl_minimum_layer: 2				      #edit line, not add!!!
    sasl_pwcheck_method: saslauthd      	  #add new line
    asl_saslauthd_path: /var/spool/postfix/var/run/saslauthd/mux    # for web-cyradm
    
    #for STARTTLS and TLS/SSL
    tls_cert_file: /etc/ssl/cyrus/server.pem
    tls_key_file: /etc/ssl/cyrus/server.pem
    tls_ca_file: /etc/ssl/cyrus/server.pem
    tls_ca_path: /etc/ssl/cyrus


* generating server.pem: http://www.tldp.org/HOWTO/Postfix-Cyrus-Web-cyradm-HOWTO/cyrus-config.html or http://pastebin.com/raw.php?i=CU17QBuQ

##### 2) /etc/postfix/main.cf

    mydomain = example.com                                              #add new line
    mydestination = $myhostname, $mydomain, mail.$mydomain, localhost, mysql:/etc/postfix/mysql-mydestination.cf   #edit line, not add!!!
    mailbox_transport = cyrus                                           #add new line
    
    virtual_alias_maps = hash:/etc/postfix/virtual, mysql:/etc/postfix/mysql-virtual.cf #add new line
    sender_canonical_maps = mysql:/etc/postfix/mysql-canonical.cf                       #add new line
    broken_sasl_auth_clients = yes                                      #add new line
    cyrus_sasl_config_path = /etc/postfix/sasl                          #add new line
    smtpd_sasl_security_options = noanonymous                           #add new line
    smtpd_recipient_restrictions =                                      #add new line
        permit_mynetworks,                                              
        permit_sasl_authenticated,
        reject_unauth_destination
    
##### 3) copy some postfix configuration files (I suppose you clone this repository into /root directory)

    cp /root/ubuntu-postfix-cyrus/etc/postfix/* /etc/postfix

##### 4) /etc/default/saslauthd

    START=yes
    OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd -r"    #edit line, not add!!!
    PARAMS="-c -m /var/spool/postfix/var/run/saslauthd"     #I think it isn't needed more
    
-r due to use username+domain in SELECT query: http://pastebin.com/raw.php?i=Tx5KrxtN

##### 5) /etc/postfix/master.cf (uncomment following, edit "argv=" parameter with path to deliver!!!, and comment what you don't need)

    cyrus unix - n n - - pipe
    flags=R user=cyrus argv=/usr/sbin/cyrdeliver -e -m "${extension}" ${user}
    
    smtps     inet  n       -       -       -       -       smtpd
    
    
##### 6) /etc/postfix/sasl/smtpd.conf (create new file)
    
    pwcheck_method: saslauthd
    mech_list: PLAIN LOGIN
    
##### 7) change saslauth location because postfix runs chrooted and permission to mysql folder

    rm -r /var/run/saslauthd/
    mkdir -p /var/spool/postfix/var/run/saslauthd 
    ln -s /var/spool/postfix/var/run/saslauthd /var/run/saslauthd
    chgrp sasl /var/spool/postfix/var/run/saslauthd
    adduser postfix sasl                                    #adding postfix to sasl group
    adduser postfix mail                                    #adding postfix to mail group
    chmod -R 755 /var/lib/mysql/
    
    
##### 8) change cyrus admin password

    saslpasswd2 -c cyrus
    passwd cyrus
    
##### 9) restart services

    /etc/init.d/cyrus-imapd restart
    /etc/init.d/postfix restart
    /etc/init.d/saslauthd restart
    
    
##### 10) some basic commands

    passwd cyrus		          	#change password to cyrus admin account
    cyradm -u cyrus localhost 	    #log into cyrus “shell” as admin
    cm user.name  		            #create mailbox name@example.com
    saslpasswd2 name		        #change password to mailbox name@example.com
    useradd name; passwd name	    #add user and change password to mailbox name@example.com
    
    #delete mailbox
    cyradm -u cyrus localhost
    sam user.name cyrus all #(I don't know why not work sufficient delete permission by "sam user.name cyrus d")
    dm user.name
    
##### 11) some debugging commands

    saslfinger -s
    
    #check imap and smtp
    smtptest -u user -a user
    imtest -u user -a user
    
    #check starttls
    telnet example.com 465
    ehlo example.com
    ...more google it
    
    #check tls/ssl
    openssl s_client -connect smtp.example.com:465 -state -debug
        
    #check imap
    telnet smtp.example.com 143
    whatever login username password
    
    
    #you can add this line to /etc/postfix/main.cf
    debug_peer_list = example.com
    debug_peer_level = 2
    
    #you can make postfix more verbose by edit line in /etc/postfix/master.cf
    smtps     inet  n       -       -       -       -       smtpd -v -v
    

## Web-cyradm

### Install needed packages (I suppose you clone this repository into /root directory)

##### 1) apt-get -y install apache2 php5 libapache2-mod-php5 php5-mysql

##### 2) place web-cyradm application into right directory and extract

    mkdir -p /var/www
    cp /root/ubuntu-postfix-cyrus/web-cyradm-svn-0.5.5.tar.gz /var/www
    cd /var/www
    tar -xvzf web-cyradm-svn-0.5.5.tar.gz
    rm web-cyradm-svn-0.5.5.tar.gz

##### 3) create VirtualHost in apache2

    cp /root/ubuntu-postfix-cyrus/etc/apache2/sites-available/web-cyradm-svn-0.5.5 /etc/apache2/sites-available
    cd /etc/apache2/sites-enabled
    ln -s ../sites-available/web-cyradm-svn-0.5.5 web-cyradm-svn-0.5.5
    
##### 4) configure web-cyradm (when you use default settings, you needn't edit conf.php)

    cd /var/www/web-cyradm-svn-0.5.5/config/
    cp conf.php.dist conf.php
    
##### 5) configure mysql (edit passwords in sql script as needed)

    cd /var/www/web-cyradm-svn-0.5.5/scripts/
    sed -i 's/TYPE=MyISAM/ENGINE=MyISAM/;s/timestamp(14)/timestamp/' create_mysql.sql   #modification for newest mysql
    mysql < insertuser_mysql.sql
    mysql mail -u mail -p < create_mysql.sql        #password is 'secret'
    
##### 6) restart all services

    /etc/init.d/cyrus-imapd restart
    /etc/init.d/mysql restart
    /etc/init.d/postfix restart
    /etc/init.d/saslauthd restart
    /etc/init.d/apache2 restart

    







##### At the end what maybe help you (but if all is working, not do it)

    ln -s /var/run/mysqld/mysqld.sock /tmp/mysql.sock
    echo "pwcheck_method: saslauthd" > /usr/lib/sasl2/smtpd.conf

Possible missing packages: php-db
