# Check Cron

`/usr/local/nagios/etc/nrpe.cfg`

```
command[check_cron]=/usr/lib/nagios/plugins/check_file_age /tmp/cron-running
```

`crontab -unagios -e`

```
MAILTO=""
* * * * * touch /tmp/cron-running
```