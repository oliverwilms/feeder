Class Feeder.TestProduction Extends %UnitTest.TestProduction
{

/// Class name of the production.  It must contain the production class name.
Parameter PRODUCTION = "Feeder.FeederProduction";

/// Maximum time in seconds to wait for the production to completely start or stop.  The default is 10 seconds, 
/// override if necessary.
Parameter MAXWAIT = 10;

/// Minimum time to let production run before collecting event log entries of type "infouser" and check for results. 
/// The default is 10 seconds, override if necessary.  This varies with the production; some productions only
/// need to run for a little time, and some require more time.
Parameter MINRUN = 10;

/// If any errors appear in the Event Log during execution of the production, the test will fail.
/// If errors are expected to happen, override this parameter. 
/// You may also want to check them manually by overriding the method <method>CheckErrors</method>.
Parameter IGNOREPRODUCTIONERRORS = 1;

// 1 because I want to execute method <method>CheckErrors</method>.

ClassMethod DebugMerge(strMessage As %String = "", ByRef pArray) As %Status
{
	Merge ^TESTunit($I(^TESTunit)) = pArray
	Set tValue = ""
	If $Get(pArray) '= "" Set tValue = " = "_pArray
	Set ^TESTunit(^TESTunit) = $ZDateTime($NOW(),8,1,3)_" : "_$JOB_" : "_strMessage_tValue
	Quit $$$OK
}

ClassMethod DebugTEST(strMessage As %String = "") As %Status
{
	Set ^TESTunit($I(^TESTunit)) = $ZDateTime($NOW(),8,1,3)_" : "_$JOB_" : "_strMessage
	Quit $$$OK
}

ClassMethod StatusToText(pStatus As %Status) As %String
{
	Set tReturn = $System.Status.GetOneErrorText(pStatus)
	Quit tReturn
}

ClassMethod DebugStatus(pStatus As %Status) As %Status
{
	Set tStatus = ..StatusToText(pStatus)
	Quit ..DebugTEST(tStatus)
}

/// Can set up a test environment
Method OnBeforeAllTests() As %Status
{
	Do ..DebugTEST("OnBeforeAllTests")
	Quit $$$OK
}

Method xOnBeforeOneTest()
{
	Quit
}

/// Code to run right before the production is started.  This is useful to:<br>
/// <ul><li>Adjust settings - see method <method>ChangeSetting</method>.</li>
/// <li>Create directories - see method <method>CreateMainDirTree</method>.</li>
/// <li>Copy files - see method <method>CopyFile</method>.</li>
/// <li>Create credentials required by the production - see method <method>CreateCredentials</method>.</li>
/// <li>etc.</li></ul>
/// If an error status is returned, the test will be aborted and failed.
/// So if a non fatal error occurs, you may invoke ..LogErrors(status,"OnBeforeProductionStart()") and return $$$OK.
Method OnBeforeProductionStart() As %Status
{
	Do ..DebugTEST("OnBeforeProductionStart")
	Set pFiles = $Get(^myUnitTestControl("Files"),1)
	Set pServer = $Get(^myUnitTestControl("Server"))
	Set pPort = $Get(^myUnitTestControl("Port"))
	Set pURL = $Get(^myUnitTestControl("URL"))
	Set tSC = ..ValidateConfiguration(.pServer,.pPort,.pURL)
	Do ..DebugStatus(tSC)
	Set tMessage = "Sending to "_$Get(pServer)_":"_$Get(pPort)_$Get(pURL,"/")
	Do ..LogMessage(tMessage)
	Do ..DebugTEST(tMessage)
	Do $$$AssertStatusOK(tSC,"ValidateConfiguration returned")
	Do ##class(Feeder.Util).StartUnitTest()  // Increments ^myUnitTests here
	Set tSC = ##class(Feeder.Util).GetProductionStates(pServer,pPort,pFiles)
	Set tSC = ##class(Feeder.Util).GetDocumentId(0,.pDocumentId)
	Set tSC = ##class(Feeder.Util).GetMsgBankCount(0,.pMsgBankCount)
	Set tSC = ##class(Feeder.Test).UpdateMyProp("","DocIdBefore",$Get(pDocumentId))
	Set tSC = ##class(Feeder.Test).UpdateMyProp("","MsgBkBefore",$Get(pMsgBankCount))
	Set tSC = ##class(Feeder.Test).UpdateMyProp("","TargetServer",pServer)
	Set tSC = ##class(Feeder.Test).UpdateMyProp("","TargetPort",pPort)
	Set tSC = ##class(Feeder.Test).UpdateMyProp("","TargetURL",pURL)
	If ($Extract(pFiles,1,2) = "CC") {
		Set tSC = ##class(Feeder.UnitTests).CopyCCS()
		Do $$$AssertStatusOK(tSC,"CopyCCS returned")
		Quit tSC
	}
	Set tSC = ##class(Feeder.UnitTests).CopyFiles("","",.pFiles)
	Do ..LogMessage(pFiles_" files")
	Do $$$AssertStatusOK(tSC,"CopyFiles returned")
	Quit tSC
}

/// Code to run right after the production is started. Used, for example, to call a method that initiates the test.
/// If an error status is returned, the test will be aborted and failed and the production will be stopped.
/// So if a non fatal error occurs, you may invoke ..LogErrors(status,"OnAfterProductionStart()") and return $$$OK.
Method OnAfterProductionStart() As %Status
{
	Do ..DebugTEST("OnAfterProductionStart")
	Quit $$$OK
	Set request = ##class(Ens.StringRequest).%New()
	set request.StringValue="Hello Ensemble"
	Set tSC = ..SendRequest( "Tutorial.ExampleOperation" ,request, 
                                                       .response,1,40)
	Do $$$AssertEquals(response.StringValue,"OK","Response should contain OK.")
	Set request.StringValue=""
	Set tSC = ..SendRequest( "Tutorial.ExampleOperation" ,request, 
                                                        .response,1,40)
	Quit $$$OK
}

/// Fill in with code to check the results for the production execution.<br>
/// This method is initialized with a local array containing user created entries of type "Info" from the Event Log, 
/// not including the start production/components entries, with the following contents:<br>
///   <b>Log</b> = last existing seq for array <b>Log()</b> <br>
///   <b>Log(seq, fieldname)</b> = fieldvalue<br>
/// To get other entries from the Event Log, or for more information about the array contents,
/// see method <method>GetEventLog</method>. <br>
/// Return $$$OK in most cases, or an error status if you want to indicate that there was a failure.  Remember 
/// that failures are automatic when unit test macros are used.<br>
Method CheckResults(ByRef Log As %String, New As %String) As %Status
{
	Do ..DebugTEST("CheckResults")
	Do ..DebugMerge("Log",.Log)
	Do ..DebugTEST("New = "_$Get(New))
	;
	Set tSC	= ##class(Feeder.Util).CheckMessagesThisInstance(.tMsgCount,.tBegin,.tEnd)
	Set tBeginEnd = " between "_tBegin_" and "_tEnd
	Set tVerb = "processed"
	Do ..LogMessage("This production "_$Get(tVerb,"sent")_" "_tMsgCount_" message(s)"_$Get(tBeginEnd)_".")
	Set tSC = ##class(Feeder.Test).UpdateMyProp("","myMsgBegin",tBegin)
	Set tSC = ##class(Feeder.Test).UpdateMyProp("","myMsgCount",tMsgCount)
	Set tSC = ##class(Feeder.Test).UpdateMyProp("","myMsgEnd",tEnd)
	Quit tSC
}

/// Override this method if you are going to check errors with custom code.
/// It's automatically invoked when parameter <parameter>IGNOREPRODUCTIONERRORS</parameter> = 1.
Method CheckErrors() As %Status
{
	Do ..DebugTEST("CheckErrors")
	// GetEventLog types are "error", "info", "infouser", "trace", "alert"
	Set s = ..GetEventLog("error", "", ..BaseLogId, .err, .new) // Retrieve all records of type "Error"
	Do ..DebugMerge("err",.err)
	Do ..DebugTEST("new = "_$Get(new))
	Set (s1,s2) = $$$AssertEquals(new,0,"Should be 0 new errors(found: "_+$Get(new)_")")
	Set text = $Get(err(1,"Text"))
	Set eText = "Test error case"
	//Set s2 = $$$AssertTrue(text[eText,"Should contain '"_eText_"'(found: '"_text_"')")
	Set tSC = ##class(Feeder.Test).UpdateMyProp("","myErrCount",$Get(new))
	If 's1||'s2 Set tSC=..Error("Expected error entries don't match")
	Quit tSC
}

/// Code to run right before the production is stopped.
/// If an error status is returned, the test will be failed and aborted, the production will be stopped.
/// If a non fatal error occurs, you may invoke ..LogErrors(status,"OnBeforeProductionStop()") and return $$$OK.
Method OnBeforeProductionStop() As %Status
{
	Do ..DebugTEST("OnBeforeProductionStop")
	Quit $$$OK
}

/// Code to run right after the production is stopped.
/// If an error status is returned, the test is failed.
/// If a non fatal error occurs, you may invoke ..LogErrors(status,"OnAfterProductionStop()") and return $$$OK.
Method OnAfterProductionStop() As %Status
{
	Do ..DebugTEST("OnAfterProductionStop")
	Quit $$$OK
}

/// Can tear down a test environment
Method OnAfterAllTests() As %Status
{
	Do ..DebugTEST("OnAfterAllTests")
	Set tSC = ##class(Feeder.Util).GetDocumentId(0,.pDocumentId)
	Set tSC = ##class(Feeder.Util).GetMsgBankCount(0,.pMsgBankCount)
	Set tSC = ##class(Feeder.Test).UpdateMyProp("","DocIdAfter",$Get(pDocumentId))
	Set tSC = ##class(Feeder.Test).UpdateMyProp("","MsgBkAfter",$Get(pMsgBankCount))
	Quit $$$OK
	// ..TestResultsAfterStop() and ..TestErrorsAfterStop() are automatically called
	Set tSC = ..TestResultsAfterStop()
	Set tSC = ..TestErrorsAfterStop()
	Quit $$$OK
}

/// This method is going to check message counts after Production stopped.
Method TestResultsAfterStop() As %Status
{
	Do ..DebugTEST("TestResultsAfterStop")
	Set tTargetMsgCount = 0
	Set (tTargetMsgBegin,tTargetMsgEnd) = ""
	Set tSC = ##class(Feeder.Util).CheckMessages()
	Set myUnitTest = $Get(^myUnitTests)
	If myUnitTest {
		Set pIris = ""
		For {
			Set pIris = $Order(^myUnitTests(myUnitTest,pIris))
			If pIris = "" Quit
			Set tMsgCount = $Get(^myUnitTests(myUnitTest,pIris,"MsgCount"),0)
			If tMsgCount {
				Set tBegin = $Get(^myUnitTests(myUnitTest,pIris,"Begin"),"")
				Set tEnd = $Get(^myUnitTests(myUnitTest,pIris,"End"),"")
				Do ..LogMessage(pIris_" processed "_tMsgCount_" message(s) from "_tBegin_" till "_tEnd_".")
				Set tTargetMsgCount = tTargetMsgCount + tMsgCount
				Set tDiff = $Get(^myUnitTests(myUnitTest,pIris,"DateTimeDiff"),0)
				Set tBegin = ##class(Feeder.Util).AddDateTimeDiff(tBegin,tDiff)
				If (tTargetMsgBegin = "") Set tTargetMsgBegin = tBegin
				If (##class(Feeder.Util).GetDateTimeDiff(tTargetMsgBegin,tBegin) < 0) Set tTargetMsgBegin = tBegin
				Set tEnd = ##class(Feeder.Util).AddDateTimeDiff(tEnd,tDiff)
				If (tTargetMsgEnd = "") Set tTargetMsgEnd = tEnd
				If (##class(Feeder.Util).GetDateTimeDiff(tTargetMsgEnd,tEnd) > 0) Set tTargetMsgEnd = tEnd
			}
		}
	}
	Do ..LogMessage(" IRIS processed "_tTargetMsgCount_" total message(s).")  // from "_tBegin_" till "_tEnd_".")
	Set tSC = ##class(Feeder.Test).UpdateMyProp(myUnitTest,"TargetMsgBegin",tTargetMsgBegin)
	Set tSC = ##class(Feeder.Test).UpdateMyProp(myUnitTest,"TargetMsgCount",tTargetMsgCount)
	Set tSC = ##class(Feeder.Test).UpdateMyProp(myUnitTest,"TargetMsgEnd",tTargetMsgEnd)
	Set tSC = $$$AssertNotEquals(tTargetMsgCount,0,"Total Messages Count is (not) zero.")
	Quit tSC
}

/// This method is going to check errors after Production stopped.
Method TestErrorsAfterStop() As %Status
{
	Do ..DebugTEST("TestErrorsAfterStop")
	Set tAllErrors = 0
	Set tSC = ##class(Feeder.Util).CheckErrors()
	Set tSC = $$$OK
	Set myUnitTest = $Get(^myUnitTests)
	If myUnitTest {
		Set pIris = ""
		For {
			Set pIris = $Order(^myUnitTests(myUnitTest,pIris))
			If pIris = "" Quit
			Set tErrCount = $Get(^myUnitTests(myUnitTest,pIris,"ErrCount"),0)
			//Set temp = $$$AssertEquals(tErrCount,0,pIris_" had "_tErrCount_" error(s).")
			If (+tErrCount) {
				Set tAllErrors = tAllErrors + tErrCount
				//Do ..LogMessage(pIris_" had "_tErrCount_" error(s).")
				Set tSC = $$$AssertEquals(tErrCount,0,pIris_" had "_tErrCount_" error(s).")
			}
		}
	}
	Do ##class(Feeder.Test).UpdateMyProp(myUnitTest,"TargetErrCount",tAllErrors)
	If (tSC = $$$OK) Set tSC = $$$AssertEquals(tAllErrors,0,"Total Error Count is zero.")
	Quit tSC
}

ClassMethod ValidateConfiguration(ByRef pServer As %String, ByRef pPort As %String, ByRef pURL As %String) As %Status
{
	Do ..DebugTEST("ValidateConfiguration")
	Do ..DebugTEST("pServer = "_$Get(pServer))
	Do ..DebugTEST("pPort = "_$Get(pPort))
	Do ..DebugTEST("pURL = "_$Get(pURL))
	Set tConfigName = "CSP Operation"
	Set tSC = ##class(Feeder.Ensemble).ValidateConfigItem(tConfigName)
	If $$$ISERR(tSC) {
		Set tConfigClass = "Feeder.CSPOperation"
		Set tSC = ##class(Feeder.Ensemble).InsertConfigItem("",tConfigName,tConfigClass)
		If ($Get(pServer) = "") Set pServer = ##class(Feeder.Util).whichLoadBalancer()
		If ($Get(pPort) = "") Set pPort = 52773
		If ($Get(pURL) = "") Set pURL = ##class(Feeder.Util).whichURL()
	}
	If $$$ISERR(tSC) Do ..DebugStatus(tSC) Quit tSC
	Set tSetting = "Port"
	If ($Get(pPort) '= "") Set tSC = ..ChangeSetting("",tConfigName,tSetting,pPort)
	If ($Get(pPort) = "") Set tSC = ..GetSetting("",tConfigName,tSetting,.pPort)
	If $$$ISERR(tSC) Do ..DebugStatus(tSC) Quit tSC
	Set tSetting = "Server"
	If ($Get(pServer) '= "") Set tSC = ..ChangeSetting("",tConfigName,tSetting,pServer)
	If ($Get(pServer) = "") Set tSC = ..GetSetting("",tConfigName,tSetting,.pServer)
	If $$$ISERR(tSC) Do ..DebugStatus(tSC) Quit tSC
	Set tSetting = "URL"
	If ($Get(pURL) '= "") Set tSC = ..ChangeSetting("",tConfigName,tSetting,pURL)
	If ($Get(pURL) = "") Set tSC = ..GetSetting("",tConfigName,tSetting,.pURL)
	If $$$ISERR(tSC) Do ..DebugStatus(tSC) Quit tSC
	Set tConfigName = "File Passthrough Service"
	Set tSC = ##class(Feeder.Ensemble).ValidateConfigItem(tConfigName)
	If $$$ISERR(tSC) {
		Set tConfigClass = "EnsLib.File.PassthroughService"
		Set tSC = ##class(Feeder.Ensemble).InsertConfigItem("",tConfigName,tConfigClass)
	}
	If $$$ISERR(tSC) Do ..DebugStatus(tSC) Quit tSC
	Set tSC = ..ChangeSetting("",tConfigName,"FilePath","/tmp/")
	If $$$ISERR(tSC) Do ..DebugStatus(tSC) Quit tSC
	Set tSC = ..GetSetting("",tConfigName,"TargetConfigNames",.tTargetName)
	Do ..DebugTEST("TargetConfigNames = "_tTargetName)
	If (tTargetName = "") {
		Set tTargetName = "CSP Operation"
		Set tSC = ..ChangeSetting("",tConfigName,"TargetConfigNames",tTargetName)
	}
	If $$$ISERR(tSC) Do ..DebugStatus(tSC) Quit tSC
	Quit $$$OK
}

}
