#!/bin/bash

###########################################################################
#               subdomains.sh was written by @noamr                       #
#               usage is free under  (CC BY 3.0 US)                       #
#  default subdomain list was taken from https://github.com/rbsec/dnscan  #
###########################################################################

DOMAIN=
SUBDOMAINFILE=./subdomains.txt
OUTPUTLEVEL=all
SKIP_INTERNAL_IP=yes

usage()
{
cat <<EOM
usage: ${0##*/} [OPTIONS] -d domain.tld
Options:
  -f  | -subdomain-file <subdomains file>  Path to subdomains file. Each subdomain should be in a new line. Defaults to subdomains.txt.
  -ol | --output-level  <all|ip|sub>       Output level. Defaults to all.
  -si | --show-internal                    Show private subnets IPs. Defaults to false.
  -h  | --help                             Print this message and exit.
EOM
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
        -si | --skip-internal ) SKIP_INTERNAL_IP=no
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
  RESULTS=($(dig axfr @$NS $DOMAIN | egrep '^;; XFR size: [1-9]'))
  EXIT_CODE=$?
  if [[ "${EXIT_CODE}" == "0" ]]; then
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

RANDOM_SUB=$(hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/urandom)
CATCHALL_IP=$(dig +short $RANDOM_SUB.$DOMAIN)
if [[ ! -z "$CATCHALL_IP" ]]; then
  echo "$DOMAIN catch-all subdomains is enabled (${CATCHALL_IP})"
fi

echo "* Starting brute-force"

while read subdomain; do
  [[ -z "$subdomain" ]] && continue
  full=$subdomain.$DOMAIN
  ip=$(dig +short $full | tr '\n' ' ')

  if [[ (! -z "$ip") ]]; then
    iponly=`echo $ip | awk '{print $NF}'`
    if [[ ! -z "$CATCHALL_IP" ]]; then
      _IS_CATCHALL_IP=0
      for _CATCHALL_IP in "${CATCHALL_IP[@]}"; do
        if [[ "${_CATCHALL_IP}" == "${iponly}" ]]; then
          _IS_CATCHALL_IP=1
          break
        fi
      done
      if [[ "${_IS_CATCHALL_IP}" == "1" ]]; then
        continue;
      fi
    fi
    if [[ "${SKIP_INTERNAL_IP}" == "no" || (! $ip =~ ^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.)) ]]; then
      if [ "$OUTPUTLEVEL" == "ip" ]; then
        printf "%s\n" "$iponly"
      elif [ "$OUTPUTLEVEL" == "sub" ]; then
        printf "%s\n" "$full"
      else
        printf "%-25s %s\n" "$full" "$ip"
      fi
    fi
  fi
done <$SUBDOMAINFILE

echo "All done"
