Balena on-site network checker
==============================

Run locally to test the suitability of the current network for a Balena
deployment.

Check the [Balena network requirements](https://www.balena.io/docs/reference/OS/network/2.x/#network-requirements) for details.

To use:

```
docker-compose build
docker run -it --rm on-site-checker_network-check:latest -u <uuid> -t <api token> -a https://api.balena-cloud.com -r https://registry2.balena-cloud.com
```

Where:
- **uuid**: Device UUID
- **api token**: Balena API Key

A compliant network reports:
```
{
  "checks": [
    {
      "name": "check_site",
      "success": true,
      "status": "No site issues detected"
    }
  ]
}
```
