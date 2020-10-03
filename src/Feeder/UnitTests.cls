Class Feeder.UnitTests
{

/// Use "CC" for pFiles to test CCS
ClassMethod HealthTest(pFiles As %String = 1) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - HealthTest")
	Set myNamespace = $Namespace
	Set $Namespace = "%SYS"
	Set ^SYS("Security","CSP","AllowPrefix","/csp/dmlss_hc/","%UnitTest.")=1
	Set ^SYS("Security","CSP","AllowPrefix","/csp/healthshare/dmlss_hc/","%UnitTest.")=1
	Set $Namespace = myNamespace
	Set ^myUnitTestControl("Files") = pFiles
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
	Quit $$$OK
}

ClassMethod LBTest(pFiles As %String = 1, pPort As %Integer = 52773) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - LBTest")
	Set myNamespace = $Namespace
	Set $Namespace = "%SYS"
	Set ^SYS("Security","CSP","AllowPrefix","/csp/dmlss_hc/","%UnitTest.")=1
	Set ^SYS("Security","CSP","AllowPrefix","/csp/healthshare/dmlss_hc/","%UnitTest.")=1
	Set $Namespace = myNamespace
	Set ^myUnitTestControl("Server") = ##class(Feeder.Util).whichLoadBalancer()
	Set ^myUnitTestControl("URL") = ##class(Feeder.Util).whichURL()
	Set ^myUnitTestControl("Port") = pPort
	Set ^myUnitTestControl("Files") = pFiles
	Set ^UnitTestRoot = ""
	Do ##class(Feeder.TestProduction).Run()
	Kill ^myUnitTestControl
	Quit $$$OK
}

/// When using DebugRunTestCase, mytests directory need not actually contain MyPackage.Tests.
/// By contrast RunTest always requires that the test to be executed be contained in a subdirectory of ^UnitTestRoot even when using “/noload”.
ClassMethod Init(pFiles As %String = 1) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - Init")
	Set myNamespace = $Namespace
	Set $Namespace = "%SYS"
	Set ^SYS("Security","CSP","AllowPrefix","/csp/dmlss_hc/","%UnitTest.")=1
	Set ^SYS("Security","CSP","AllowPrefix","/csp/healthshare/dmlss_hc/","%UnitTest.")=1
	Set $Namespace = myNamespace
	//Set ^UnitTestRoot = "/opt/unittests/"
	//Do ##class(%UnitTest.Manager).RunTest("mytests")
	//Do ##class(%UnitTest.Manager).RunTest("mytests:MyPackage.Tests")
	//Do ##class(%UnitTest.Manager).RunTest("mytests:MyPackage.Tests", "/noload/nodelete")
	//
	//Do ##class(%UnitTest.Manager).DebugRunTestCase("mytests","Oliver.TestCase","","")
	//
	//
	Set ^myUnitTestControl("Files") = pFiles
	Set ^UnitTestRoot = ""
	Do ##class(Feeder.TestProduction).Run()
	Kill ^myUnitTestControl
	Quit $$$OK
}

/// Initiate Windows TestProduction
ClassMethod InitWin() As %Status
{
	Set myNamespace = $Namespace
	Set $Namespace = "%SYS"
	Set ^SYS("Security","CSP","AllowPrefix","/csp/dmlss_hc/","%UnitTest.")=1
	Set ^SYS("Security","CSP","AllowPrefix","/csp/healthshare/dmlss_hc/","%UnitTest.")=1
	Set $Namespace = myNamespace
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

/// Lock File only works if File Permissions are 766 in IRIS container
ClassMethod CopyCCS() As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.UnitTests - CopyCCS")
	Set pFile = "/ICS/testfiles/ccstest/ccssamples/CCS.12312019065821_2019-12-31"
	// Only ONE dot or period allowed in Filename for Semaphore detection *** //
	Set path = "/ICS/dmlss/creditcard/ccsIncoming/"
	Set pTarget = path _ "CCS_12312019065821_2019-12-31.txt"
	Set ^TEST(^TEST,"from1") = pFile
	Set ^TEST(^TEST,"to1") = pTarget
	Set tZF1 = $ZF(-1,"cp -p "_pFile_" "_pTarget)  // -p Preserves Permissions
	Set ^TEST(^TEST,"CopyCCS1") = tZF1
	Set pFile = "/ICS/testfiles/semaphore/semaphore"
	Set pTarget = path _ "CCS_12312019065821_2019-12-31.sem"
	Set ^TEST(^TEST,"from2") = pFile
	Set ^TEST(^TEST,"to2") = pTarget
	Set tZF2 = $ZF(-1,"cp -p "_pFile_" "_pTarget)  // -p Preserves Permissions
	Set ^TEST(^TEST,"CopyCCS2") = tZF2
	Quit ((tZF1 + tZF2) = 0)
}

ClassMethod CopyFiles(pFrom As %String = "", pTo As %String = "", ByRef pFiles As %String = "") As %Status
{
	Do ##class(Feeder.Util).DebugTEST("CopyFiles")
	Set tSC = $$$OK
	Set pathTest = "/ICS/testfiles/"
	Set file1 = "IVA*"
	Set path = "/tmp/"
	Set prefix = ""
	If (pFrom = "") Set pFrom = pathTest_file1
	If (pTo = "") Set pTo = path
	Set tSC = ##class(Feeder.Util).FileSet(.pFileList,path,file1)
	Set pCount = pFileList.Size
	Write pCount_" matching file(s) in "_path,!
	If pCount {
		Do ##class(Feeder.Util).DebugTEST("path = "_path)
		Do ##class(Feeder.Util).DebugTEST("file1 = "_file1)
		Do ##class(Feeder.Util).DebugTEST(pCount_" matching file(s)")
		Quit $$$OK
	}
	;
	If +pFiles {
		Set tSC = ..TgenFiles(pFiles)
		Quit tSC
	}
	Quit tSC
	;
	Set tSC = ##class(Feeder.Util).FileSet(.pFileList,pathTest,file1)
	//zw pFileList
	Set pCount = pFileList.Size
	Write pCount_" matching file(s) in "_pathTest,!
	Do ##class(Feeder.Util).DebugTEST(pCount_" matching file(s)")
	Do ##class(Feeder.Util).DebugTEST("cp -p "_pFrom_" "_pTo)
	Set tZF = $ZF(-1,"cp -p "_pFrom_" "_pTo)
	Do ##class(Feeder.Util).DebugTEST("Result = "_tZF_" (0 is good)")
	Quit (tZF = 0)
}

ClassMethod CopyFileWin(pFrom As %String = "", pTo As %String = "") As %Status
{
	Set ^TEST($I(^TEST)) = "CopyFileWin"
	Set pDeleteBeforeCopy = 0
	Set ^TEST(^TEST,"from") = pFrom
	Set ^TEST(^TEST,"to") = pTo
	Set boolCopyFile = ##class(%File).CopyFile(pFrom, pTo, pDeleteBeforeCopy, .returnInteger)
	Set ^TEST(^TEST,"boolCopyFile") = boolCopyFile
	Quit (boolCopyFile = 1)
}

ClassMethod FilesCount(pFlag As %String = "") As %Integer
{
	Set filespec = "*"
	Set tDirCRD = "/ICS/dmlss/crd/crdProcessed/"
	Set tDirFAM = "/ICS/dmlss/fam/famProcessed/"
	Set tDirFMS = "/ICS/dmlss/fms/fmsProcessed/"
	Set pCount = $Get(pCount,0) + ##class(Feeder.Util).GetFilesCount(tDirCRD,filespec)
	Set pCount = $Get(pCount,0) + ##class(Feeder.Util).GetFilesCount(tDirFAM,filespec)
	Set pCount = $Get(pCount,0) + ##class(Feeder.Util).GetFilesCount(tDirFMS,filespec)
	Quit pCount
}

ClassMethod FilesMonitor() As %Status
{
	Lock ^TESTFilesMonitor:1
	If '$TEST { Write "Already Running",! Quit $$$OK }
	Set tStartH = $Horolog
	Set ^TESTFilesMonitor("GO") = tStartH
	Set tStartTimeH = $Piece(tStartH,",",2)
	Set tStartSecond = tStartTimeH # 60
	Set tDelta = "undefined"
	Set tFirstLoop = 1
	For {
		Set tData = $Get(^TESTFilesMonitor("GO"),"NULL")
		If ("Qq" [ $Extract(tData,1)) { Quit }
		Set tHH = $Horolog
		Set tTimeH = $Piece(tHH,",",2)
		Set tSecond = tTimeH # 60
		If (tSecond = tStartSecond) {
			Set tFilesCount = ..FilesCount()
			If 'tFirstLoop { 
				Set tDelta = tFilesCount - $Get(tFilesCountPrior)
				Set tData = $Get(^TESTFilesMonitor("DELTA",tDelta))
				Set ^TESTFilesMonitor("DELTA",tDelta) = $Increment(tData)
			}
			If tFirstLoop { Set tFirstLoop = 0 }
			Set tIncrement = 0 - $Increment(^TESTFilesMonitor)
			Set ^TESTFilesMonitor(tIncrement) = $ZDateTime($NOW(),8,1,3)_" : "_tFilesCount_" : "_$Get(tDelta)
			Set tFilesCountPrior = tFilesCount
		}
		Hang 1
		Continue
	}
	LOCK  // Release all locks
	Quit $$$OK
}

ClassMethod LostAndFound() As %Integer
{
	Set tCount = 0
	Set tNode = $Get(pNode)
	For {
		Set tNode = $Order(^HS.Local.VFC75.LostFilesDLA(tNode))
		If tNode = "" Quit
		Set tQQ = ""
		For {
			Set tQQ = $Order(^HS.Local.VFC75.LostFilesDLA(tNode,tQQ))
			If tQQ = "" Quit
			Set tFilePath = ""
			For {
				Set tFilePath = $Order(^HS.Local.VFC75.LostFilesDLA(tNode,tQQ,tFilePath))
				If tFilePath = "" Quit
				Set tFilename = ""
				For {
					Set tFilename = $Order(^HS.Local.VFC75.LostFilesDLA(tNode,tQQ,tFilePath,tFilename))
					If tFilename = "" Quit
					Set tSC = ##class(%File).Exists(tFilePath_tFilename)
					Write tSC,"  ",tFilePath_tFilename,!
					If tSC { Set tCount = tCount + 1 }
					// Lookup ConfigItem based on Filename
					Set tConfig = ""
					If (tFilename ? 1"IVAFMS-ET".E) {
						Set tConfig = "ETfromDMLSS"
						Set tPath = "/ICS/dmlss/fms/fmsProcessed/"
					} ElseIf (tFilename ? 1"IVAFMS-FA".E) {
						Set tConfig = "FAfromDMLSS"
						Set tPath = "/ICS/dmlss/fam/famProcessed/"
					} ElseIf (tFilename ? 1"IVARR-INRR".E) {
						Set tConfig = "FedRRfromDMLSS"
						Set tPath = "/ICS/dmlss/crd/crdProcessed/"
					} ElseIf (tFilename ? 1"IVARR-IFRR".E) {
						Set tConfig = "NonFedRRfromDMLSS"
						Set tPath = "/ICS/dmlss/crd/crdProcessed/"
					} Else {
						Set tConfig = "MOfromDMLSS"
						Set tPath = "/ICS/dmlss/fms/fmsProcessed/"
					}
					Set pCount = ##class(Feeder.Util).GetFilesCount(tPath,tFilename_"*")
				}
			}
		}
	}
	//Set ^HS.Local.VFC75.LostFilesDLA(pNode,pSequence,pFilePath,pFilename) = $H
	Quit tSC
}

ClassMethod ResetDirectory(pFiles As %String = "") As %Status
{
	Set filespec = "*"
	Set tDirCRD = "/ICS/dmlss/crd/crdProcessed/"
	Set tDirFAM = "/ICS/dmlss/fam/famProcessed/"
	Set tDirFMS = "/ICS/dmlss/fms/fmsProcessed/"
	Set status = $ZF(-100,"/SHELL", "rm -f "_tDirCRD, filespec)
	//-bash: /usr/bin/rm: Argument list too long
	Write "Delete status: ",status,!
	Write "Checking Directories after Reset:",!
	Set pCount = ..FilesCount(pFiles)
	Quit $$$OK
}

ClassMethod ResetDLA() As %Status
{
	Set tFC = ..FilesCount()
	If (tFC = 0) { Quit $$$OK }
	Write "Files Count = ",tFC,!
	Job ##class(Feeder.UnitTests).ResetFiles(1)
	Job ##class(Feeder.UnitTests).ResetFiles(2)
	Job ##class(Feeder.UnitTests).ResetFiles(3)
	Job ##class(Feeder.UnitTests).ResetFiles(4)
	Job ##class(Feeder.UnitTests).ResetFiles(5)
	Quit $$$OK
}

ClassMethod ResetFiles(pFlag As %String = "") As %Status
{
	Do ##class(Feeder.Util).DebugTEST("ResetFiles("_pFlag_")")
	Set filespec = "*"
	Set tDirCRD = "/ICS/dmlss/crd/crdProcessed/"
	Set tDirFAM = "/ICS/dmlss/fam/famProcessed/"
	Set tDirFMS = "/ICS/dmlss/fms/fmsProcessed/"
	If (pFlag = 1) {
		Set pPath = tDirCRD
		Set pFiles = "IVARR-IFRR*"
	}
	If (pFlag = 2) {
		Set pPath = tDirCRD
		Set pFiles = "IVARR-INRR*"
	}
	If (pFlag = 3) {
		Set pPath = tDirFAM
		Set pFiles = "IVAFMS-FA*"
	}
	If (pFlag = 4) {
		Set pPath = tDirFMS
		Set pFiles = "IVAFMS-ET*"
	}
	If (pFlag = 5) {
		Set pPath = tDirFMS
		Set pFiles = "IVAFMS-MO*"
	}
	If ($Get(pPath) = "") || ($Get(pFiles) = "") { Quit $$$OK }
	Set tFileSet = ##class(%ResultSet).%New("%File:FileSet")
	Do tFileSet.%Execute(pPath,pFiles)
	While tFileSet.%Next() {
		If tFileSet.Type="D" { Continue }  // Skip Directories
		Set tDelete = ##class(%File).Delete(tFileSet.Name,.pOutput)
		If tDelete { Continue }

		Set tFile = ##class(%File).GetFilename(tFileSet.Name)
		Write tFile,!
		zw pOutput
		If 'tDelete { Quit }  // Quit on Error
	}
	Do ##class(Feeder.Util).DebugTEST("ResetFiles("_pFlag_") done")
	Quit $$$OK
}

/// Generate Test Files
ClassMethod TgenFiles(pCount As %String = 1) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("TgenFiles")
	Set pTarget = "/tmp/"
	Set tPath = "/tmp/"
	// Check Exists //
	If ##class(%File).Exists("/ICS/testgen/") Set tPath = "/ICS/testgen/"  // AWS
	If ##class(%File).Exists("/srv/hs/db/data/testgen/") Set tPath = "/srv/hs/db/data/testgen/"  // CRRC
	Set tScript1 = "et.sh"
	Set tScript2 = "fa.sh"
	Set tScript3 = "ifrr.sh"
	Set tScript4 = "inrr.sh"
	Set tScript5 = "mo.sh"
	Set tDate = "random" // or date YYYYMMDD
	Set tCMD = tPath_tScript1_" "_pCount_" "_tDate_" "_pTarget_" "_tPath
	Do ##class(Feeder.Util).DebugTEST(tCMD)
	Set tZF = $ZF(-1,tCMD)
	Do ##class(Feeder.Util).DebugTEST("Result = "_tZF_" (0 is good)")
	If (tZF '= 0) Quit 0
	Set tCMD = tPath_tScript2_" "_pCount_" "_tDate_" "_pTarget_" "_tPath
	Do ##class(Feeder.Util).DebugTEST(tCMD)
	Set tZF = $ZF(-1,tCMD)
	Do ##class(Feeder.Util).DebugTEST("Result = "_tZF_" (0 is good)")
	If (tZF '= 0) Quit 0
	Set tCMD = tPath_tScript3_" "_pCount_" "_tDate_" "_pTarget_" "_tPath
	Do ##class(Feeder.Util).DebugTEST(tCMD)
	Set tZF = $ZF(-1,tCMD)
	Do ##class(Feeder.Util).DebugTEST("Result = "_tZF_" (0 is good)")
	If (tZF '= 0) Quit 0
	Set tCMD = tPath_tScript4_" "_pCount_" "_tDate_" "_pTarget_" "_tPath
	Do ##class(Feeder.Util).DebugTEST(tCMD)
	Set tZF = $ZF(-1,tCMD)
	Do ##class(Feeder.Util).DebugTEST("Result = "_tZF_" (0 is good)")
	If (tZF '= 0) Quit 0
	Set tCMD = tPath_tScript5_" "_pCount_" "_tDate_" "_pTarget_" "_tPath
	Do ##class(Feeder.Util).DebugTEST(tCMD)
	Set tZF = $ZF(-1,tCMD)
	Do ##class(Feeder.Util).DebugTEST("Result = "_tZF_" (0 is good)")
	If (tZF '= 0) Quit 0
	Quit (tZF = 0)
}

}
