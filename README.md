## Feeder
This solution contains an InterSystems IRIS Interoerability Production for sending test messages.

## Enhanced for Interoperability Contest
Specify code to use to generate test files from Feeder Cache Server Page

## Extra: File Adapters to allow multiple IRIS instances to process files in shared directories.

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
<img width="1411" alt="Screenshot of Production" src="https://user-images.githubusercontent.com/50807396/99205087-1f08d580-277d-11eb-993a-aeda6154accf.PNG">
Link to the Feeder Cache Server Page here: http://localhost:52773/feederapp/Feeder.csp
You need to replace localhost with the ip address if the Feeder runs on a remote server. Change the port number if you use a different port.
<img width="1411" alt="Screenshot of Production" src="https://user-images.githubusercontent.com/50807396/99205069-144e4080-277d-11eb-9716-be7de5198706.PNG">


## What's inside the repository

### Dockerfile

The simplest dockerfile which starts IRIS and imports Installer.cls and then runs the Installer.setup method, which creates IRISAPP Namespace and imports ObjectScript code from /src folder into it.
Use the related docker-compose.yml to easily setup additional parameters like port number and where you map keys and host folders.
Use .env/ file to adjust the dockerfile being used in docker-compose.


## Why is there a Feeder?
[Article](https://community.intersystems.com/post/file-passthrough-feeder)

## Why are there new File Adapters in Feeder 2.0?
Explanation coming soon
