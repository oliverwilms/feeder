ARG IMAGE=store/intersystems/iris-community:2020.1.0.204.0
ARG IMAGE=intersystemsdc/iris-community:2020.1.0.209.0-zpm
ARG IMAGE=intersystemsdc/iris-community:2020.2.0.204.0-zpm
ARG IMAGE=intersystemsdc/iris-community:2020.3.0.200.0-zpm
ARG IMAGE=intersystemsdc/irishealth-community:2020.3.0.200.0-zpm
ARG IMAGE=intersystems/irishealth:2020.1.0.215.0.20264
FROM $IMAGE

USER root

WORKDIR /opt/feeder
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /opt/feeder
COPY csp /usr/irissys/csp/feeder
RUN chown ${ISC_PACKAGE_MGRUSER}:${ISC_PACKAGE_IRISGROUP} /usr/irissys/csp/feeder

USER irisowner

COPY  Installer.cls .
COPY  src src
COPY iris.script /tmp/iris.script

# run iris and initial 
RUN iris start IRIS \
    && iris session IRIS -U %SYS < /tmp/iris.script \
    && iris stop IRIS quietly

HEALTHCHECK --interval=10s --timeout=3s --retries=2 CMD wget localhost:52773/csp/user/cache_status.cxw || exit 1

USER root

RUN rm /tmp/i*
