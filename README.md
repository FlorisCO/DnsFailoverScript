# DNS Failover Script

## About

This shell script will check if a TCP endpoint and update a CloudFlare DNS record when the availability changes.

## Usage

For the usage of the check.sh script please change the following variables to match your needs 

### Endpoint

- HOST="*test.example.com*"
- TCP_PORT="*PORTNR*"

### Cloudflare API details

- API_TOKEN="*CLOUDFLARE_API_TOKEN*"
- ZONE_ID="*CLOUDFLARE_ZONE_ID*"
- dnsrecord="*DNS_RECORD*"
- NEW_IP_ON_SUCCESS="*ORIGINAL_IP*"
- ALTERNATE_IP_ON_FAILURE="*BACKUP_IP*"

### Example

```sh
HOST="ping.example.com"
TCP_PORT="8080"
API_TOKEN="52008908ca3a49c880dacb32b3e826fb"
ZONE_ID="*2c7f6859b5e14d59a78f93e7ce3fe66b*"
dnsrecord="service.example.com"
NEW_IP_ON_SUCCESS="127.0.0.1"
ALTERNATE_IP_ON_FAILURE="127.0.0.2"
```