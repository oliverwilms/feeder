Class Feeder.REST Extends %CSP.REST
{

Parameter UseSession As Integer = 1;

Parameter HandleCorsRequest = 1;

Parameter CONTENTTYPE = "application/json";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
<Route Url="/:FILENAME" Method="POST" Call="UploadFile" />
<Route Url="/UploadFile/:FILENAME" Method="POST" Call="UploadFile" />
<Route Url="/UploadFile/:FILENAME" Method="GET" Call="TEST" />
<Route Url="/UploadFileNew/:FILENAME" Method="POST" Call="UploadFile" />
<Route Url="/BaseLogId" Method="GET" Call="GetBaseLogId" />
<Route Url="/BaseMsgId" Method="GET" Call="GetBaseMsgId" />
<Route Url="/Bases" Method="GET" Call="GetBases" />
<Route Url="/CheckErrors/:BaseLogId" Method="GET" Call="CheckErrors" />
<Route Url="/CheckErrors" Method="GET" Call="CheckErrors" />
<Route Url="/CheckMessages/:BaseMsgId" Method="GET" Call="CheckMessages" />
<Route Url="/CheckMessages" Method="GET" Call="CheckMessages" />
<Route Url="/DateTime" Method="GET" Call="GetDateTime" />
<Route Url="/DocumentId" Method="GET" Call="GetDocumentId" />
<Route Url="/ProductionStatus" Method="GET" Call="GetProductionStatus" />
<Route Url="/Production/Item/Enable/:ConfigItemName" Method="GET" Call="GetProdItemEnable" />
<Route Url="/ProdItemEnable/:ConfigItemName" Method="GET" Call="GetProdItemEnable" />
<Route Url="/Production/Start" Method="GET" Call="GetProductionStart" />
<Route Url="/Production/Stop" Method="GET" Call="GetProductionStop" />
</Routes>
}

ClassMethod DebugTEST(strMessage As %String = "") As %Status
{
	Set ^TESTapi($I(^TESTapi)) = $ZDateTime($NOW(),8,1,3)_" : "_$JOB_" : "_strMessage
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

ClassMethod GetBaseLogId() As %Status
{
	Do ..DebugTEST("Feeder.REST - GetBaseLogId")
	Set tBaseLogId = 0
	// Get base log event ID
	Set query = "SELECT TOP 1 ID FROM Ens_Util.Log ORDER BY ID DESC"
	Set tSC = ##class(Ensemble).ExecuteQueryOneValue(query,.tBaseLogId)
	Set tBaseLogId = 1 + tBaseLogId
	Do ..DebugTEST("tBaseLogId = "_tBaseLogId)
	Set data = {}
	Set data.BaseLogId = tBaseLogId
	Write data.%ToJSON()
	Quit $$$OK
}

ClassMethod GetBaseMsgId() As %Status
{
	Do ..DebugTEST("Feeder.REST - GetBaseMsgId")
	Set tBaseMsgId = 0
	// Get base msg event ID
	Set query = "SELECT TOP 1 ID FROM Ens.MessageHeader ORDER BY ID DESC"
	Set tSC = ##class(Ensemble).ExecuteQueryOneValue(query,.tBaseMsgId)
	Set tBaseMsgId = 1 + tBaseMsgId
	Do ..DebugTEST("tBaseMsgId = "_tBaseMsgId)
	Set data = {}
	Set data.BaseMsgId = tBaseMsgId
	Write data.%ToJSON()
	Quit $$$OK
}

ClassMethod GetBases() As %Status
{
	Do ..DebugTEST("Feeder.REST - GetBases")
	Set tBaseLogId = 0
	// Get base log event ID
	Set query = "SELECT TOP 1 ID FROM Ens_Util.Log ORDER BY ID DESC"
	Set tSC = ##class(Ensemble).ExecuteQueryOneValue(query,.tBaseLogId)
	Set tBaseLogId = 1 + tBaseLogId
	Do ..DebugTEST("tBaseLogId = "_tBaseLogId)
	Set tBaseMsgId = 0
	// Get base msg event ID
	Set query = "SELECT TOP 1 ID FROM Ens.MessageHeader ORDER BY ID DESC"
	Set tSC = ##class(Ensemble).ExecuteQueryOneValue(query,.tBaseMsgId)
	Set tBaseMsgId = 1 + tBaseMsgId
	Do ..DebugTEST("tBaseMsgId = "_tBaseMsgId)
	Set data = {}
	Set data.BaseLogId = tBaseLogId
	Set data.BaseMsgId = tBaseMsgId
	Write data.%ToJSON()
	Quit $$$OK
}

/// Copied from %UnitTest.TestProduction
/// Override this method if you are going to check errors with custom code.
/// It's automatically invoked when parameter <parameter>IGNOREPRODUCTIONERRORS</parameter> = 1.
ClassMethod CheckErrors(pBaseLogId As %String = "") As %Status
{
	Do ..DebugTEST("Feeder.REST - CheckErrors")
	If (pBaseLogId = "<undefined>") {
		Set n = "<undefined>"
	} Else {
		Set s = ##class(Ensemble).GetEventLog("error", "", pBaseLogId, .Err, .n) // Retrieve all records of type "Error"
	}
	Set data = {}
	Set data.ErrCount = $Get(n,-1)
	Write data.%ToJSON()
	Quit $$$OK
}

ClassMethod CheckMessages(pBaseMsgId As %String = "") As %Status
{
	Do ..DebugTEST("Feeder.REST - CheckMessages")
	If (pBaseMsgId = "<undefined>") {
		Set n = "<undefined>"
	} Else {
		Set s = ##class(Ensemble).GetMessages("error", "", pBaseMsgId, .v, .n, .pBegin, .pEnd) // Retrieve Messages
	}
	Set data = {}
	Set data.MsgCount = $Get(n,-1)
	Set data.Begin = $Get(pBegin)
	Set data.End = $Get(pEnd)
	Write data.%ToJSON()
	Quit $$$OK
}

ClassMethod GetDateTime(pDateFormat As %String = 3) As %Status
{
	Do ..DebugTEST("Feeder.REST - GetDateTime")
	Set tDateTime = $ZDateTime($NOW(),pDateFormat,1,3)
	Do ..DebugTEST("tDateTime = "_tDateTime)
	Set data = {}
	Set data.DateTime = tDateTime
	Write data.%ToJSON()
	Quit $$$OK
}

ClassMethod GetDocumentId() As %Status
{
	Do ..DebugTEST("Feeder.REST - GetDocumentId")
	Set tDocumentId = $Get(^HS.Local.VFC75.DocumentIDTBF63D,-1)
	Do ..DebugTEST("tDocumentId = "_tDocumentId)
	Set data = {}
	Set data.DocumentId = tDocumentId
	Write data.%ToJSON()
	Quit $$$OK
}

ClassMethod GetProdItemEnable(pConfigItemName As %String, pEnable As %Boolean = 1, pDoUpdate As %Boolean = 1) As %Status
{
	Do ..DebugTEST("Feeder.REST - GetProdItemEnable - "_pConfigItemName_" - "_pEnable_" - "_pDoUpdate)
	Set tSC = ##class(Ensemble).EnableConfigItem(pConfigItemName, pEnable, pDoUpdate)
	Do ..DebugStatus(tSC)
	Set status = ..StatusToText(tSC)
	Set data = {}
	Set data.Status = status
	Write data.%ToJSON()
	Quit $$$OK
}

ClassMethod GetProductionStatus() As %Status
{
	Do ..DebugTEST("Feeder.REST - GetProductionStatus")
	Set tSC = ##class(Ensemble).GetProductionStatus(.pProductionName, .pState)
	//Do ..DebugTEST("pProductionName = "_pProductionName)
	Do ..DebugTEST("pState = "_pState)
	Set data = {}
	Set data.ProductionName = pProductionName
	Set data.State = pState
	Write data.%ToJSON()
	Quit $$$OK
}

ClassMethod GetProductionStart() As %Status
{
	Do ..DebugTEST("Feeder.REST - GetProductionStart")
	Set tSC = ##class(Ensemble).StartProduction()
	Set status = ..StatusToText(tSC)
	Set data = {}
	Set data.Status = status
	Write data.%ToJSON()
	Quit $$$OK
}

ClassMethod GetProductionStop() As %Status
{
	Do ..DebugTEST("Feeder.REST - GetProductionStop")
	Set tSC = ##class(Ensemble).StopProduction()
	Set status = ..StatusToText(tSC)
	Set data = {}
	Set data.Status = status
	Write data.%ToJSON()
	Quit $$$OK
}

ClassMethod TEST(FILENAME As %String = "") As %Status
{
	Do ..DebugTEST("Feeder.REST - TEST")
	Quit $$$OK
}

ClassMethod UploadFile(FILENAME As %String = "") As %Status
{
	Do ..DebugTEST("Feeder.REST - UploadFile")
	Set tSC = ##class(Ens.Director).CreateBusinessService("InboundDLA",.tService)
	Do ..DebugStatus(tSC)
	set stream=##class(%GlobalCharacterStream).%New()
	if $IsObject(%request.Content) {
		do stream.CopyFrom(%request.Content)
	}
	set tRequest=##class(Ens.StreamContainer).%New()
	do tRequest.StreamSet(stream)
	set tRequest.OriginalFilename = FILENAME
	Set tSC = tService.ProcessInput(tRequest,.output)
	Do ..DebugStatus(tSC)
	Quit $$$OK
}

/// Attempt to send files directly to Service based on FILENAME
/// Not working, we need to have a file to read RecordMap
ClassMethod UploadFileNew(FILENAME As %String = "") As %Status
{
	Do ..DebugTEST("Feeder.REST - UploadFileNew")
	Set tServiceName = ..UploadFileNewGetService(FILENAME)
	Set tSC = ##class(Ens.Director).CreateBusinessService(tServiceName,.tService)
	Do ..DebugStatus(tSC)
	set stream=##class(%GlobalCharacterStream).%New()
	if $IsObject(%request.Content) {
		do stream.CopyFrom(%request.Content)
	}
	set tRequest=##class(Ens.StreamContainer).%New()
	do tRequest.StreamSet(stream)
	set tRequest.OriginalFilename = FILENAME
	Set tSC = tService.ProcessInput(tRequest,.output)
	Do ..DebugStatus(tSC)
	Quit $$$OK
}

ClassMethod UploadFileNewGetService(pFILENAME As %String = "") As %String
{
	Do ..DebugTEST("Feeder.REST - UploadFileNewGetService")
	Do ..DebugTEST("pFILENAME = "_pFILENAME)
	Set tReturn = "InboundDLA"  // Default - Catch All
	For tService = "ETfromDMLSS", "FAfromDMLSS", "FedRRfromDMLSS", "MOfromDMLSS", "NonFedRRfromDMLSS" {
		Set tPosition = 1
		Set tSC = ##class(Ensemble).GetSetting("",tService,"FileSpec",.tFileSpec)
		If $$$ISERR(tSC) Continue
		Set tPosition = $Find(tFileSpec,"*",tPosition)
		If tPosition {
			Set tFN = $Extract(pFILENAME,1,tPosition - 2)
			Set tFS = $Extract(tFileSpec,1,tPosition - 2)
			If (tFN '= tFS) Continue
		}
		Set tPosition = $Find(tFileSpec,"*",tPosition)
		If (tPosition = 0) {
			Set tReturn = tService
			Quit
		}
	}	
	Do ..DebugTEST("tReturn = "_tReturn)
	Quit tReturn
}

}
