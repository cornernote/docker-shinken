# Shinken Docker installation using pip (latest)
FROM debian:jessie

RUN echo "deb [check-valid-until=no] http://cdn-fastly.deb.debian.org/debian jessie main" > /etc/apt/sources.list.d/jessie.list
RUN echo "deb [check-valid-until=no] http://archive.debian.org/debian jessie-backports main" > /etc/apt/sources.list.d/jessie-backports.list
#RUN sed -i '/deb http:\/\/deb.debian.org\/debian jessie-updates main/d' /etc/apt/sources.list
RUN sed -i '/deb http:\/\/\(deb\|httpredir\).debian.org\/debian jessie.* main/d' /etc/apt/sources.list
RUN apt-get -o Acquire::Check-Valid-Until=false update
RUN echo "Acquire::Check-Valid-Until \"false\";" > /etc/apt/apt.conf.d/100disablechecks

# Install Shinken, Nagios plugins, apache2 and supervisord
RUN         apt-get update && apt-get install -y python-pip \
                python-pycurl \
                python-cherrypy3 \
                nagios-plugins \
                libsys-statistics-linux-perl \
                apache2 \
                libapache2-mod-proxy-html \
                supervisor \
                python-dev \
                python-cairo \
                python-crypto \
                libssl-dev \
                inotify-tools \
                ntp \
                vim \
                nano \
                ssmtp \
                mailutils \
                curl
RUN         useradd --create-home shinken && \
                pip install shinken pymongo>=3.0.3 requests arrow bottle==0.12.8 && \
                update-rc.d -f apache2 remove && \
                update-rc.d -f shinken remove

# Install shinken modules from shinken.io
RUN         chown -R shinken:shinken /etc/shinken/ && \
                su - shinken -c 'shinken --init' && \
                su - shinken -c 'shinken install webui2' && \
                su - shinken -c 'shinken install auth-htpasswd' && \
                su - shinken -c 'shinken install sqlitedb' && \
                su - shinken -c 'shinken install pickle-retention-file-scheduler' && \
                su - shinken -c 'shinken install booster-nrpe' && \
                su - shinken -c 'shinken install logstore-sqlite' && \
                su - shinken -c 'shinken install livestatus' && \
                su - shinken -c 'shinken install graphite' && \
                su - shinken -c 'shinken install ui-graphite'

# Install Graphite
RUN         pip install Twisted==11.1.0 && \
                pip install flup==1.0.2 && \
                pip install django==1.5.10 && \
                pip install django-tagging==0.3.2 && \
                pip install https://github.com/graphite-project/ceres/tarball/master && \
                pip install whisper==0.9.12 && \
                pip install carbon==0.9.12 && \
                pip install graphite-web==0.9.12 && \
                pip install gunicorn==19.1.1

# Install and configure thruk
RUN         gpg --keyserver keys.gnupg.net --recv-keys F8C1CA08A57B9ED7 && \
                gpg --armor --export F8C1CA08A57B9ED7 | apt-key add - && \
                echo 'deb http://labs.consol.de/repo/stable/debian jessie main' >> /etc/apt/sources.list && \
                apt-get update && \
                apt-get install -y thruk && \
                apt-get clean
ADD         files/etc/thruk/thruk_local.conf /etc/thruk/thruk_local.conf

# Install check_nrpe plugin
ADD         files/usr/src/nrpe-2.15.tar.gz /usr/src/
RUN         cd /usr/src/nrpe-2.15/ && \
                ./configure --with-nagios-user=shinken --with-nagios-group=shinken --with-nrpe-user=shinken --with-nrpe-group=shinken --with-ssl=/usr/bin/openssl --with-ssl-lib=/usr/lib/x86_64-linux-gnu && \
                make all && \
                make install-plugin && \
                mv /usr/local/nagios/libexec/check_nrpe /usr/lib/nagios/plugins/check_nrpe && \
                cd / && \
                rm -rf /usr/src/nrpe-2.15

# Configure apache
ADD         files/etc/apache2/sites-available/shinken_apache.conf /etc/apache2/sites-available/shinken_apache.conf
RUN         ln -sf /etc/apache2/sites-available/shinken_apache.conf /etc/apache2/sites-enabled/shinken_apache.conf
RUN         ln -sf /etc/apache2/mods-available/proxy* /etc/apache2/mods-enabled/
RUN         ln -sf /etc/apache2/mods-available/slotmem_shm.load /etc/apache2/mods-enabled/
RUN         ln -sf /etc/apache2/mods-available/xml2enc.load /etc/apache2/mods-enabled/

# Configure Shinken modules
ADD         files/etc/shinken/shinken.cfg /etc/shinken/shinken.cfg
ADD         files/etc/shinken/brokers/broker-master.cfg /etc/shinken/brokers/broker-master.cfg
ADD         files/etc/shinken/pollers/poller-master.cfg /etc/shinken/pollers/poller-master.cfg
ADD         files/etc/shinken/schedulers/scheduler-master.cfg /etc/shinken/schedulers/scheduler-master.cfg
ADD         files/etc/shinken/modules/webui2.cfg /etc/shinken/modules/webui2.cfg
ADD         files/etc/shinken/modules/webui2/plugins/worldmap/plugin.cfg /var/lib/shinken/modules/webui2/plugins/worldmap/plugin.cfg
ADD         files/etc/shinken/modules/livestatus.cfg /etc/shinken/modules/livestatus.cfg
ADD         files/etc/shinken/modules/graphite.cfg /etc/shinken/modules/graphite.cfg
ADD         files/etc/shinken/modules/ui-graphite.cfg /etc/shinken/modules/ui-graphite.cfg
ADD         files/etc/shinken/htpasswd.users /etc/shinken/htpasswd.users
RUN         mkdir -p /etc/shinken/custom_configs /usr/local/custom_plugins && \
                rm -f /etc/thruk/htpasswd && \
                ln -sf /etc/shinken/htpasswd.users /etc/thruk/htpasswd && \
                chown -R shinken:shinken /etc/shinken/

# Configure graphite
ADD         files/opt/graphite/conf/carbon.conf /opt/graphite/conf/carbon.conf
ADD         files/opt/graphite/conf/storage-schemas.conf /opt/graphite/conf/storage-schemas.conf
ADD         files/opt/graphite/conf/storage-aggregation.conf /opt/graphite/conf/storage-aggregation.conf
ADD         files/opt/graphite/webapp/graphite/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
RUN         mkdir -p /var/log/graphite && \
                cd /opt/graphite/webapp/graphite/ && \
                python manage.py syncdb --noinput

# Add shinken config watcher to restart arbiter, when changes happen
ADD         files/usr/bin/watch_shinken_config.sh /usr/bin/watch_shinken_config.sh
RUN         chmod 755 /usr/bin/watch_shinken_config.sh

# Copy extra NRPE plugins and fix permissions
ADD         files/usr/lib/nagios/plugins/ /usr/lib/nagios/plugins/
RUN         cd /usr/lib/nagios/plugins/ && \
                chmod a+x * && \
                chmod u+s check_apt restart_service check_ping check_icmp check_fping apt_update

# Copy configs
#COPY        files/* /

# Define mountable directories
VOLUME      ["/etc/shinken/custom_configs", "/usr/local/custom_plugins"]

# configure ssmtp
ADD         files/etc/ssmtp/* /etc/ssmtp/

# configure supervisor
ADD         files/etc/supervisor/conf.d/* /etc/supervisor/conf.d/

# Expost port 80 (apache2)
EXPOSE  80

# Default docker process
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
