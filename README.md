ubuntu-postfix-cyrus
====================

#### How to install Postfix with Cyrus and SASL authentication on Ubuntu 12.04


## To use this mail server configure your e-mail client as see below

IMAP: port 143, connection security: none, authentication: name/password

SMTP: port 465, connection security: STARTTLS, authentication: name/password

## Install needed packages

##### 1) apt-get -y install cyrus-admin cyrus-clients cyrus-imapd sasl2-bin postfix

## Edit following configuration files

##### 1) /etc/imapd.conf 

    admins: cyrus                             #edit line, nod add!!! (otherwise create mailbox “cm user.name” ends with permision denied)
    altnamespace: yes  			              #edit line, not add!!!
    allowplaintext: yes				          #edit line, not add!!!
    sasl_mech_list: PLAIN				      #edit line, not add!!!
    sasl_minimum_layer: 2				      #edit line, not add!!!
    sasl_pwdcheck_method: saslauthd     	  #add new line

##### 2) /etc/postfix/main.cf

    mydomain = example.com                                              #add new line
    mydestination = $myhostname, $mydomain, mail.$mydomain, localhost   #edit line, not add!!!
    mailbox_transport = cyrus                                           #add new line
    smtpd_sasl_auth_enable = yes                                        #add new line
    broken_sasl_auth_clients = yes                                      #add new line
    smtpd_sasl_type = cyrus                                             #add new line
    cyrus_sasl_config_path = /etc/postfix/sasl                          #add new line
    smtpd_sasl_security_options = noanonymous                           #add new line
    smtpd_recipient_restrictions =                                      #add new line
        permit_mynetworks,                                              
        permit_sasl_authenticated,
        reject_unauth_destination
    cyrus_destination_recipient_limit = 1                               #add new line
    
##### 3) /etc/default/saslauthd

    START=yes
    OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"    #edit line, not add!!!
    PARAMS="-c -m /var/spool/postfix/var/run/saslauthd"     #I think it isn't needed more

##### 4) /etc/postfix/master.cf (uncomment following, edit "argv=" parameter with path to deliver!!!, and comment what you don't need)

    cyrus unix - n n - - pipe
    flags=R user=cyrus argv=/usr/sbin/cyrdeliver -e -m "${extension}" ${user}
    
    smtps     inet  n       -       -       -       -       smtpd
    
    
##### 5) /etc/postfix/sasl/smtpd.conf (create new file)
    
    pwcheck_method: saslauthd
    
##### 6) change saslauth location because postfix runs chrooted

    rm -r /var/run/saslauthd/
    mkdir -p /var/spool/postfix/var/run/saslauthd
    ln -s /var/spool/postfix/var/run/saslauthd /var/run
    chgrp sasl /var/spool/postfix/var/run/saslauthd
    adduser postfix sasl                                    #adding postfix to sasl group
    
    
##### 7) change cyrus admin password

    saslpasswd2 -c cyrus
    passwd cyrus
    
##### 8) restart services

    /etc/init.d/cyrus-imapd restart
    /etc/init.d/postfix restart
    /etc/init.d/saslauthd restart
    
    
##### 9) some basic commands

    passwd cyrus		          	#change password to cyrus admin account
    cyradm -u cyrus localhost 	    #log into cyrus “shell” as admin
    cm user.name  		            #create mailbox name@example.com
    saslpasswd2 name		        #change password to mailbox name@example.com
    useradd kayn; passwd kayn	    #add user and change password to mailbox name@example.com
    
    #delete mailbox
    cyradm -u cyrus localhost
    sam user.kayn cyrus all #(I don't know why not work sufficient delete permission by "sam user.kayn cyrus d")
    dm user.kayn
    
##### 10) some debugging commands

    saslfinger -s
    
    #check smtps
    telnet example.com 465
    ehlo example.com
    ...more google it
    
    #other check smtps
    openssl s_client -connect smtp.kayn.tk:465 -state -debug
        
    #check imap
    telnet smtp.kayn.tk 143
    whatever login username password
    
    #you can add this line to /etc/postfix/main.cf
    debug_peer_list = example.com
    debug_peer_level = 2
    
    #you can make postfix more verbose by edit line in /etc/postfix/master.cf
    smtps     inet  n       -       -       -       -       smtpd -v -v
