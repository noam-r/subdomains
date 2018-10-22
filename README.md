# Stupid Subdomain Detector

Stupid Subdomain Detector is a small bash script that bute-checks the existance of subdomains for a given domain.

Usage:
```sh
$ ./subdomains.sh -d domain.com [-f subDomainFile.txt] [-ol all|sub|ip]
```

  - domain (-d) is required
  - subdomain file (-f) is optional
  - output-level (-ol) is optional - display all by default

The default subdomain list was taken from https://github.com/rbsec/dnscan
