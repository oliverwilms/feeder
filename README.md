## Feeder
This solution contains an InterSystems IRIS Interoerability Production for sending test messages.

## Enhanced for Interoperability Contest
The production has new BusinessProcessBPL process to automatically import CSV files using [csvgen](https://openexchange.intersystems.com/package/csvgen).
<img width="1411" alt="Screenshot of BusinessProcessBPL" src="https://user-images.githubusercontent.com/50807396/99479975-d1c36a00-291c-11eb-8c3e-728c20c02caa.png">

## Extra: File Adapters to allow multiple IRIS instances to process files in shared directories.
[Article](https://community.intersystems.com/post/file-access-control-inbound-adapter-running-multiple-iris-instances)
## How I use the Feeder
I want to describe how I use Feeder at work: I update the Dockerfile to use a non-Community Edition IRIS image. I copy iris.key into current directory and add "--key /voldata/iris.key" to the command in docker-compose.yml to activate my license key. I update iris.script because I do not have ZPM and I do not need csvgen. (I just added it to get a bonus point for BPL usage.)

I will continue to describe my usage of Feeder as time allows...

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
If you are prompted to login, use "_SYSTEM" for username and the default password is "SYS".
USER>zn "FEEDER"
FEEDER>write ##class(Feeder.Util).TestMethod()
You should see the following output:
Your Feeder is ready.
1
```
## Use it
<img width="1411" alt="Screenshot of Production" src="https://user-images.githubusercontent.com/50807396/99479986-d5ef8780-291c-11eb-9075-7fa24bf3aa8c.png">
You can use the Feeder from the Terminal command line or control it from the Feeder Cache Server Page here: http://localhost:52773/feederapp/Feeder.csp
You need to replace localhost with the ip address if the Feeder runs on a remote server. Change the port number if you use a different port.
We can specify code to use to generate test files from Feeder Cache Server Page. 
<img width="1411" alt="Screenshot of Feeder Cache Server Page" src="https://user-images.githubusercontent.com/50807396/99205069-144e4080-277d-11eb-9716-be7de5198706.PNG">


## What's inside the repository

### Dockerfile

Dockerfile defines the InterSystems IRIS image to use, starts IRIS, imports Installer.cls, and runs the Installer.setup method, which creates FEEDER Namespace and imports ObjectScript code from /src folder into it.
Use the related docker-compose.yml to easily setup additional parameters like port number and where you map keys and host folders.
You may use .env/ file to adjust the dockerfile being used in docker-compose.

### Feeder.UnitTests.cls

You can execute the following Tests from Terminal (IRIS session):


## Why is there a Feeder?
[Article](https://community.intersystems.com/post/file-passthrough-feeder)

## Why are there new File Adapters in Feeder 2.0?
[Article](https://community.intersystems.com/post/file-access-control-inbound-adapter-running-multiple-iris-instances)

