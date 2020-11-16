Class FileControl.CCSFiles Extends %Persistent [ StorageStrategy = NewStorage1 ]
{

Parameter AllowDuplicateFilename = 1;

Parameter AllowDuplicateInterval = 2;

Parameter DataGlobal = "^HS.Local.VFC75.CCSFiles";

Parameter DebugGlobal = "^HS.Local.VFC75.CCSDebug";

Parameter FilenameIndexGlobal = "^HS.Local.VFC75.CCSIndex";

Index NewIndex1 On (HostNode, Sequence, FilePath, Filename) [ IdKey, PrimaryKey, Unique ];

Property HostNode As %String(MAXLEN = 255);

Property Sequence As %Integer;

Property FilePath As %String(MAXLEN = 255);

Property Filename As %String(MAXLEN = 255);

Property FileSize As %Integer;

Property FileDateCreated As %String;

Property FileDateModified As %String;

/// The creation date for this file (rounded to the second).
Property DateCreated As %Date [ Calculated ];

/// The last modified date for this file (rounded to the second).
Property DateModified As %Date [ Calculated ];

Property zFileTimestamp As %String [ Calculated, SqlComputeCode = {set {*}=##class(HS.Local.VA.eSCM.DMLSS.File.LostFiles).zFileTimestamp({Filename})}, SqlComputed ];

ClassMethod DebugCCS(pMessage As %String = "") As %Status
{
	If (..#DebugGlobal '= "") {
		Set tIncrement = $Increment(@..#DebugGlobal)
		Set @..#DebugGlobal@(tIncrement) = $ZDateTime($NOW(),8,1,3)_" : "_$JOB_" : "_pMessage
	}
	Quit $$$OK
}

ClassMethod PreProcess(
	pOriginalFilename As %String = "precopy.sh",
	pFilePath As %String = "/ICS") As %Status
{
	Set tSC = ..DebugCCS("PreProcess("_pOriginalFilename_","_pFilePath_")")
	If (pFilePath '= "") {
		Set pOriginalFilename = ##class(%File).NormalizeFilename(pOriginalFilename,pFilePath)
		Set tSC = ..DebugCCS("pOriginalFilename = "_pOriginalFilename)
	}
	Set tDataGlobal = ..#DataGlobal
	Set tFilename = ##class(%File).GetFilename(pOriginalFilename)
	Set tIndexGlobal = ..#FilenameIndexGlobal
	Set tPath = ##class(%File).GetDirectory(pOriginalFilename)
	Set tPathKey = ##class(HS.Local.VA.eSCM.DMLSS.Utility).GetKey("Path",tPath)
	Set tData = $Data(@tIndexGlobal@(tFilename))
	Set tSC = ..DebugCCS("tData = "_tData)
	If (tData = 0) {
		Lock @tIndexGlobal@(tFilename):1
		Set tLock = $TEST
	} ElseIf ..#AllowDuplicateFilename {
		Lock @tIndexGlobal@(tFilename):1
		Set tLock = $TEST
	}
	Set tSC = ..DebugCCS("tLock1 = "_$Get(tLock,"<UNDEFINED>"))
	Set tLock = $Get(tLock,0)
	If 'tLock Quit tLock
	If tData {
		Set tThis = ##class(%File).GetFileDateCreated(pOriginalFilename)
		//Set tData = @tIndexGlobal@(tFilename)
		Set tThat = $Piece(@tIndexGlobal@(tFilename),"^",2)
		Set tDiff = ##class(HS.Local.VA.eSCM.DMLSS.Utility).GetDateTimeDiff(tThat,tThis,"SQL_TSI_SECOND")
		Set tSC = ..DebugCCS("tThis = "_tThis)
		Set tSC = ..DebugCCS("tThat = "_tThat)
		Set tSC = ..DebugCCS("tDiff = "_tDiff)
		If (tDiff < ..#AllowDuplicateInterval) {
			Set tLock = $$$ERROR($$$GeneralError,"Duplicate Filename too soon")
			Lock  // Unlock
			Set tSC = ..DebugCCS("tLock2 = $$$ERROR($$$GeneralError,""Duplicate Filename too soon"")")
			Quit tLock
		}
	}
	Set @tIndexGlobal@(tFilename) = ""
	Set tNode = "*"
	Set tSequence = $Increment(@tDataGlobal)
	//Set tPath = "/ICS/dmlss/creditcard/ccsPreprocess/"
	//Set tFilename = pOriginalFilename
	//Set @tDataGlobal@(tNode,tSequence,tPath,tFilename) = tFilename
	Set tF = ##class(%File).%New(pOriginalFilename)
	Set tData = tF.Size_"^"_tF.DateCreated_"^"_tF.DateModified
	Set @tDataGlobal@(tNode,tSequence,tPath,tFilename) = tData
	Set @tIndexGlobal@(tFilename) = tData
	Set tF = ""
	Lock  // Unlock
	Set tSC = ..DebugCCS("tLock = $$$OK")
	Quit $$$OK
}

ClassMethod zFileTimestamp(pFilename As %String = "") As %String
{
	Set u = "_"
	Set len = $Length(pFilename,u)
	Set strTimestamp = $Piece(pFilename,u,(len-1),*)
	Quit strTimestamp
}

ClassMethod zLostTimestamp(pLostTimestamp As %String = "") As %String
{
	Set strTimestamp = $ZDATETIME(pLostTimestamp)
	Quit strTimestamp
}

Storage NewStorage1
{
<SQLMap name="Map1">
<Data name="FileDateCreated">
<Delimiter>"^"</Delimiter>
<Piece>2</Piece>
</Data>
<Data name="FileDateModified">
<Delimiter>"^"</Delimiter>
<Piece>3</Piece>
</Data>
<Data name="FileSize">
<Delimiter>"^"</Delimiter>
<Piece>1</Piece>
</Data>
<Global>^HS.Local.VFC75.CCSFiles</Global>
<Subscript name="1">
<Expression>{HostNode}</Expression>
</Subscript>
<Subscript name="2">
<Expression>{Sequence}</Expression>
</Subscript>
<Subscript name="3">
<Expression>{FilePath}</Expression>
</Subscript>
<Subscript name="4">
<Expression>{Filename}</Expression>
</Subscript>
<Type>data</Type>
</SQLMap>
<StreamLocation>^HS.Local.VA.eSCMDCDB.CCSFilesS</StreamLocation>
<Type>%Storage.SQL</Type>
}

}
