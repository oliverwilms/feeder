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
## Use it
Configure CSP Operation
https://github.com/oliverwilms/bilder/blob/main/Capture_Feeder_CSP-Operation_Settings.PNG
Link to the Feeder Cache Server Page here: http://localhost:52773/csp/feeder/Feeder.csp
You need to replace localhost with the ip address if the Feeder runs on a remote server.

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

## Why is there a Feeder?
[Article](https://community.intersystems.com/post/file-passthrough-feeder)
