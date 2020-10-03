Class Feeder.CSPOperation Extends Ens.BusinessOperation
{

/// Server to connect to (optional). If not specified, it defaults to 'localhost'.
Property Server As %String(MAXLEN = 255);

/// Port for connection.
Property Port As %String(MAXLEN = 6);

/// URL to connect to (optional). If not specified, it defaults to '/csp/healthshare/DLA_IN/DLAIN.csp?FILENAME='.
Property URL As %String(MAXLEN = 255);

Parameter INVOCATION = "Queue";

Parameter SETTINGS = "Server,Port,URL";

Method SendMessage(pRequest As Ens.StreamContainer, Output pResponse As Ens.Response, pDEBUG As %String = 1) As %Status
{
	If (pDEBUG > 1) Do ##class(Feeder.Util).DebugTEST("Feeder.CSPOperation")
	Set tErrorCount = 0
	Set tFilename = ##class(%File).GetFilename(pRequest.OriginalFilename)
	If (pDEBUG > 1) Do ##class(Feeder.Util).DebugTEST("OriginalFilename = "_tFilename)
	Set type = "POST"
	If (..URL = "") {
		Set location = "/csp/healthshare/DLA_IN/DLAIN.csp?FILENAME="_tFilename
	} Else {
		If (..URL = "csp/user/cache_status.cxw") {
			Set location = ..URL  // /csp/user/cache_status.cxw
		} Else {
			Set location = ..URL_tFilename
		}
	}
	If (pDEBUG > 1) Do ##class(Feeder.Util).DebugTEST("location = "_location)
	Set test = 0
	Set reset = 1
	Do {
		Set tRetryFlag = 0
		Set pResponse = $$$NULLOREF
		Set tRequest = ##class(%Net.HttpRequest).%New()
		// InitiateAuthentication does not exist in HealthShare versions
		Try {
			Set tRequest.InitiateAuthentication = ""

			If (location [ "restapi") {
				Set tRequest.InitiateAuthentication = "Basic"
				Set tRequest.Username = "_SYSTEM" ;"ECCMON"
				//Set tRequest.Password = "SYS" ;"eccmon123!"
				Set tRequest.Password = ##class(Feeder.Util).GetPass(..Server_":"_..Port)
			}
		} Catch {
		}

		//Set tRequest.Server = ""  // This defaults to 'localhost', i.e. your current machine if not specified.
		Set tRequest.Port = ..Port
		If (..Server '= "") Set tRequest.Server = ..Server
		If (pDEBUG > 1) Do ##class(Feeder.Util).DebugTEST("Server:Port = "_..Server_":"_..Port)
		Set tSC = tRequest.EntityBody.CopyFrom(pRequest.Stream)
		If $$$ISERR(tSC) Do ##class(Feeder.Util).DebugStatus(tSC)
		#dim objResponseTime As Feeder.ResponseTime
		Set objResponseTime = ##class(Feeder.ResponseTime).NewRequest(tRequest,location)
		Set tSC = tRequest.Send(type,location,test,reset)
		If $$$ISERR(tSC) Do ##class(Feeder.Util).DebugStatus(tSC)
		#dim tResponse As %Net.HttpResponse
		Set tResponse = tRequest.HttpResponse
		If $IsObject(tResponse) {
			Set tSC = objResponseTime.SaveResponse(tResponse)
			If (tResponse.StatusCode = 500), ($Increment(tErrorCount) = 1) Set tRetryFlag = 1
			If (tResponse.StatusCode = 503), ($Increment(tErrorCount) = 1) Set tRetryFlag = 1
			Set tLogResponse = tResponse.StatusCode_" / "_tResponse.ReasonPhrase
			If (pDEBUG > 1) Do ##class(Feeder.Util).DebugTEST("StatusCode/Reason = "_tLogResponse)
		} Else {
			If (pDEBUG > 1) Do ##class(Feeder.Util).DebugTEST("HttpResponse = "_tResponse)
		}
	} While tRetryFlag
	If (pDEBUG = 1) {
		Set tLog = "CSPOperation - "_tFilename_" - "_$Get(tLogResponse,$Get(tResponse))
		Do ##class(Feeder.Util).DebugTEST(tLog)
	}
	Set tSC = $$$OK
	Quit tSC
}

XData MessageMap
{
<MapItems>
	<MapItem MessageType="Ens.StreamContainer"> 
		<Method>SendMessage</Method>
	</MapItem>
</MapItems>
}

}
