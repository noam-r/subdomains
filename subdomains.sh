#!/bin/bash

###########################################################################
#               subdomains.sh was written by @noamr                       #
#               usage is free under  (CC BY 3.0 US)                       #
#  default subdomain list was taken from https://github.com/rbsec/dnscan  #
###########################################################################

DOMAIN=
SUBDOMAINFILE=./subdomains.txt
OUTPUTLEVEL=all

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
        -ol | --output-level )  shift
                                OUTPUTLEVEL=$1
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

echo "* Scanning $DOMAIN"

ip=$(dig +short $DOMAIN)
[[ ! -z "$ip" ]] && printf "ip for $DOMAIN is $ip\n\n" || echo "$DOMAIN has no ip"

# Check for zone-transfer, you never know
NSS=($(dig NS $DOMAIN +short))
for NS in "${NSS[@]}"
do
  echo "* Checking Nameserver $NS for zone-transfer"
  RESULTS=($(dig axfr @$NS $DOMAIN +short))
  if ((${#RESULTS[@]}>5)); then
	echo "FOUND using: dig axfr @$NS $DOMAIN - have fun"

  if [ "$OUTPUTLEVEL" == "ip" ]; then
    awk_printf_prefix='$1=$4="";'
    awk_condition='$4 == "A"'
  elif [ "$OUTPUTLEVEL" == "sub" ]; then
    awk_printf_prefix='$4=$5="";'
    awk_condition=''
  else
    awk_printf_prefix=''
    awk_condition=''
  fi
  printf "%s\n" "$(dig axfr @$NS $DOMAIN | sed '/^;/ d' | sort -k4 | awk "$awk_condition"' {'"$awk_printf_prefix"' printf "%-50s %-10s %s\n", $1, $4, $5}'| sed 's/^ *//;s/ *$//')"
	exit
  fi
done

echo "* No zone-transfer found on all nameservers, moving on"

# Check for catch-all subdomain, which will make the rest of the script redundant
RANDOM_SUB=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
ip=$(dig +short RANDOM_SUB.$DOMAIN)
[[ ! -z "$ip" ]] && echo "$DOMAIN catch-all subdomains is enabled" && exit 1

echo "* Catch-all subdomains is not enabled, moving on"

echo "* Starting brute-force"

while read subdomain; do
  [[ -z "$subdomain" ]] && continue
  full=$subdomain.$DOMAIN
  ip=$(dig +short $full | tr '\n' ' ')

  if [[ (! -z "$ip") && (! $ip =~ ^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)) ]]; then
    if [ "$OUTPUTLEVEL" == "ip" ]; then
      iponly=`echo $ip | awk '{print $NF}'`
      printf "%s\n" "$iponly"
    elif [ "$OUTPUTLEVEL" == "sub" ]; then
      printf "%s\n" "$full"
    else
      printf "%-25s %s\n" "$full" "$ip"
    fi
  fi
done <$SUBDOMAINFILE

echo "All done"
