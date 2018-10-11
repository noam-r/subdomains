# Stupid Subdomain Detector

Stupid Subdomain Detector is a small bash script that bute-checks the existance of subdomains for a given domain.

Usage:
```sh
$ ./subdomains.sh -d domain.com [-f subDomainFile.txt]
```

  - domain (-d) is required
  - subdomain file (-f) is optional

The default subdomain list was taken from https://github.com/rbsec/dnscan
