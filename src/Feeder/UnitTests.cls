Class Feeder.UnitTests
{

ClassMethod Setup(pFiles As %String = 1) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - Setup - pFiles = "_pFiles)
	Set tSC = $$$OK
	Set myNamespace = $Namespace
	Set $Namespace = "%SYS"
	Set ^SYS("Security","CSP","AllowPrefix","/csp/feeder/","%UnitTest.") = 1
	//Set ^SYS("Security","CSP","AllowPrefix","/csp/healthshare/feeder/","%UnitTest.") = 1
	Set $Namespace = myNamespace
	Set ^myUnitTestControl("Files") = pFiles
	Set ^myUnitTestControl("Production") = "Feeder.FeederProduction"
	Set tCodeClassName = $Get(^myFeeder("Config","CodeClassName"),"Feeder.UnitTestHelper")
	Set tCodeClassMethod = $Get(^myFeeder("Config","CodeClassMethod"),"ACopy")
	Set tSC = $ClassMethod(tCodeClassName,tCodeClassMethod,pFiles)
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - Setup is done")
	Quit tSC
}

ClassMethod CCS(
	pFiles As %String = 1,
	pPort As %Integer = 2022) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - CCS")

	Set ^myFeeder("Config","CodeClassName") = "User.DLATest"
	Set ^myFeeder("Config","CodeClassMethod") = "CopyFilesCCS"

	Set tSC = ..Setup(pFiles)
	//Set ^myUnitTestControl("Server") = ##class(Feeder.Util).whichLoadBalancer()
	//Set ^myUnitTestControl("URL") = ##class(Feeder.Util).whichURL()
	//Set ^myUnitTestControl("Port") = pPort
	Set ^myUnitTestControl("Files") = pFiles
	Set ^UnitTestRoot = ""
	Do ##class(Feeder.TestProduction).Run()
	Kill ^myUnitTestControl
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - CCS is done")
	Quit $$$OK
}

ClassMethod FSC(
	pFiles As %String = 1,
	pPort As %Integer = 52773) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - FSC")

	Set ^myFeeder("Config","CodeClassName") = "User.FSCTest"
	Set ^myFeeder("Config","CodeClassMethod") = "CopyFiles"

	Set tSC = ..Setup(pFiles)
	//Set ^myUnitTestControl("Server") = ##class(Feeder.Util).whichLoadBalancer()
	//Set ^myUnitTestControl("URL") = ##class(Feeder.Util).whichURL()
	//Set ^myUnitTestControl("Port") = pPort
	Set ^myUnitTestControl("Files") = pFiles
	Set ^UnitTestRoot = ""
	Do ##class(Feeder.TestProduction).Run()
	Kill ^myUnitTestControl
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - FSC is done")
	Quit $$$OK
}

/// Use "CC" for pFiles to test CCS
ClassMethod HealthTest(pFiles As %String = 1) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - HealthTest")
	Set tSC = ..Setup(pFiles)
	Set tSC = ##class(Feeder.Util).GetContainerArray(.tIRIS)
	Merge ^myUnitTestControl("IRIS") = tIRIS
	Set tIRIS = ""
	For {
		Set tIRIS = $Order(^myUnitTestControl("IRIS",tIRIS),1,tTarget)
		If (tIRIS = "") Quit
		Set ^myUnitTestControl("Server") = $Piece(tTarget,":",1)
		Set ^myUnitTestControl("Port") = $Piece(tTarget,":",2)
		Set ^UnitTestRoot = ""
		Do ##class(Feeder.TestProduction).Run()
	}
	Kill ^myUnitTestControl
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - HealthTest is done")
	Quit $$$OK
}

ClassMethod LBTest(
	pFiles As %String = 1,
	pPort As %Integer = 52773) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - LBTest")
	Set tSC = ..Setup(pFiles)
	Set ^myUnitTestControl("Server") = ##class(Feeder.Util).whichLoadBalancer()
	Set ^myUnitTestControl("URL") = ##class(Feeder.Util).whichURL()
	Set ^myUnitTestControl("Port") = pPort
	Set ^myUnitTestControl("Files") = pFiles
	Set ^UnitTestRoot = ""
	Do ##class(Feeder.TestProduction).Run()
	Kill ^myUnitTestControl
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - LBTest is done")
	Quit $$$OK
}

ClassMethod POC(
	pFiles As %String = 1,
	pPort As %Integer = 52773) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - POC")

	Set ^myFeeder("Config","CodeClassName") = "Feeder.POC"
	Set ^myFeeder("Config","CodeClassMethod") = "CopyFiles"

	Set tSC = ..Setup(pFiles)
	//Set ^myUnitTestControl("Server") = ##class(Feeder.Util).whichLoadBalancer()
	//Set ^myUnitTestControl("URL") = ##class(Feeder.Util).whichURL()
	//Set ^myUnitTestControl("Port") = pPort
	Set ^myUnitTestControl("Files") = pFiles
	Set ^UnitTestRoot = ""
	Do ##class(Feeder.TestProduction).Run()
	Kill ^myUnitTestControl
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - POC is done")
	Quit $$$OK
}

ClassMethod POU(
	pFiles As %String = 1,
	pPort As %Integer = 52773) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - POU")

	Set ^myFeeder("Config","CodeClassName") = "Feeder.POU"
	Set ^myFeeder("Config","CodeClassMethod") = "CopyFiles"

	Set tSC = ..Setup(pFiles)
	//Set ^myUnitTestControl("Server") = ##class(Feeder.Util).whichLoadBalancer()
	//Set ^myUnitTestControl("URL") = ##class(Feeder.Util).whichURL()
	//Set ^myUnitTestControl("Port") = pPort
	Set ^myUnitTestControl("Files") = pFiles
	Set ^UnitTestRoot = ""
	Do ##class(Feeder.TestProduction).Run()
	Kill ^myUnitTestControl
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - POU is done")
	Quit $$$OK
}

/// When using DebugRunTestCase, mytests directory need not actually contain MyPackage.Tests.
/// By contrast RunTest always requires that the test to be executed be contained in a subdirectory of ^UnitTestRoot even when using “/noload”.
ClassMethod Init(pFiles As %String = 1) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - Init")
	Set tSC = ..Setup(pFiles)
	//Set ^UnitTestRoot = "/opt/unittests/"
	//Do ##class(%UnitTest.Manager).RunTest("mytests")
	//Do ##class(%UnitTest.Manager).RunTest("mytests:MyPackage.Tests")
	//Do ##class(%UnitTest.Manager).RunTest("mytests:MyPackage.Tests", "/noload/nodelete")
	//
	//Do ##class(%UnitTest.Manager).DebugRunTestCase("mytests","Oliver.TestCase","","")
	//
	Set ^myUnitTestControl("Files") = pFiles
	Set ^UnitTestRoot = ""
	Do ##class(Feeder.TestProduction).Run()
	Kill ^myUnitTestControl
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - Init is done")
	Quit $$$OK
}

/// Initiate Windows TestProduction
ClassMethod InitWin() As %Status
{
	Set tSC = ..Setup(pFiles)
	//Set ^UnitTestRoot = "C:\unittests"
	//Do ##class(%UnitTest.Manager).RunTest("mytests")
	//Do ##class(%UnitTest.Manager).RunTest("mytests:MyPackage.Tests")
	//Do ##class(%UnitTest.Manager).RunTest("mytests:MyPackage.Tests", "/noload/nodelete")
	//
	//Do ##class(%UnitTest.Manager).DebugRunTestCase("mytests","Oliver.TestCase","","")
	//
	//
	Set ^UnitTestRoot = ""
	//Do ##class(UnitTest.Win.TestProduction1).Run()
	Quit $$$OK
}

}
