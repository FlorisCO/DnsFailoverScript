# DNS Failover Script

## About

This shell script will try to connect to a TCP endpoint and update a CloudFlare DNS record when the availability changes.

## Usage

For the usage of the check.sh script please change the following variables to match your needs 

### Endpoint

- HOST="*test.example.com*"
- TCP_PORT="*PORTNR*"

### Cloudflare API details

To update a Cloudflare record, an API token is needed that has DNS edit rights on the DNS record's zone.

This script will switch the IP address of the specified DNS record from the production IP to the failover IP when the endpoint is not reachable.
When the endpoint is reachable again, the address will be switched back to the production IP.

- API_TOKEN="*CLOUDFLARE_API_TOKEN*"
- ZONE_ID="*CLOUDFLARE_ZONE_ID*"
- DNS_RECORD="*DNS_RECORD*"
- PROD_IP="*ORIGINAL_IP*"
- BACKUP_IP="*BACKUP_IP*"

### Example

```sh
HOST="ping.example.com"
TCP_PORT="8080"
API_TOKEN="52008908ca3a49c880dacb32b3e826fb"
ZONE_ID="2c7f6859b5e14d59a78f93e7ce3fe66b"
DNS_RECORD="service.example.com"
PROD_IP="127.0.0.1"
BACKUP_IP="127.0.0.2"
```