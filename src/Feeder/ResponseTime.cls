Class Feeder.ResponseTime Extends %Persistent
{

Property RequestTimestamp As %String;

Property ResponseTimestamp As %String;

Property ResponseZCalc As %Integer [ Calculated, SqlComputeCode = {set {*}=##class(Feeder.Util).GetDateTimeDiff({RequestTimestamp},{ResponseTimestamp})}, SqlComputed ];

/// Server to connect to (optional). If not specified, it defaults to 'localhost'.
Property Server As %String(MAXLEN = 255);

/// Port for connection.
Property Port As %String(MAXLEN = 6);

/// URL to connect to (optional). If not specified, it defaults to '/csp/healthshare/DLA_IN/DLAIN.csp?FILENAME='.
Property URL As %String(MAXLEN = 255);

/// The HTTP status code. This is useful to determine if the request was
/// successful. Look in the rfc for HTTP to see which codes are supported
/// and what they mean. A human readable form of this code is stored as
/// the <PROPERTY>ReasonPhrase</PROPERTY>
Property StatusCode As %Integer;

/// This is the human readable reason that goes with the <PROPERTY>StatusCode</PROPERTY>.
Property ReasonPhrase As %String;

Property myUnitTest As %String;

ClassMethod NewRequest(pRequest As %Net.HttpRequest, pURL As %String) As Feeder.ResponseTime
{
	Set oResponseTime = ..%New()
	Set oResponseTime.RequestTimestamp = $ZDateTime($NOW(),3,1,3)
	Set oResponseTime.myUnitTest = $Get(^myUnitTests)
	Set oResponseTime.Port = pRequest.Port
	Set oResponseTime.Server = pRequest.Server
	Set oResponseTime.URL = $Get(pURL)
	Quit oResponseTime
}

Method SaveResponse(pResponse As %Net.HttpResponse) As %Status
{
	Set ..ResponseTimestamp = $ZDateTime($NOW(),3,1,3)
	Set ..StatusCode = pResponse.StatusCode
	Set ..ReasonPhrase = pResponse.ReasonPhrase
	Set tSC = ..%Save()
	Quit tSC
}

Storage Default
{
<Data name="ResponseTimeDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>RequestTimestamp</Value>
</Value>
<Value name="3">
<Value>ResponseTimestamp</Value>
</Value>
<Value name="4">
<Value>Server</Value>
</Value>
<Value name="5">
<Value>Port</Value>
</Value>
<Value name="6">
<Value>URL</Value>
</Value>
<Value name="7">
<Value>StatusCode</Value>
</Value>
<Value name="8">
<Value>ReasonPhrase</Value>
</Value>
<Value name="9">
<Value>myUnitTest</Value>
</Value>
</Data>
<DataLocation>^Feeder.ResponseTimeD</DataLocation>
<DefaultData>ResponseTimeDefaultData</DefaultData>
<IdLocation>^Feeder.ResponseTimeD</IdLocation>
<IndexLocation>^Feeder.ResponseTimeI</IndexLocation>
<StreamLocation>^Feeder.ResponseTimeS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
