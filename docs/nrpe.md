# NRPE

NRPE allows you to remotely execute Nagios plugins on other Linux/Unix machines. This allows you to monitor remote machine metrics (disk usage, CPU load, etc).


## Installation


```
sudo apt-get install -y nagios-nrpe-server nagios-plugins
sudo sed -ie 's/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1,138.68.227.196/g' /etc/nagios/nrpe.cfg
sudo sed -ie 's/command_timeout=60/command_timeout=600/g' /etc/nagios/nrpe.cfg
sudo sed -ie 's/connection_timeout=300/connection_timeout=3000/g' /etc/nagios/nrpe.cfg
sudo ufw allow from 138.68.227.196 to any port 5666 proto tcp
```

Add to `/etc/nagios/nrpe_local.cfg`:

```
command[check_users]=/usr/lib/nagios/plugins/check_users -w 2 -c 5
command[check_load]=/usr/lib/nagios/plugins/check_load -w 5,4,3 -c 10,6,4
command[check_procs_zombie]=/usr/lib/nagios/plugins/check_procs -w 5 -c 10 -s Z
command[check_procs]=/usr/lib/nagios/plugins/check_procs -w 200 -c 300
command[check_swap]=/usr/lib/nagios/plugins/check_swap -w 50 -c 20
command[check_disk]=/usr/lib/nagios/plugins/check_disk -w 20% -c 10% -A
# mysql - first run sql: CREATE USER 'nagios'@'localhost' IDENTIFIED BY 'thepassword';
command[check_mysql]=/usr/lib/nagios/plugins/check_mysql -unagios -pthepassword
# docker check_disk - see sudoers below
command[check_disk]=/usr/bin/sudo /usr/lib/nagios/plugins/check_disk -w 15% -c 10% -A
```

Add to sudoers, at the bottom `sudo visudo`:

```
# nagios
User_Alias NRPERS = nagios, nrpe
Cmnd_Alias NRPERSCOMMANDS = /usr/bin/docker inspect *, /usr/lib/nagios/plugins/check_disk *
Defaults:NRPERS !requiretty
NRPERS ALL=(root) NOPASSWD: NRPERSCOMMANDS
```

Restart service

```
sudo service nagios-nrpe-server restart
```

Check logs

```
sudo tail -f /var/log/syslog | grep nrpe
```


## Testing

From server:

```
docker-compose exec shinken /usr/lib/nagios/plugins/check_nrpe -H example.com -c check_load
```


From client:

```
sudo -H -u nagios bash -c '/usr/lib/nagios/plugins/check_mysql' 
```