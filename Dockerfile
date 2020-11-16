ARG IMAGE=store/intersystems/iris-community:2020.1.0.204.0
ARG IMAGE=intersystemsdc/iris-community:2020.1.0.209.0-zpm
ARG IMAGE=intersystemsdc/iris-community:2020.2.0.204.0-zpm
ARG IMAGE=intersystemsdc/iris-community:2020.3.0.200.0-zpm
ARG IMAGE=intersystemsdc/irishealth-community:2020.3.0.200.0-zpm
ARG IMAGE=intersystems/irishealth:2020.1.0.215.0
FROM $IMAGE

USER root
COPY iris.key $ISC_PACKAGE_INSTALLDIR/mgr/
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /usr/irissys/mgr/iris.key
WORKDIR /opt/feeder
RUN mkdir /ghostdb/ && mkdir /voldata/ && mkdir /voldata/irisdb/ && mkdir /voldata/icsp/ && mkdir /voldata/icsp/feederapp/
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/feeder /ghostdb/ /voldata/ /voldata/irisdb/ /voldata/icsp/ /voldata/icsp/feederapp/

USER ${ISC_PACKAGE_MGRUSER}

COPY Installer.cls .
COPY csp /voldata/icsp/feederapp
COPY src src
COPY iris.script /tmp/iris.script

# run iris and initial 
RUN iris start IRIS \
    && iris session IRIS -U %SYS < /tmp/iris.script \
    && iris stop IRIS quietly

HEALTHCHECK --interval=10s --timeout=3s --retries=2 CMD wget localhost:52773/csp/user/cache_status.cxw || exit 1

USER root
COPY vcopy.sh vcopy.sh
RUN rm -f $ISC_PACKAGE_INSTALLDIR/mgr/alerts.log $ISC_PACKAGE_INSTALLDIR/mgr/IRIS.WIJ $ISC_PACKAGE_INSTALLDIR/mgr/journal/* && cp -Rpf /voldata/* /ghostdb/ && rm -fr /voldata/* \
  && chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/feeder/vcopy.sh && chmod +x /opt/feeder/vcopy.sh
