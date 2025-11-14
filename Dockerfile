FROM debian:bullseye

# labels

ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/archont94/counter-strike1.6"

ARG rehlds_version=3.7.0.695
ARG metamod_version=1.3.0.149
ARG jk_botti_version=1.43
ARG steamcmd_url=https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
ARG rehlds_url="https://github.com/dreamstalker/rehlds/releases/download/$rehlds_version/rehlds-dist-$rehlds_version-dev.zip"
ARG metamod_url="https://github.com/rehlds/metamod-r/releases/download/$metamod_version/metamod-bin-$metamod_version.zip"
ARG amxmod_url="https://www.amxmodx.org/amxxdrop/1.9/amxmodx-1.9.0-git5263-base-linux.tar.gz"
ARG revoice_url="https://teamcity.rehlds.org/guestAuth/downloadArtifacts.html?buildTypeId=Revoice_Publish&buildId=lastSuccessful"
ARG jk_botti_url="https://jukivili.kapsi.fi/web/jk_botti/jk_botti-1.43-release.tar.xz"
ARG rehlds_url=https://github.com/dreamstalker/rehlds/releases/download/3.14.0.857/rehlds-dist-3.14.0.857-dev.zip
ARG regamedll_version=5.26.0.668
ARG reapi_version=5.24.0.300
ARG regamedll_url="https://github.com/s1lentq/ReGameDLL_CS/releases/download/$regamedll_version/regamedll-bin-$regamedll_version.zip"
ARG reapi_url="https://github.com/s1lentq/reapi/releases/download/$reapi_version/reapi-bin-$reapi_version.zip"
ARG revoice_url="https://github.com/rehlds/ReVoice/releases/download/0.1.0.34/revoice_0.1.0.34.zip"



# define default env variables
ARG SERVER_NAME="Counter-Strike 1.6 DockerServer"
ARG FAST_DL="http://127.0.0.1/cstrike/"
ARG ADMIN_STEAM_ID="STEAM_0:0:123456"

ENV PORT=27015
ENV MAP=de_dust2
ENV MAXPLAYERS=16
ENV SV_LAN=0

# install dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get -qqy install lib32gcc-s1 libstdc++6:i386 libc6-dev:i386 libc6:i386 libcurl4:i386 libcurl3-gnutls:i386 curl nginx vim git make cmake build-essential g++-multilib libc6-dev-i386 lib32stdc++6 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*


# create directories, download steamcmd and install CS 1.6 via steamcmd
#     additional info: https://danielgibbs.co.uk/2017/10/hlds-steamcmd-workaround-appid-90-part-ii/

RUN mkdir /root/Steam /root/.steam # && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxf - -C /root/Steam && \
    /root/Steam/steamcmd.sh +login anonymous +force_install_dir "/hlds" +app_update 90 +app_set_config 90 mod cstrike validate +quit || true && \
    rm -r /hlds/steamapps/* && \
    curl -s https://raw.githubusercontent.com/dgibbs64/HLDS-appmanifest/master/CounterStrike/appmanifest_90.acf -o /hlds/steamapps/appmanifest_90.acf && \
    /root/Steam/steamcmd.sh +login anonymous +force_install_dir "/hlds" +app_update 90 +app_set_config 90 mod cstrike validate +quit && \
    rm -r /root/.steam /root/Steam

RUN mkdir -p /root/Steam /root/.steam /hlds/steamapps && \
    curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxf - -C /root/Steam && \
    #echo '"AppState"' > /hlds/steamapps/appmanifest_90.acf && \
    #echo '{' >> /hlds/steamapps/appmanifest_90.acf && \
    #echo '"appid" "90"' >> /hlds/steamapps/appmanifest_90.acf && \
    #echo '"Universe" "1"' >> /hlds/steamapps/appmanifest_90.acf && \
    #echo '"StateFlags" "4"' >> /hlds/steamapps/appmanifest_90.acf && \
    #echo '"buildid" "6153"' >> /hlds/steamapps/appmanifest_90.acf && \
    #echo '}' >> /hlds/steamapps/appmanifest_90.acf && \
    /root/Steam/steamcmd.sh +force_install_dir "/hlds" +login anonymous +app_set_config 90 mod cstrike +app_update 90 -beta steam_legacy validate +quit
    #rm -rf /root/.steam /root/Steam



# configure nginx to allow for FastDownload
RUN mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.backup && \
    bash -c "mkdir -p /srv/cstrike/{gfx,maps,models,overviews,sound,sprites}/nothing-here"
COPY nginx_config.conf /etc/nginx/sites-available/default

# configure FastDownload
RUN echo "// enable fast download - sv_downloadurl have to start with 'http', end with 'cstrike/', i.e. 'http://10.20.30.40/cstrike/'  " >> /hlds/cstrike/server.cfg && \
    echo "sv_downloadurl \"$FAST_DL\"" >> /hlds/cstrike/server.cfg && \
    echo "sv_allowdownload 1" >> /hlds/cstrike/server.cfg && \
    echo "sv_allowupload 1" >> /hlds/cstrike/server.cfg

# change server name
RUN sed -i "s/hostname \"Counter-Strike 1.6 Server\"/hostname \"$SERVER_NAME\"/" /hlds/cstrike/server.cfg

RUN apt-get update && apt-get install unzip

# instal rehlds
RUN curl -sLJO https://github.com/rehlds/ReHLDS/releases/download/3.14.0.857/rehlds-bin-3.14.0.857.zip \
    && mkdir -p /opt/steam/rehlds \
    && unzip rehlds-bin-3.14.0.857.zip -d /opt/steam/rehlds \
    && cp -R /opt/steam/rehlds/bin/linux32/* /hlds/ \
    && rm -rf rehlds-bin-3.14.0.857.zip  "/opt/steam/rehlds"

RUN mkdir -p /opt/steam/hlds

RUN mv /hlds/* /opt/steam/hlds

# Install Metamod-R
RUN mkdir -p /opt/steam/hlds/cstrike/addons/metamod \
    && touch /opt/steam/hlds/cstrike/addons/metamod/plugins.ini
RUN curl -sqL "$metamod_url" > tmp.zip
RUN unzip -j tmp.zip "addons/metamod/metamod*" -d /opt/steam/hlds/cstrike/addons/metamod
RUN chmod -R 755 /opt/steam/hlds/cstrike/addons/metamod
RUN sed -i 's/dlls\/cs\.so/addons\/metamod\/metamod_i386.so/g' /opt/steam/hlds/cstrike/liblist.gam

# Install AMX mod X
RUN curl -sqL "$amxmod_url" | tar -C /opt/steam/hlds/cstrike/ -zxvf - \
    && echo 'linux addons/amxmodx/dlls/amxmodx_mm_i386.so' >> /opt/steam/hlds/cstrike/addons/metamod/plugins.ini
RUN cat /opt/steam/hlds/cstrike/mapcycle.txt >> /opt/steam/hlds/cstrike/addons/amxmodx/configs/maps.ini

# Install ReGameDLL_CS
RUN curl -sLJO "$regamedll_url" \
 && unzip -o -j regamedll-bin-$regamedll_version.zip "bin/linux32/cstrike/*" -d "/opt/steam/hlds/cstrike" \
 && unzip -o -j regamedll-bin-$regamedll_version.zip "bin/linux32/cstrike/dlls/*" -d "/opt/steam/hlds/cstrike/dlls"

# Install ReAPI
RUN curl -sLJO "$reapi_url" \
 && unzip -o reapi-bin-$reapi_version.zip -d "/opt/steam/hlds/cstrike"
RUN echo 'reapi' >> /opt/steam/hlds/cstrike/addons/amxmodx/configs/modules.ini

# Install Reunion
RUN mkdir -p /opt/steam/hlds/cstrike/addons/reunion
COPY lib/reunion/bin/Linux/reunion_mm_i386.so /opt/steam/hlds/cstrike/addons/reunion/reunion_mm_i386.so
COPY lib/reunion/reunion.cfg /opt/steam/hlds/cstrike/reunion.cfg
COPY lib/reunion/amxx/* /opt/steam/hlds/cstrike/addons/amxmodx/scripting/
RUN mkdir -p /opt/steam/hlds/cstrike/addons/metamod \
    && echo 'linux addons/reunion/reunion_mm_i386.so' >> /opt/steam/hlds/cstrike/addons/metamod/plugins.ini \
    && sed -i 's/Setti_Prefix1 = 5/Setti_Prefix1 = 4/g' /opt/steam/hlds/cstrike/reunion.cfg


# Install bind_key
COPY lib/bind_key/amxx/bind_key.amxx /opt/steam/hlds/cstrike/addons/amxmodx/plugins/bind_key.amxx
RUN echo 'bind_key.amxx            ; binds keys for voting' >> /opt/steam/hlds/cstrike/addons/amxmodx/configs/plugins.ini

# Install ReVoice
RUN mkdir -p /opt/steam/hlds/cstrike/addons/revoice && \
    curl -sL "$revoice_url" -o /tmp/revoice.zip && \
    unzip -o /tmp/revoice.zip -d /tmp/revoice && \
    find /tmp/revoice -name "revoice_mm_i386.so" -exec cp {} /opt/steam/hlds/cstrike/addons/revoice/revoice_mm_i386.so \; && \
    find /tmp/revoice -name "revoice.cfg" -exec cp {} /opt/steam/hlds/cstrike/addons/revoice/revoice.cfg \; && \
    echo 'linux addons/revoice/revoice_mm_i386.so' >> /opt/steam/hlds/cstrike/addons/metamod/plugins.ini && \
    rm -rf /tmp/revoice /tmp/revoice.zip

RUN curl -sLO https://jukivili.kapsi.fi/web/jk_botti/jk_botti-1.43-release.tar.xz \
    && tar -xf jk_botti-1.43-release.tar.xz -C /opt/steam/hlds \
    && echo 'linux addons/jk_botti/dlls/jk_botti_mm_i386.so' >> /opt/steam/hlds/cstrike/addons/metamod/plugins.ini

COPY maps /opt/steam/hlds/cstrike
COPY configs/server.cfg /opt/steam/hlds/cstrike/server.cfg
COPY configs/motd.txt /opt/steam/hlds/cstrike/motd.txt
COPY configs/motd.jpg /opt/steam/hlds/cstrike/motd.jpg
COPY configs/steamcomm.lst /opt/steam/hlds/valve/steamcomm.lst
COPY configs/maps.ini /opt/steam/hlds/cstrike/addons/amxmodx/configs/maps.ini
COPY configs/maps.ini /opt/steam/hlds/cstrike/mapcycle.txt
COPY lib/reapi_parachute_mute/cstrike /opt/steam/hlds/cstrike
COPY configs/plugins.ini /opt/steam/hlds/cstrike/addons/amxmodx/configs/plugins.ini
COPY configs/users.ini /opt/steam/hlds/cstrike/addons/amxmodx/configs/users.ini

RUN sed -i "s/TIMEOUT=10/TIMEOUT=1/" /opt/steam/hlds/hlds_run

COPY kickstart.sh /kickstart.sh


RUN mkdir -p /root/.steam/sdk32/ && \
    cp /opt/steam/hlds/steamclient.so /root/.steam/sdk32/steamclient.so

RUN sed -i "s/imessage.amxx/;imessage.amxx/g" /opt/steam/hlds/cstrike/addons/amxmodx/configs/plugins.ini
RUN sed -i "s/scrollmsg.amxx/;scrollmsg.amxx/g" /opt/steam/hlds/cstrike/addons/amxmodx/configs/plugins.ini
COPY lib/gravity/cstrike /opt/steam/hlds/cstrike
COPY lib/speed/cstrike /opt/steam/hlds/cstrike

WORKDIR /opt/steam/hlds
ENTRYPOINT /kickstart.sh
