## Feeder
This solution contains an InterSystems IRIS Interoerability Production for sending test messages.

## Why is there a Feeder?
[Article](https://community.intersystems.com/post/file-passthrough-feeder)

## What else can Feeder do?
[Article](https://community.intersystems.com/post/what-else-can-feeder-do)

## Test Report
Open IRIS terminal:

```
$ docker-compose exec iris iris session iris
If you are prompted to login, use "_SYSTEM" for username and the default password is "SYS".
USER>zn "FEEDER"
FEEDER>do ##class(Feeder.TestReport).Go()
UnitTest 4 began 2020-11-22 15:28:56.454
  It sent 5 messages between 15:28:56.509 and 15:28:56.531 (227.273 mps)
    to internal-sqa-iris-app-alb-123456789.us-gov-west-1.elb.amazonaws.com:52773
/restapi/UploadFile/
  4 responses were 200 / OK
  1 responses were 404 / Not Found
  MsgBk before: 0 - after: 0
    0 messages banked

```
## Enhanced for Interoperability Contest
The production has new BusinessProcessBPL process to automatically import CSV files using [csvgen](https://openexchange.intersystems.com/package/csvgen).
<img width="1411" alt="Screenshot of BusinessProcessBPL" src="https://user-images.githubusercontent.com/50807396/99479975-d1c36a00-291c-11eb-8c3e-728c20c02caa.png">

## Extra: File Adapters to allow multiple IRIS instances to process files in shared directories.
[Article](https://community.intersystems.com/post/file-access-control-inbound-adapter-running-multiple-iris-instances)
## How I use the Feeder
I want to describe how I use Feeder at work: I update the Dockerfile to use a non-Community Edition IRIS image. I copy iris.key into current directory and add "--key /voldata/iris.key" to the command in docker-compose.yml to activate my license key. I update iris.script because I do not have ZPM and I do not need csvgen. (I just added it to get a bonus point for BPL usage.)

The application I use the Feeder to send test messages to accepts HTTP requests and some files are received via FTP. I started the Feeder with a CSP Operation that simulates the HTTP requests. Later on I added a way to copy files to specific file path that simulates the files received via FTP. My target InterSystems Operability Production has various File Services to process the files. I will continue to describe my usage of Feeder as time allows...

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
You can control the Feeder from the command line or from the Feeder Cache Server Page here: http://localhost:52773/feederapp/Feeder.csp
You need to replace localhost with the ip address if the Feeder runs on a remote server. Change the port number if you use a different port.
We can specify code to use to generate test files from Feeder Cache Server Page. 
<img width="1411" alt="Capture_Feeder_CSP" src="https://user-images.githubusercontent.com/50807396/99889597-56afcb80-2c1c-11eb-9420-90b70cfbbb74.PNG">
After the data is submitted on CSP page, it is saved in ^myFeeder global pictured below:
<img width="1411" alt="Capture_myFeeder_Global" src="https://user-images.githubusercontent.com/50807396/99889821-5ca6ac00-2c1e-11eb-80d5-b294a98b75b5.PNG">

## What's inside the repository

### Dockerfile

Dockerfile defines the InterSystems IRIS image to use, starts IRIS, imports Installer.cls, and runs the Installer.setup method, which creates FEEDER Namespace and imports ObjectScript code from /src folder into it.
Use the related docker-compose.yml to easily setup additional parameters like port number and where you map keys and host folders.
You may use .env/ file to adjust the dockerfile being used in docker-compose.

### Feeder.UnitTests.cls
I created Feeder UnitTests class to Run Feeder.TestProduction, which extends %UnitTest.TestProduction, which tests a Production using the following steps. It starts the production (Feeder.FeederProduction), waits a certain time, stops the production, and checks results. I am not really interested in testing FeederProduction, instead I use it to send test messages to another production and then check the results of test messages processed in the target production. This is especially handy if the target production runs in multiple containers and it would be cumbersome to check each instance for messages, event logs, etc.

I mainly use two methods, HealthTest and LBTest. HealthTest is intended to be used for checking the health of known IRIS instances by sending messages directly to an instance. LBTest is intended to be used for testing a deployment by sending messages to a load balancer which distributes messages for processing. HealthTest depends on IRIS instances being defined, which I hardcoded in Feeder.Util class (GetContainerArray). I like to some day enhance Feeder.csp to allow configuration of IRIS instances similar to how Enterprise Systems get configured in Management Portal.

Let's take a look at LBTest classmethod. It calls common Setup method, sets ^myUnitTestControl with values pointing to the Load Balancer, runs Feeder.TestProduction, and kills ^myUnitTestControl. Setup method controls what code gets executed to generate test messages and how many messages it should generate. You can configure Feeder to use any URL, it does not need to be a Load Balancer.

```
$ docker-compose exec iris iris session iris
If you are prompted to login, use "_SYSTEM" for username and the default password is "SYS".
USER>zn "FEEDER"
FEEDER>write ##class(Feeder.UnitTests).LBTest()
You will see output

```
### Feeder.UnitTestHelper.cls
Classmethod CopyCCS copies a datafile and a semaphore file to a directory on a shared file system - ICS can stand for IRIS Cloud Storage - for processing by the IRIS Interoperabilty Production I am redesigning for deployment using containers in AWS.
When I send test messages through FeederProduction's CSP Operation via HTTP requests to the targeted Interoperabilty Production, it places files in three directories to be sent to downstream systems which are not connected yet. There is a classmethod FilesMonitor which can be jobbed as a background job - JOB ##class(Feeder.UnitTestHelper).FilesMonitor() - and it updates a global with the count of files it finds in the watched directories once a minute. This provides a way to see how many files are processed per minute from a Global Viewer as pictured below:
<img width="1411" alt="View Global Data" src="https://user-images.githubusercontent.com/50807396/99887849-78558680-2c0d-11eb-9713-fd6a279d9036.PNG">

I utilize the CSP Operation to send five different test file types, which end up in the watched directories, and classmethod ResetDLA can delete the files. 
