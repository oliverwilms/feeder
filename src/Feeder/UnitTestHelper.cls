Class Feeder.UnitTestHelper
{

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
