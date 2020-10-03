Class Feeder.Test Extends %Persistent [ StorageStrategy = NewStorage1 ]
{

// https://community.intersystems.com/post/art-mapping-globals-classes-1-3

Index NewIndex1 On myUnitTest [ IdKey, PrimaryKey, Unique ];

Property myUnitTest As %Integer;

Property myErrCount As %Integer;

Property myMsgBegin As %String;

Property myMsgCount As %Integer;

Property myMsgEnd As %String;

Property Start As %String;

Property TargetServer As %String(MAXLEN = 255);

Property TargetPort As %String;

Property TargetURL As %String(MAXLEN = 255);

Property TargetErrCount As %Integer;

Property TargetMsgBegin As %String;

Property TargetMsgCount As %Integer;

Property TargetMsgEnd As %String;

Property DocIdBefore As %Integer;

Property DocIdAfter As %Integer;

Property MsgBkBefore As %Integer;

Property MsgBkAfter As %Integer;

Property Files As %Integer;

Property zProcessCalc As %Integer [ Calculated, SqlComputeCode = {set {*}=##class(Feeder.Util).GetDateTimeDiff({myMsgBegin},{TargetMsgEnd})}, SqlComputed ];

ClassMethod NewTest(pStart As %String, pFiles As %String) As %Status
{
	Set objTest = ..%New()
	Set objTest.myUnitTest = $Increment(^myUnitTests)
	Set objTest.Start = $H
	Set objTest.Files = pFiles
	Set tSC = objTest.%Save()
	If $$$ISERR(tSC) {
		Do $System.Status.DisplayError(tSC)
	}
	Quit tSC
}

ClassMethod UpdateMyProp(pUnitTest As %String, pProp As %String, pValue As %String) As %Status
{
	Set tSC = $$$OK
	Try {
		If ($Get(pUnitTest,"") = "") Set pUnitTest = $Get(^myUnitTests)
		Set obj = ..%OpenId(pUnitTest)
		Set $PROPERTY(obj,pProp) = pValue
		Set tSC = obj.%Save()
	}
	Catch {
		Set tSC = $$$ERROR($$$GeneralError,"UpdateMyProp error")
		//Do ..DebugStatus(tSC)
	}
	Quit tSC
}

Storage NewStorage1
{
<IdFunction>increment</IdFunction>
<IdLocation>^myUnitTests</IdLocation>
<SQLMap name="Map1">
<Data name="DocIdAfter">
<Delimiter>"^"</Delimiter>
<Piece>15</Piece>
</Data>
<Data name="DocIdBefore">
<Delimiter>"^"</Delimiter>
<Piece>14</Piece>
</Data>
<Data name="Files">
<Delimiter>"^"</Delimiter>
<Piece>2</Piece>
</Data>
<Data name="MsgBkAfter">
<Delimiter>"^"</Delimiter>
<Piece>17</Piece>
</Data>
<Data name="MsgBkBefore">
<Delimiter>"^"</Delimiter>
<Piece>16</Piece>
</Data>
<Data name="Start">
<Delimiter>"^"</Delimiter>
<Piece>1</Piece>
</Data>
<Data name="TargetErrCount">
<Delimiter>"^"</Delimiter>
<Piece>11</Piece>
</Data>
<Data name="TargetMsgBegin">
<Delimiter>"^"</Delimiter>
<Piece>8</Piece>
</Data>
<Data name="TargetMsgCount">
<Delimiter>"^"</Delimiter>
<Piece>9</Piece>
</Data>
<Data name="TargetMsgEnd">
<Delimiter>"^"</Delimiter>
<Piece>10</Piece>
</Data>
<Data name="TargetPort">
<Delimiter>"^"</Delimiter>
<Piece>6</Piece>
</Data>
<Data name="TargetServer">
<Delimiter>"^"</Delimiter>
<Piece>5</Piece>
</Data>
<Data name="TargetURL">
<Delimiter>"^"</Delimiter>
<Piece>7</Piece>
</Data>
<Data name="myErrCount">
<Delimiter>"^"</Delimiter>
<Piece>3</Piece>
</Data>
<Data name="myMsgBegin">
<Delimiter>"^"</Delimiter>
<Piece>12</Piece>
</Data>
<Data name="myMsgCount">
<Delimiter>"^"</Delimiter>
<Piece>4</Piece>
</Data>
<Data name="myMsgEnd">
<Delimiter>"^"</Delimiter>
<Piece>13</Piece>
</Data>
<Global>^myUnitTests</Global>
<Subscript name="1">
<Expression>{myUnitTest}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^Feeder.TestS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
