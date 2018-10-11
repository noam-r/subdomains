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

[[ -z $DOMAIN ]] && usage && exit 1
[[ ! -f $SUBDOMAINFILE ]] && echo "Cannot read subdomain file" && exit 1

echo "Scanning $DOMAIN"

ip=$(dig +short $DOMAIN)
[[ ! -z "$ip" ]] && echo "ip for $DOMAIN is $ip" || echo "$DOMAIN has no ip"

while read subdomain; do
  [[ -z "$subdomain" ]] && continue
  full=$subdomain.$DOMAIN
  ip=$(dig +short $full | tr '\n' ' ')
  [[ ! -z "$ip" ]] && [[ ! $ip =~ ^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.) ]] && printf "FOUND %-25s %s\n" "$full" "$ip"
done <$SUBDOMAINFILE

echo "All done"
