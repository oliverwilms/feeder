Class Feeder.Util
{

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

ClassMethod CallRESTapi(pIris As %String, pUrl As %String, ByRef pResponseData As %DynamicObject, pType As %String = "GET") As %Status
{
	#define maxRESTapiErr 3
	#define maxRetries 2
	#define timeout 3
	Do ..DebugTEST("Feeder.Util - CallRESTapi")
	Do ..DebugTEST("pIris = "_$Get(pIris))
	Do ..DebugTEST("pUrl = "_$Get(pUrl))
	Set myUnitTest = $Get(^myUnitTests)
	If (myUnitTest = "") Quit $$$ERROR($$$GeneralError,"^myUnitTests undefined")
	If myUnitTest {
		Set tRESTapiErr = $Get(^myUnitTests(myUnitTest,pIris,"RESTapiErr"),0)
		If (tRESTapiErr >= $$$maxRESTapiErr) Quit $$$ERROR($$$GeneralError,"Too many errors")
	}
	Set tErrorCount = 0
	Set tParamIRIS = pIris
	If (pIris = 0) Set pIris = "127.0.0.1:52773"
	Set tServer = $Piece(pIris,":",1)
	Set tPort = $Piece(pIris,":",2)
	Do {
		Set tRetryFlag = 0
		Set pResponse = $$$NULLOREF
		Set tRequest = ##class(%Net.HttpRequest).%New()

		// InitiateAuthentication does not exist in HealthShare versions
		Try {
			//Supported schemes are Negotiate, NTLM and Basic.
			Set tRequest.InitiateAuthentication = "Basic"
			Set tRequest.Username = "_SYSTEM"
			Set tRequest.Password = ..GetPass(pIris)
		} Catch {
		}

		//Set tRequest.Server = ""  // This defaults to 'localhost', i.e. your current machine if not specified.
		Set tRequest.Port = tPort
		If (tServer '= "") Set tRequest.Server = tServer
		Set tRequest.Timeout = $$$timeout
		Set type = "GET"
		Set location = $Get(pUrl)
		Set test = 0
		Set reset = 1
		Set tSC = tRequest.Send(type,location,test,reset)
		If $$$ISERR(tSC) Do ..DebugStatus(tSC)
		Set pResponse = tRequest.HttpResponse
		If $IsObject(pResponse) {
			If (pResponse.StatusCode '= 200) {
				Do ..DebugTEST("StatusCode = "_pResponse.StatusCode)
				Do ..DebugTEST("ReasonPhrase = "_pResponse.ReasonPhrase)
			}
			If (pResponse.StatusCode = 500) {  // Internal Server Error
				If $Increment(tErrorCount) <= $$$maxRetries Set tRetryFlag = 1
			}
		} Else {
			Do ..DebugTEST("HttpResponse = "_pResponse)
		}
	} While tRetryFlag

	If $IsObject(pResponse) {
		#dim tDataStream As %Stream.GlobalBinary
		Set tDataStream = pResponse.Data
		Set tDataString = tDataStream.Read(.len,.sc)
		If $$$ISOK(sc) {
			Do ..DebugTEST("tDataString = "_tDataString)
		} Else {
			Do ..DebugTEST("Data = "_pResponse.Data)
			Do ..DebugTEST("len = "_$Get(len))
			Do ..DebugStatus(sc)
		}
		Try {
			Set pResponseData = ##class(%DynamicObject).%FromJSON(tDataString)
		}
		Catch {
			Set tSC = $$$ERROR($$$GeneralError,"JSON error")
			Do ..DebugStatus(tSC)
		}
	}
	If $$$ISOK(tSC) {
		Quit tSC
	}
	Set pIris = $Get(tParamIRIS,pIris)
	Set myUnitTest = $Get(^myUnitTests)
	If (myUnitTest = "") Quit $$$ERROR($$$GeneralError,"^myUnitTests undefined")
	If myUnitTest {
		Set tRESTapiErr = $Get(^myUnitTests(myUnitTest,pIris,"RESTapiErr"),0)
		Set ^myUnitTests(myUnitTest,pIris,"RESTapiErr") = $Increment(tRESTapiErr)
	}
	Quit tSC
}

ClassMethod ExecuteQueryOneValue(pQuery As %String, ByRef pResult As %String) As %Status
{
	Do ..DebugTEST("Feeder.Util - ExecuteQueryOneValue")
	Do ..DebugTEST("pQuery = "_pQuery)
	Set pResult = ""
	Set rs = ##class(%ResultSet).%New()
	Set tSC = rs.Prepare(pQuery)
	Do ..DebugStatus(tSC)
	If $$$ISOK(tSC) {
		Set tSC = rs.Execute()
		Do ..DebugStatus(tSC)
		If $$$ISOK(tSC), rs.Next() Set pResult = rs.GetData(1)
	}
	Do rs.Close()
	Set rs = ""
	Do ..DebugTEST("pResult = "_pResult)
	Quit tSC
}

/// Get a list of files in the directory configured by FilePath.
/// The filenames are returned in a %ListOfDataTypes object. Each entry in the list is
/// a semicolon-separated string containing: Filename;Type;Size;DateCreated;DateModified;FullPathName
ClassMethod FileSet(Output pFileList As %ListOfDataTypes, pFilePath As %String = "", pWildcards As %String = "*", pIncludeDirs As %Boolean = 0) As %Status
{
	#; ={$Select($$$isVMS:"*.*",1:"*")}
	Set $ZT="Trap",tSC=$$$OK
	do {
		Kill pFileList Set pFileList=##class(%ListOfDataTypes).%New()
		//$$$catTRACE("file","Getting list of filenames for "_..fixPath(..FilePath))
		Set tResultSet=##class(%ResultSet).%New("%File:FileSet")
		Set tSC=tResultSet.Execute(pFilePath,pWildcards,"Type",pIncludeDirs)  Quit:$$$ISERR(tSC)
		While 0'=tResultSet.Next() {
			#; PathName;Type;Size;DateCreated;DateModified;Name
			Set tSC = pFileList.Insert(tResultSet.GetData(6)_";="_tResultSet.GetData(2)_";"_tResultSet.GetData(3)_";created="_tResultSet.GetData(4)_";modified="_tResultSet.GetData(5)_";"_tResultSet.GetData(1))  Quit:$$$ISERR(tSC)
		}
	} while (0)
	//If $$$ISERR(tSC) $$$LOGSTATUS(tSC)
Exit
	Quit tSC
Trap
	//Set $ZT="",tSC=$$$SystemError
	Set $ZT="",tSC=$$$ERROR($$$GeneralError,"FileSet Error")
	Goto Exit
}

ClassMethod GetBaseMsgId() As %Status
{
	Do ..DebugTEST("Feeder.Util - GetBaseMsgId")
	Set tBaseMsgId = 0
	// Get base msg event ID
	Set query = "SELECT TOP 1 ID FROM Ens.MessageHeader ORDER BY ID DESC"
	Set tSC = ..ExecuteQueryOneValue(query,.tBaseMsgId)
	Set tBaseMsgId = 1 + tBaseMsgId
	Do ..DebugTEST("tBaseMsgId = "_tBaseMsgId)
	/*
	Set data = {}
	Set data.BaseMsgId = tBaseMsgId
	Write data.%ToJSON()
	*/
	Set myUnitTest = $Get(^myUnitTests)
	If myUnitTest {
		Set pIris = 0
		Set ^myUnitTests(myUnitTest,pIris,"BaseMsgId") = $Get(tBaseMsgId,"<undefined>")
	}
	Set tSC = $$$OK
	Quit tSC
}

ClassMethod GetPass(pIris As %String) As %String
{
	Set tPass = "abc123"
	Quit tPass
}

ClassMethod GetContainerArray(ByRef pIRIS) As %Status
{
	Kill pIRIS
	//Caution: These will start during LBTest()
	Quit $$$OK
}

ClassMethod GetConfigItemArray(ByRef pItem, pFiles As %String = 1) As %Status
{
	Kill pItem
	If ($Extract(pFiles,1,2) = "CC") {
		Set pItem($Increment(pItem)) = "fromCCS"
		Quit $$$OK
	}
	Set pItem($Increment(pItem)) = "InComingDLA"
	Set pItem($Increment(pItem)) = "toDLAUser"
	Set pItem($Increment(pItem)) = "ETfromDMLSS"
	Set pItem($Increment(pItem)) = "FAfromDMLSS"
	Set pItem($Increment(pItem)) = "FedRRfromDMLSS"
	Set pItem($Increment(pItem)) = "MOfromDMLSS"
	Set pItem($Increment(pItem)) = "NonFedRRfromDMLSS"
	Set pItem($Increment(pItem)) = "fromDMLSS_Router"
	Set pItem($Increment(pItem)) = "ETtoFMS"
	Set pItem($Increment(pItem)) = "FAtoFMS"
	Set pItem($Increment(pItem)) = "FedRRtoFMSCrud"
	Set pItem($Increment(pItem)) = "MOtoFMS"
	Set pItem($Increment(pItem)) = "NonFedRRtoFMSCrud"
	Quit $$$OK
}

ClassMethod GetBases() As %Status
{
	Set tSC = ..GetBaseMsgId()
	Set tSC = ..GetContainerArray(.pIRIS)
	Set ii = ""
	For {
		Set ii = $Order(pIRIS(ii),1,tIris)
		If (ii = "") Quit
		Set tSC = ..GetBasesOneInstance(tIris)
	}
	Quit $$$OK
}

ClassMethod GetBasesOneInstance(pIris As %String) As %Status
{
	Do ..DebugTEST("Feeder.Util - GetBasesOneInstance - "_$Get(pIris))
	Set pUrl = "/restapi/Bases"
	Set tSC = ..CallRESTapi(pIris,pUrl,.obj)
	If $$$ISERR(tSC) Do ..DebugStatus(tSC)
	If $$$ISOK(tSC) {
		Try {
			Set tBaseLogId = obj.BaseLogId
			Set tBaseMsgId = obj.BaseMsgId
		}
		Catch {
			Set tSC = $$$ERROR($$$GeneralError,"JSON error")
			Do ..DebugStatus(tSC)
		}
		//Do ..DebugTEST("tBaseLogId = "_$Get(tBaseLogId,"<undefined>"))
		//Do ..DebugTEST("tBaseMsgId = "_$Get(tBaseMsgId,"<undefined>"))
	}
	Set myUnitTest = $Get(^myUnitTests)
	If myUnitTest {
		Set ^myUnitTests(myUnitTest,pIris,"BaseLogId") = $Get(tBaseLogId,"<undefined>")
		Set ^myUnitTests(myUnitTest,pIris,"BaseMsgId") = $Get(tBaseMsgId,"<undefined>")
	}
	Set tSC = $$$OK
	Quit tSC
}

ClassMethod GetProductionStates(pServer As %String, pPort As %String, pFiles As %String = 1) As %Status
{
	Do ..DebugTEST("Feeder.Util - GetProductionStates")
	Set target = $Get(pServer)_":"_$Get(pPort)  // This UnitTest will send messages to target
	Do ..DebugTEST("target = "_target)
	Set tLB = (..whichLoadBalancer() = pServer)  // We want all IRIS productions running when LB
	Set tSC = ..GetContainerArray(.pIRIS)
	Set ii = ""
	For {
		Set ii = $Order(pIRIS(ii),1,tIris)
		If (ii = "") Quit
		Set action = $Select(tLB:"Start",tIris=target:"Start",1:"Stop")
		Set tSC = ..GetProdStatusOneInstance(tIris,action,pFiles)
	}
	Quit $$$OK
}

ClassMethod GetProdStatusOneInstance(pIris As %String, pAction As %String, pFiles As %String = 1) As %Status
{
	Do ..DebugTEST("Feeder.Util - GetProdStatusOneInstance - "_$Get(pIris))
	Set pUrl = "/restapi/ProductionStatus"
	Set tSC = ..CallRESTapi(pIris,pUrl,.obj)
	If $$$ISERR(tSC) Do ..DebugStatus(tSC)
	If $$$ISOK(tSC) {
		Try {
			Set tProductionName = obj.ProductionName
			Set tState = obj.State
		}
		Catch {
			Set tSC = $$$ERROR($$$GeneralError,"JSON error")
			Do ..DebugStatus(tSC)
		}
		//Do ..DebugTEST("tProductionName = "_$Get(tProductionName,"<undefined>"))
		//Do ..DebugTEST("tState = "_$Get(tState,"<undefined>"))
	}
	Set myUnitTest = $Get(^myUnitTests)
	If myUnitTest {
		Set ^myUnitTests(myUnitTest,pIris,"ProductionName") = $Get(tProductionName,"<undefined>")
		Set ^myUnitTests(myUnitTest,pIris,"State") = $Get(tState,"<undefined>")
	}
	If ($Get(pAction) = "Start") {
		Set tSC = ..EnableProdItems(pIris,pFiles)
		If ($Get(tState) '= "Running") {
			Set tSC = ..GetProdStartOneInstance(pIris)
		}
	}
	If ($Get(pAction) = "Stop"),($Get(tState) '= "Stopped") {
		Set tSC = ..GetProdStopOneInstance(pIris)
	}
	Quit tSC
}

ClassMethod GetProductionStarts() As %Status
{
	Set tSC = ..GetContainerArray(.pIRIS)
	Set ii = ""
	For {
		Set ii = $Order(pIRIS(ii),1,tIris)
		If (ii = "") Quit
		Set tSC = ..GetProdStartOneInstance(tIris)
	}
	Quit $$$OK
}

ClassMethod GetProdStartOneInstance(pIris As %String) As %Status
{
	Do ..DebugTEST("Feeder.Util - GetProdStartOneInstance - "_$Get(pIris))
	Set pUrl = "/restapi/Production/Start"
	Set tSC = ..CallRESTapi(pIris,pUrl,.obj)
	If $$$ISERR(tSC) Do ..DebugStatus(tSC)
	If $$$ISOK(tSC) {
		Try {
			Set status = obj.Status
		}
		Catch {
			Set tSC = $$$ERROR($$$GeneralError,"JSON error")
			Do ..DebugStatus(tSC)
		}
		//Do ..DebugTEST("status = "_$Get(status,"<undefined>"))
	}
	Set myUnitTest = $Get(^myUnitTests)
	If myUnitTest {
		Set ^myUnitTests(myUnitTest,pIris,"Production/Start") = $Get(status,"<undefined>")
	}
	Quit tSC
}

ClassMethod GetProductionStops() As %Status
{
	Set tSC = ..GetContainerArray(.pIRIS)
	Set ii = ""
	For {
		Set ii = $Order(pIRIS(ii),1,tIris)
		If (ii = "") Quit
		Set tSC = ..GetProdStopOneInstance(tIris)
	}
	Quit $$$OK
}

ClassMethod GetProdStopOneInstance(pIris As %String) As %Status
{
	Do ..DebugTEST("Feeder.Util - GetProdStopOneInstance - "_$Get(pIris))
	Set pUrl = "/restapi/Production/Stop"
	Set tSC = ..CallRESTapi(pIris,pUrl,.obj)
	If $$$ISERR(tSC) Do ..DebugStatus(tSC)
	If $$$ISOK(tSC) {
		Try {
			Set status = obj.Status
		}
		Catch {
			Set tSC = $$$ERROR($$$GeneralError,"JSON error")
			Do ..DebugStatus(tSC)
		}
		//Do ..DebugTEST("status = "_$Get(status,"<undefined>"))
	}
	Set myUnitTest = $Get(^myUnitTests)
	If myUnitTest {
		Set ^myUnitTests(myUnitTest,pIris,"Production/Stop") = $Get(status,"<undefined>")
	}
	Quit tSC
}

ClassMethod EnableProdItems(pIris As %String, pFiles As %String = 1) As %Status
{
	Do ..DebugTEST("Feeder.Util - EnableProdItems - "_$Get(pIris))
	Set tSC = ..GetConfigItemArray(.pItem,pFiles)
	Set ii = ""
	For {
		Set ii = $Order(pItem(ii),1,tConfigItemName)
		If (ii = "") Quit
		Set tSC = ..EnableConfigItem(pIris,tConfigItemName)
	}
	Quit $$$OK
}

ClassMethod EnableConfigItem(pIris As %String, pConfigItemName As %String) As %Status
{
	Do ..DebugTEST("Feeder.Util - EnableConfigItem - "_$Get(pIris)_" - "_$Get(pConfigItemName))
	Set pUrl = "/restapi/Production/Item/Enable/"_$Get(pConfigItemName)
	Set tSC = ..CallRESTapi(pIris,pUrl,.obj)
	If $$$ISERR(tSC) Do ..DebugStatus(tSC)
	If $$$ISOK(tSC) {
		Try {
			Set status = obj.Status
		}
		Catch {
			Set tSC = $$$ERROR($$$GeneralError,"JSON error")
			Do ..DebugStatus(tSC)
		}
	}
	Quit tSC
}

/// Copied from %UnitTest.TestProduction
/// Retrieve records from the Interoperability event log, returning them in an array.<br>
/// <b>type</b> = "info" or "error" or "trace" or "warning" or "alert" or "assert" or
///        "infouser" or "startstop" or "other"
/// <b>name</b> = config name to filter entries (only fetch entries associated with this config name)<br>
/// Examples: <br>
/// To get new user entries of type "Info":<br>
/// Set s = ..GetEventLog("infouser", "", "", .Log, .New)<br>
/// To get new entries of type "Trace":<br>
/// Set s = ..GetEventLog("trace", "MyBP", "", .Log, .New)<br>
/// where <b>New</b> indicates how many new entries were found.<br>
/// Sample format for the returned array: <br>
/// 	Log(1,"ConfigName")="Ens.ScheduleHandler" <br>
/// 	Log(1,"ID")="114" <br>
/// 	Log(1,"Job")="4768" <br>
/// 	Log(1,"SessionId")="8" <br>
/// 	Log(1,"SourceClass")="Ens.Director" <br>
/// 	Log(1,"SourceMethod")="UpdateProduction" <br>
/// 	Log(1,"Stack")="" <br>
/// 	Log(1,"Text")="Production 'QDENS.HL7.HL7Routing.Production' is up-to-date." <br>
/// 	Log(1,"TimeLogged")="2006-12-05 17:41:06.421" <br>
/// 	Log(1,"Type")="Info"
ClassMethod GetEventLog(type As %String = "all", name As %String = "", baseId As %Integer, ByRef v As %String, Output New As %Integer) As %Status
{
	Quit $$$OK
}

ClassMethod MakeTestFile(pPath As %String = "/ICS/unittest/") As %Status
{
	Set tSC = $$$OK
	Set pFilename = "testfile"
	Set dev = pPath _ pFilename
	Set param = ""
	Set timeout = 1
	Open dev:("NRW"):timeout
	Else  Write "cannot Open",!
	Use dev
	Write "Halloh"
	Close dev
	Use 0
	Quit tSC
}

ClassMethod StartUnitTest(pFiles As %Integer = 1) As %Boolean
{
	Set d = "^"
	Set (myErrCount,myMsgCount) = -1
	Set myUnitTest = $Increment(^myUnitTests)
	Set tSC	= ..GetDateTimeOneInstance(0,.pDateTime,0)  // Updates ^myUnitTests
	Set ^myUnitTests(myUnitTest) = $Get(pDateTime)_d_pFiles_d_myErrCount_d_myMsgCount
	Do ..GetDateTimes()
	Set tSC = ..GetBases()
	Quit 1
}

/// Copied from %UnitTest.TestProduction
/// Override this method if you are going to check errors with custom code.
/// It's automatically invoked when parameter <parameter>IGNOREPRODUCTIONERRORS</parameter> = 1.
ClassMethod CheckErrors() As %Status
{
	Do ..DebugTEST("Feeder.Util - CheckErrors")
	Set tSC = ..GetContainerArray(.pIRIS)
	Set ii = ""
	For {
		Set ii = $Order(pIRIS(ii),1,tIris)
		If (ii = "") Quit
		Set tSC = ..CheckErrorsOneInstance(tIris)
	}
	Quit $$$OK
}

ClassMethod CheckErrorsOneInstance(pIris As %String, Output pErrCount As %String) As %Status
{
	Do ..DebugTEST("Feeder.Util - CheckErrorsOneInstance - "_$Get(pIris))
	Set myUnitTest = $Get(^myUnitTests)
	If (myUnitTest = "") Quit $$$ERROR($$$GeneralError,"^myUnitTests undefined")
	If myUnitTest {
		Set tBaseLogId = $Get(^myUnitTests(myUnitTest,pIris,"BaseLogId"),-1)
		If (tBaseLogId = -1) Quit $$$ERROR($$$GeneralError,"BaseLogId undefined")
	}
	Set pUrl = "/restapi/CheckErrors/"_$Get(tBaseLogId,1)
	Set tSC = ..CallRESTapi(pIris,pUrl,.obj)
	If $$$ISERR(tSC) Do ..DebugStatus(tSC)
	If $$$ISOK(tSC) {
		Try {
			Set pErrCount = obj.ErrCount
		}
		Catch {
			Set tSC = $$$ERROR($$$GeneralError,"JSON error")
			Do ..DebugStatus(tSC)
		}
		//Do ..DebugTEST("pErrCount = "_$Get(pErrCount,"<undefined>"))
	}
	Set myUnitTest = $Get(^myUnitTests)
	If myUnitTest {
		Set ^myUnitTests(myUnitTest,pIris,"ErrCount") = $Get(pErrCount,"<undefined>")
	}
	Quit tSC
}

ClassMethod CheckMessages() As %Status
{
	Do ..DebugTEST("Feeder.Util - CheckMessages")
	Set tSC = ..GetContainerArray(.pIRIS)
	Set ii = ""
	For {
		Set ii = $Order(pIRIS(ii),1,tIris)
		If (ii = "") Quit
		Set tSC = ..CheckMessagesOneInstance(tIris)
	}
	Quit $$$OK
}

ClassMethod CheckMessagesOneInstance(pIris As %String) As %Status
{
	Do ..DebugTEST("Feeder.Util - CheckMessagesOneInstance - "_$Get(pIris))
	Set myUnitTest = $Get(^myUnitTests)
	If (myUnitTest = "") Quit $$$ERROR($$$GeneralError,"^myUnitTests undefined")
	If myUnitTest {
		Set tBaseMsgId = $Get(^myUnitTests(myUnitTest,pIris,"BaseMsgId"),-1)
		If (tBaseMsgId = -1) Quit $$$ERROR($$$GeneralError,"BaseMsgId undefined")
	}
	Set pUrl = "/restapi/CheckMessages/"_$Get(tBaseMsgId,1)
	Set tSC = ..CallRESTapi(pIris,pUrl,.obj)
	If $$$ISERR(tSC) Do ..DebugStatus(tSC)
	If $$$ISOK(tSC) {
		Try {
			Set tMsgCount = obj.MsgCount
			Set tBegin = obj.Begin
			Set tEnd = obj.End
		}
		Catch {
			Set tSC = $$$ERROR($$$GeneralError,"JSON error")
			Do ..DebugStatus(tSC)
		}
		//Do ..DebugTEST("tMsgCount = "_$Get(tMsgCount,"<undefined>"))
		//Do ..DebugTEST("tBegin = "_$Get(tBegin,"<undefined>"))
		//Do ..DebugTEST("tEnd = "_$Get(tEnd,"<undefined>"))
	}
	Set myUnitTest = $Get(^myUnitTests)
	If myUnitTest {
		Set ^myUnitTests(myUnitTest,pIris,"MsgCount") = $Get(tMsgCount,"<undefined>")
		Set ^myUnitTests(myUnitTest,pIris,"Begin") = $Get(tBegin,"<undefined>")
		Set ^myUnitTests(myUnitTest,pIris,"End") = $Get(tEnd,"<undefined>")
	}
	Quit tSC
}

ClassMethod CheckMessagesThisInstance(ByRef pMsgCount As %String, ByRef pBegin As %String, ByRef pEnd As %String) As %Status
{
	Do ..DebugTEST("Feeder.Util - CheckMessagesThisInstance")
	Set myUnitTest = $Get(^myUnitTests)
	If (myUnitTest = "") Quit $$$ERROR($$$GeneralError,"^myUnitTests undefined")
	Set tBaseMsgId = $Get(^myUnitTests(myUnitTest,0,"BaseMsgId"),1)
	Set pName = "File Passthrough Service"
	Set s = ##class(Feeder.Ensemble).GetMessages("all", pName, tBaseMsgId, .Msg, .pMsgCount, .pBegin, .pEnd) // Retrieve Messages
	Do ..DebugTEST("MsgCount = "_$Get(pMsgCount,-1))
	Do ..DebugMerge("Msg",.Msg)
	Quit $$$OK
}

ClassMethod GetDateTimes() As %Status
{
	Do ..DebugTEST("Feeder.Util - GetDateTimes")
	Set tSC = ..GetContainerArray(.pIRIS)
	Set ii = ""
	For {
		Set ii = $Order(pIRIS(ii),1,tIris)
		If (ii = "") Quit
		Set tSC = ..GetDateTimeOneInstance(tIris)
	}
	Quit $$$OK
}

ClassMethod GetDateTimeOneInstance(pIris As %String, ByRef pDateTime As %String, pDateTimeBase As %String) As %Status
{
	Do ..DebugTEST("Feeder.Util - GetDateTimeOneInstance - "_$Get(pIris))
	Kill pDateTime
	Set pDateFormat = 3
	Set pUrl = "/restapi/DateTime"
	Set pDateTimeBase = $ZDateTime($NOW(),pDateFormat,1,3)  // Get Base Time to compare as close as possible
	Set tSC = ..CallRESTapi(pIris,pUrl,.obj)
	If $$$ISERR(tSC) Do ..DebugStatus(tSC)
	If $$$ISOK(tSC) {
		Try {
			Set pDateTime = obj.DateTime
		}
		Catch {
			Set tSC = $$$ERROR($$$GeneralError,"JSON error")
			Do ..DebugStatus(tSC)
		}
		//Do ..DebugTEST("pDateTime = "_$Get(pDateTime,"<undefined>"))
	}
	Set myUnitTest = $Get(^myUnitTests)
	If myUnitTest {
		Set ^myUnitTests(myUnitTest,pIris,"DateTime") = $Get(pDateTime,"<undefined>")
		If +$Get(pDateTimeBase,0),+$Get(pDateTime,0) {
			Set ^myUnitTests(myUnitTest,pIris,"DateTimeDiff") = ..GetDateTimeDiff(pDateTime,pDateTimeBase)
		}
	}
	Set tSC = $$$OK
	Quit tSC
}

ClassMethod AddDateTimeDiff(pTS1 As %String, pDiff As %Integer, pTSI As %String = "SQL_TSI_FRAC_SECOND") As %String
{
	Do ..DebugTEST("Feeder.Util - AddDateTimeDiff - "_$Get(pIris))
	Do ..DebugTEST("pTS1 = "_$Get(pTS1))
	Do ..DebugTEST("pDiff = "_$Get(pDiff))
	Set c = ","
	Set q = "'"
	Set pQuery = "SELECT {fn TIMESTAMPADD("_pTSI_c_pDiff_c_q_pTS1_q_")}"
	Set tSC = ..ExecuteQueryOneValue(pQuery,.pResult)
	Do ..DebugTEST("pResult = "_$Get(pResult,"<undefined>"))
	Quit $Get(pResult,"<undefined>")
}

ClassMethod GetDateTimeDiff(pTS1 As %String, pTS2 As %String, pTSI As %String = "SQL_TSI_FRAC_SECOND", pDEBUG As %Integer = 0) As %String
{
	Do:pDEBUG ..DebugTEST("Feeder.Util - GetDateTimeDiff - "_$Get(pIris))
	Do:pDEBUG ..DebugTEST("pTS1 = "_$Get(pTS1))
	Do:pDEBUG ..DebugTEST("pTS2 = "_$Get(pTS2))
	Set c = ","
	Set q = "'"
	Set pQuery = "SELECT {fn TIMESTAMPDIFF("_pTSI_c_q_pTS1_q_c_q_pTS2_q_")}"
	Set tSC = ..ExecuteQueryOneValue(pQuery,.pResult)
	Do:pDEBUG ..DebugTEST("pResult = "_$Get(pResult,"<undefined>"))
	Quit $Get(pResult,"<undefined>")
}

ClassMethod GetDocumentId(pIris As %String, ByRef pDocumentId As %String, pDEBUG As %Integer = 1) As %Status
{
	Do:pDEBUG ..DebugTEST("Feeder.Util - GetDocumentId - "_$Get(pIris))
	Kill pDocumentId
	Set pUrl = "/restapi/DocumentId"
	Set tSC = ..CallRESTapi(pIris,pUrl,.obj)
	If $$$ISERR(tSC) Do:pDEBUG ..DebugStatus(tSC)
	If $$$ISOK(tSC) {
		Try {
			Set pDocumentId = obj.DocumentId
		}
		Catch {
			Set tSC = $$$ERROR($$$GeneralError,"JSON error")
			Do:pDEBUG ..DebugStatus(tSC)
		}
	}
	Quit tSC
}

ClassMethod GetFilesCount(pPath As %String = "", pFiles As %String = "*") As %Integer
{
	Set tSC = ##class(Feeder.Util).FileSet(.pFileList,pPath,pFiles)
	Set pCount = pFileList.Size
	Write pCount_" matching file(s) in "_pPath,!
	Quit pCount
}

ClassMethod GetMsgBankCount(pIris As %String, ByRef pMsgBankCount As %String) As %Status
{
	//Do ..DebugTEST("Feeder.Util - GetMsgBankCount - "_$Get(pIris))
	Kill pMsgBankCount
	Set myNamespace = $Namespace
	Set tNamespaceMsgBank = $Get(^myUnitTestControl("Namespace","MsgBank"),"ENTERPRISE")
	//ZNSPACE "ENTERPRISE"
	Set pQuery = "SELECT COUNT(*) FROM Ens_Enterprise_MsgBank.MessageHeader"
	Set rs = ##class(%ResultSet).%New()
	Set tSC = rs.Prepare(pQuery)
	//Do ##class(Debug).DebugStatus(tSC)
	If $$$ISOK(tSC) {
		Set tSC = rs.Execute()
		//Do ##class(Debug).DebugStatus(tSC)
		If $$$ISOK(tSC), rs.Next() Set pMsgBankCount = rs.GetData(1)
	}
	Do rs.Close()
	Set rs = ""
	//Do ##class(Debug).DebugTEST("pMsgBankCount = "_pMsgBankCount)
	Set $Namespace = myNamespace
	Quit tSC
}

ClassMethod GetMsgBankReport(pIris As %String, pUnitTest As %String, ByRef pMsgBankCount As %String, pDEBUG As %String = 1) As %Status
{
	//Do ..DebugTEST("Feeder.Util - GetMsgBankCount - "_$Get(pIris))
	Kill pMsgBankCount
	Set tSC = $$$OK
	Set objUnitTest = ##class(Feeder.Test).%OpenId(pUnitTest)
	If '$IsObject(objUnitTest) { Quit tSC }
	Write:pDEBUG "This UnitTest ",pUnitTest," began ",objFeeder.Start,!
	Set tMyMsgBegin = objFeeder.Start
	Set objUnitTest = ""
	Set tMyMsgEnd = $H
	Set objUnitTest = ##class(Feeder.Test).%OpenId(pUnitTest + 1)
	If $IsObject(objUnitTest) {
		Write:pDEBUG "Next UnitTest ",pUnitTest + 1," began ",objUnitTest.Start,!
		Set tMyMsgEnd = objUnitTest.Start
	}
	Set objUnitTest = ""
	Set myNamespace = $Namespace
	Set tNamespaceMsgBank = $Get(^myUnitTestControl("Namespace","MsgBank"),"ENTERPRISE")
	//ZNSPACE "ENTERPRISE"
	Set strSELECT = "SELECT TimeCreated,TimeBanked,NodeId,Status,SourceConfigName,TargetConfigName"
	Set strFROM = " FROM Ens_Enterprise_MsgBank.MessageHeader"
	Set strWHERE = " WHERE TimeBanked BETWEEN '"_tMyMsgBegin_"' AND '"_tMyMsgEnd_"'"
	Set strORDER = " ORDER BY TimeBanked"
	Set pQuery = strSELECT_strFROM_strWHERE_strORDER
	Write:pDEBUG pQuery,!
	Set rs = ##class(%ResultSet).%New()
	Set tSC = rs.Prepare(pQuery)
	//Do ##class(Debug).DebugStatus(tSC)
	If $$$ISERR(tSC) { Quit tSC }
	Set tSC = rs.Execute()
	//Do ##class(Debug).DebugStatus(tSC)
	If $$$ISERR(tSC) { Quit tSC }
	Set (tMyMsgBegin,tMyMsgEnd) = ""
	While rs.Next() {
		If ($Increment(pMsgBankCount) = 1) Set tMyMsgBegin = $Get(rs.Data("TimeBanked"))
		Set tMyMsgEnd = $Get(rs.Data("TimeBanked"))
		If ($Get(rs.Data("NodeId")) '= "") {
			If ($Increment(pMsgBankCount("NodeId",$Get(rs.Data("NodeId")))) = 1) {
				Set pMsgBankCount("NodeId",$Get(rs.Data("NodeId")),"Begin") = $Get(rs.Data("TimeBanked"))
			}
			Set pMsgBankCount("NodeId",$Get(rs.Data("NodeId")),"End") = $Get(rs.Data("TimeBanked"))
		}
		If ($Get(rs.Data("Status")) '= "") {
			If ($Increment(pMsgBankCount("Status",$Get(rs.Data("Status")))) = 1) {
				Set pMsgBankCount("Status",$Get(rs.Data("Status")),"Begin") = $Get(rs.Data("TimeBanked"))
			}
			Set pMsgBankCount("Status",$Get(rs.Data("Status")),"End") = $Get(rs.Data("TimeBanked"))
		}
		If ($Get(rs.Data("SourceConfigName")) '= "") {
			If ($Increment(pMsgBankCount("Source",$Get(rs.Data("SourceConfigName")))) = 1) {
				Set pMsgBankCount("Source",$Get(rs.Data("SourceConfigName")),"Begin") = $Get(rs.Data("TimeBanked"))
			}
			Set pMsgBankCount("Source",$Get(rs.Data("SourceConfigName")),"End") = $Get(rs.Data("TimeBanked"))
		}
		If ($Get(rs.Data("TargetConfigName")) '= "") {
			If ($Increment(pMsgBankCount("Target",$Get(rs.Data("TargetConfigName")))) = 1) {
				Set pMsgBankCount("Target",$Get(rs.Data("TargetConfigName")),"Begin") = $Get(rs.Data("TimeBanked"))
			}
			Set pMsgBankCount("Target",$Get(rs.Data("TargetConfigName")),"End") = $Get(rs.Data("TimeBanked"))
		}
	}
	Do rs.Close()
	Set rs = ""
	//Do ##class(Debug).DebugTEST("pMsgBankCount = "_pMsgBankCount)
	Set pMsgBankCount = $Get(pMsgBankCount,0)
	Set tDelim = "^"
	Set pMsgBankCount = tDelim_$Get(pMsgBankCount,0)_tDelim_tMyMsgBegin_tDelim_tMyMsgEnd
	Set $Namespace = myNamespace
	Quit tSC
}

/// Identify "DMLSS Document ID already exists in table with ID:672"
ClassMethod GetMsgBLogReport(pIris As %String, pUnitTest As %String, ByRef pMsgBankCount As %String, pDEBUG As %String = 1) As %Status
{
	//Do ..DebugTEST("Feeder.Util - GetMsgBankCount - "_$Get(pIris))
	Kill pMsgBankCount,pMsgBLog
	Set tSC = $$$OK
	Set tSearch = "DMLSS Document ID already exists in table with ID:"
	Set objUnitTest = ##class(Feeder.Test).%OpenId(pUnitTest)
	If '$IsObject(objUnitTest) { Quit tSC }
	Write:pDEBUG "This UnitTest ",pUnitTest," began ",objUnitTest.Start,!
	Set tMyMsgBegin = objUnitTest.Start
	Set objUnitTest = ""
	Set tMyMsgEnd = $H
	Set objUnitTest = ##class(Feeder.Test).%OpenId(pUnitTest + 1)
	If $IsObject(objUnitTest) {
		Write:pDEBUG "Next UnitTest ",pUnitTest + 1," began ",objUnitTest.Start,!
		Set tMyMsgEnd = objUnitTest.Start
	}
	Set objUnitTest = ""
	Set myNamespace = $Namespace
	Set tNamespaceMsgBank = $Get(^myUnitTestControl("Namespace","MsgBank"),"ENTERPRISE")
	//ZNSPACE "ENTERPRISE"
	Set strSELECT = "SELECT TimeBanked,NodeId,ConfigName,SourceClass,SourceMethod,Text FROM Ens_Enterprise_MsgBank.Log"
	Set strORDER = " ORDER BY TimeBanked"
	Set strWHERE = " WHERE TimeBanked BETWEEN '"_tMyMsgBegin_"' AND '"_tMyMsgEnd_"'"
	Set pQuery = strSELECT_strWHERE_strORDER
	Write:pDEBUG pQuery,!
	Set rs = ##class(%ResultSet).%New()
	Set tSC = rs.Prepare(pQuery)
	//Do ##class(Debug).DebugStatus(tSC)
	If $$$ISERR(tSC) { Quit tSC }
	Set tSC = rs.Execute()
	//Do ##class(Debug).DebugStatus(tSC)
	If $$$ISERR(tSC) { Quit tSC }
	Set (tMyMsgBegin,tMyMsgEnd) = ""
	While rs.Next() {
		If ($Increment(pMsgBankCount) = 1) Set tMyMsgBegin = $Get(rs.Data("TimeBanked"))
		Set tMyMsgEnd = $Get(rs.Data("TimeBanked"))
		If ($Get(rs.Data("NodeId")) '= "") {
			If ($Increment(pMsgBankCount($Get(rs.Data("NodeId")))) = 1) {
				Set pMsgBankCount($Get(rs.Data("NodeId")),"Begin") = $Get(rs.Data("TimeBanked"))
			}
			Set pMsgBankCount($Get(rs.Data("NodeId")),"End") = $Get(rs.Data("TimeBanked"))
		}
		If ($Get(rs.Data("ConfigName")) '= "fromDMLSS_Router") Continue
		If ($Get(rs.Data("SourceClass")) '= "HS.Local.VA.eSCM.Common.DocumentIDTable") Continue
		If ($Get(rs.Data("SourceMethod")) '= "StoreDocID") Continue
		Set tText = $Get(rs.Data("Text"))
		If ($Extract(tText,1,$Length(tSearch)) '= tSearch) Continue
		If $Increment(pMsgBLog) Set pMsgBLog(pMsgBLog) = $Piece(tText,":",2)
	}
	Do rs.Close()
	Set rs = ""
	//Do ##class(Debug).DebugTEST("pMsgBankCount = "_pMsgBankCount)
	Set pMsgBankCount = $Get(pMsgBankCount,0)
	Set pMsgBLog = $Get(pMsgBLog,0)
	Set tDelim = "^"
	Set pMsgBankCount = tDelim_$Get(pMsgBankCount,0)_tDelim_tMyMsgBegin_tDelim_tMyMsgEnd_tDelim_pMsgBLog
	For ii = 1:1:pMsgBLog {
		Set pMsgBankCount = pMsgBankCount_tDelim_$Get(pMsgBLog(ii))
	}
	Set $Namespace = myNamespace
	Quit tSC
}

ClassMethod TestMethod() As %Status
{
	Write "Your Feeder is ready.",!
	Quit $$$OK
}

ClassMethod TimeAdjust(pInput As %String = "", pAdjust As %String = "-5h") As %String
{
	Set tOutput = pInput
	If pInput?4N1"-"2N1"-"2N1" "2N1":".E {
		Set dFormat = 3
		Set posDate = 1
		Set lenDate = 10
		Set posHH = 12
	}
	If pInput?2N1":".E {
		//Set tYYYY = $Extract(pInput,1,4)
		//Set tMM = $Extract(pInput,6,7)
		//Set tDD = $Extract(pInput,9,10)
		//Set tHH = $Extract(pInput,1,2)
		Set posHH = 1
	}
	If ("Dd" [ $Extract(pAdjust,*)) {
		Set posDate = $Get(posDate)
		If posDate {
			Set tDate = $Extract(pInput,posDate,posDate+lenDate-1)
			Set tDateH = $ZDH(tDate,$Get(dFormat))
			Set tDate = $ZD((tDateH + pAdjust),$Get(dFormat))
			Set $Extract(tOutput,posDate,posDate+lenDate-1) = tDate
		}
	}
	If ("Hh" [ $Extract(pAdjust,*)) {
		Set posHH = $Get(posHH)
		If posHH Set tHH = $Extract(pInput,posHH,posHH+1)
		Set tHours = 0 + $Get(tHH) + pAdjust
		If (tHours < 0) {
			Set tHours = tHours + 24
			Set tOutput = ..TimeAdjust(tOutput,"-1d")
		}
		If posHH Set $Extract(tOutput,posHH,posHH+1) = tHours
	}
	Quit tOutput
}

ClassMethod Timeout(pInput As %String = "", pTimeOnly As %String = 1, pAdjust As %String = "-5h") As %String
{
	Set tOutput = ..TimeAdjust(pInput,pAdjust)
	If pTimeOnly {
		Set tOutput = $Piece(tOutput," ",2)
	}
	Quit tOutput
}

ClassMethod TranslateServer(pServer As %String = "") As %String
{
	Set tReturnServer = pServer
	Set tALB = "internal-dmlss-ecs-ALB"
	If $Extract(pServer,1,$Length(tALB)) = tALB Set tReturnServer = tALB
	Set tCLB = "internal-iris-test-clb"
	If $Extract(pServer,1,$Length(tCLB)) = tCLB Set tReturnServer = tCLB
	Quit tReturnServer
}

/// Called from Feeder.csp - Save what was submitted
ClassMethod UpdateCodeClassMethod(pCodeClassMethod As %String = "") As %Status
{
	Set tSC = $$$OK
	Set ^myFeeder("Config","CodeClassMethod") = pCodeClassMethod
	Quit tSC
}

/// Called from Feeder.csp - Save what was submitted
ClassMethod UpdateCodeClassName(pCodeClassName As %String = "") As %Status
{
	Set tSC = $$$OK
	Set ^myFeeder("Config","CodeClassName") = pCodeClassName
	Quit tSC
}

/// Called from Feeder.csp - Save what was submitted
ClassMethod UpdateLoadBalancer(pLoadBalancerURL As %String = "") As %Status
{
	Set tSC = $$$OK
	Set ^myFeeder("Config","LoadBalancer") = pLoadBalancerURL
	Quit tSC
}

/// Called from Feeder.csp - Save what was submitted
ClassMethod UpdateURL(pCSPOpURL As %String = "") As %Status
{
	Set tSC = $$$OK
	Set ^myFeeder("Config","CSPOpURL") = pCSPOpURL
	Quit tSC
}

ClassMethod whichIRIS(ByRef pIRIS) As %Status
{
	Kill pIRIS
	Set tSC = ..GetContainerArray(.pIRIS)
	Quit tSC
}

ClassMethod whichLoadBalancer() As %String
{
	Quit $Get(^myFeeder("Config","LoadBalancer"))
}

/// For CSPOperation
ClassMethod whichURL() As %String
{
	Quit $Get(^myFeeder("Config","CSPOpURL"),"/csp/user/cache_status.cxw")
}

}
