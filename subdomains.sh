#!/bin/bash

###########################################################################
#               subdomains.sh was written by @noamr                       #
#               usage is free under  (CC BY 3.0 US)                       #
#  default subdomain list was taken from https://github.com/rbsec/dnscan  #
###########################################################################

DOMAIN=
SUBDOMAINFILE=./subdomains.txt

usage()
{
    echo "usage: ${0##*/} -d domain.tld [-f file.txt]"
}

while [ "$1" != "" ]; do
    case $1 in
        -d | --domain )         shift
                                DOMAIN=$1
                                ;;
        -f | --subdomain-file ) shift
				SUBDOMAINFILE=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

[[ ! -f $SUBDOMAINFILE ]] && echo "Cannot read subdomain file" && exit 1

echo "Scanning $DOMAIN"

ip=$(dig +short $DOMAIN)
[[ ! -z "$ip" ]] && echo "ip for $DOMAIN is $ip" || echo "$DOMAIN has no ip"

# Check for catch-all subdomain, which will make the rest of the script redundant
RANDOM_SUB=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
ip=$(dig +short RANDOM_SUB.$DOMAIN)
[[ ! -z "$ip" ]] && echo "$DOMAIN catch-all subdomains is enabled" && exit 1

while read subdomain; do
  [[ -z "$subdomain" ]] && continue
  full=$subdomain.$DOMAIN
  ip=$(dig +short $full)
  [[ ! -z "$ip" ]] && echo "FOUND $full"
done <$SUBDOMAINFILE

echo "All done"
