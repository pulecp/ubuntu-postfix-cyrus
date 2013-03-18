#!/bin/bash
apt-get update
apt-get -y install bind9

ip="x.x.x.x"        #ip address of your server
domain="example.com"   #domain of your server


ip1=`echo $ip | cut -f1 -d'.'`
ip2=`echo $ip | cut -f2 -d'.'`
ip3=`echo $ip | cut -f3 -d'.'`
ip4=`echo $ip | cut -f4 -d'.'`

echo "
zone \"$domain\" {
        type master;
        file \"/etc/bind/zones/$domain.db\";
};

zone \"$ip3.$ip2.$ip1.in-addr.arpa\" {
        type master;
        file \"/etc/bind/zones/rev.$ip3.$ip2.$ip1.in-addr.arpa\";
};" >> /etc/bind/named.conf.local

mkdir /etc/bind/zones

echo "\$TTL 1h
$domain.  IN      SOA     ns.$domain.        admin.$domain. (
                                                        209010910 ;
                                                        3600 ;
                                                        3600 ;
                                                        3600 ;
                                                        3600 ;
)

$domain. IN  NS      ns.$domain.
$domain. IN  MX      10      mail.$domain.

@        IN      A       $ip
www    IN      A       $ip
mail     IN      A       $ip
ns        IN      A       $ip
smtp    IN      A       $ip
imap    IN      A       $ip" > /etc/bind/zones/$domain.db

echo "\$TTL 1h
@ IN SOA ns.$domain. admin.$domain. (
                                                        2008112111 ;
                                                        3600 ;
                                                        3600 ;
                                                        3600 ;
                                                        3600 ;
)

                  IN      NS      ns.$domain.
$ip4              IN      PTR     $domain" > /etc/bind/zones/rev.$ip3.$ip2.$ip1.in-addr.arpa

/etc/init.d/bind9 restart
