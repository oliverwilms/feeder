## Feeder
This solution contains an InterSystems IRIS Interoerability Production for sending test messages.

## Prerequisites
Make sure you have [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) and [Docker desktop](https://www.docker.com/products/docker-desktop) installed.

## Installation 

Clone/git pull the repo into any local directory

```
$ git clone https://github.com/oliverwilms/feeder.git
```

Open the terminal in this directory and run:

```
$ docker-compose build
```

3. Run the IRIS container with your project:

```
$ docker-compose up -d
```

## How to Test it

Open IRIS terminal:

```
$ docker-compose exec iris iris session iris
USER>zn "FEEDER"
FEEDER>write ##class(Feeder.Util).TestMethod()
```
## File Passthrough Feeder
IRIS Interoperability Productions formerly known as Ensemble are fun to work with. Yes, I really think my work is fun. I have seen File Passthrough Services and File Passthrough Operations come in handy. At one point we placed test messages in files, then we utilized a File Passthrough Service with Inbound File Adapter to send the contents of the file as a Stream to a File Passthrough Operation with Outbound TCP Adapter. The Operation pointed at a TCP service and sent the test messages.

Later I wanted to troubleshoot another service that received file contents as the body of HTTP requests. I created CSPOperation to send contents of files as HTTP requests to the CSP page that was responsible to receive these messages.

I discovered %UnitTest.TestProduction class that provides a structured way to test Interoperability Productions and organize test results.

When I started working with containers, I used my Feeder Production to send test messages to Application Load Balancer or directly to one container. I added test file creation scripts and generated test files before each Unit Test. I created REST API to query IRIS instances running in containers for messages processed and event log entries. I captured many metrics and created TestReport class to report detailed test results.

I really enjoy putting the File Passthrough Feeder Production to work, as our development environment is not connected to anything to send test messages.

I demonstrated the setup to our greater team. Some were not impressed by the cryptic messages on the terminal from the %UnitTest.TestProduction execution. Hence for the Full Stack Contest I decided to add a CSP page to interact with the Feeder UnitTest Production.

## What's inside the repository

### Dockerfile

The simplest dockerfile which starts IRIS and imports Installer.cls and then runs the Installer.setup method, which creates IRISAPP Namespace and imports ObjectScript code from /src folder into it.
Use the related docker-compose.yml to easily setup additional parametes like port number and where you map keys and host folders.
Use .env/ file to adjust the dockerfile being used in docker-compose.

### Dockerfile-zpm

Dockerfile-zpm builds for you a container which contains ZPM package manager client so you are able to install packages from ZPM in this container.
As an example of usage in installs webterminal

### Dockerfile-web

Dockerfile-web starts IRIS does the same what Dockerfile does and also sets up the web app programmatically


### .vscode/settings.json

Settings file to let you immedietly code in VSCode with [VSCode ObjectScript plugin](https://marketplace.visualstudio.com/items?itemName=daimor.vscode-objectscript))

### .vscode/launch.json
Config file if you want to debug with VSCode ObjectScript

[Article](https://community.intersystems.com/post/file-passthrough-feeder)
