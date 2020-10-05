Include (%occInclude, Ensemble)

Class Feeder.Ensemble
{

/// Enable or disable a ConfigItem in a Production. The Production may be running or not.
/// The pConfigItemName argument gives the name of the config item to be enabled or disabled.
/// In the case of multiple matching items with the same config name, if any is already enabled then
///  the pEnable=1 option will do nothing and the pEnable=0 option will disable the running matching
///   production item, or if not running then the first matching enabled item that it finds.
///   
/// See method Ens.Director.ParseConfigName() for full syntax of the ConfigItem name specification string.
ClassMethod EnableConfigItem(pConfigItemName As %String, pEnable As %Boolean = 1, pDoUpdate As %Boolean = 1) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.Ensemble - EnableConfigItem")
	Set tSC = ##class(Ens.Director).EnableConfigItem(pConfigItemName, pEnable, pDoUpdate)
	Do ##class(Feeder.Util).DebugStatus(tSC)
	Quit tSC
}

ClassMethod ExecuteQueryOneValue(pQuery As %String, ByRef pResult As %String) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.Ensemble - ExecuteQueryOneValue")
	Do ##class(Feeder.Util).DebugTEST("pQuery = "_pQuery)
	Set pResult = ""
	Set rs = ##class(%ResultSet).%New()
	Set tSC = rs.Prepare(pQuery)
	Do ##class(Feeder.Util).DebugStatus(tSC)
	If $$$ISOK(tSC) {
		Set tSC = rs.Execute()
		Do ##class(Feeder.Util).DebugStatus(tSC)
		If $$$ISOK(tSC), rs.Next() Set pResult = rs.GetData(1)
	}
	Do rs.Close()
	Set rs = ""
	Do ##class(Feeder.Util).DebugTEST("pResult = "_pResult)
	Quit tSC
}

/// Copied from %UnitTest.TestProduction
/// Define an array with the macros used in this class from the definitions in the production when available.
ClassMethod GetMacros(Output MacroVars As %String) [ CodeMode = objectgenerator, Internal, Private ]
{
	If '$D(^%SYS("Ensemble","InstalledNamespace",$namespace)) Quit $$$OK
	If '$D(^rINC("EnsConstants")) Quit $$$OK // sanity check
	Do %code.WriteLine(" #Include EnsConstants")
	Do %code.WriteLine(" Set MacroVars(""eProductionStateStopped"") = $$$eProductionStateStopped")
	Do %code.WriteLine(" Set MacroVars(""eProductionStateRunning"") = $$$eProductionStateRunning")
	Do %code.WriteLine(" Set MacroVars(""eLogTypeInfo"") = $$$eLogTypeInfo")
	Do %code.WriteLine(" Set MacroVars(""eLogTypeError"") = $$$eLogTypeError")
	Do %code.WriteLine(" Set MacroVars(""eLogTypeTrace"") = $$$eLogTypeTrace")
	Do %code.WriteLine(" Set MacroVars(""eLogTypeWarning"") = $$$eLogTypeWarning")
	Do %code.WriteLine(" Set MacroVars(""eLogTypeAlert"") = $$$eLogTypeAlert")
	Do %code.WriteLine(" Set MacroVars(""eLogTypeAssert"") = $$$eLogTypeAssert")
	Do %code.WriteLine(" Set MacroVars(""eMessageTypeResponse"") = $$$eMessageTypeResponse")
	Do %code.WriteLine(" Quit")
	Quit $$$OK
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
	Do ##class(Feeder.Util).DebugTEST("Feeder.Ensemble - GetEventLog")
	// First, build cross table for record types: strings to Ensemble constants
	Do ..GetMacros(.Macro)
	Kill Trans
	Set Trans("info") = Macro("eLogTypeInfo")
	Set Trans("error") = Macro("eLogTypeError")
	Set Trans("trace") = Macro("eLogTypeTrace")
	Set Trans("warning") = Macro("eLogTypeWarning")
	Set Trans("alert") = Macro("eLogTypeAlert")
	Set Trans("assert") = Macro("eLogTypeAssert")
	Do ##class(Feeder.Util).DebugMerge("Macro",.Macro)
	Set New = 0
	Set baseId = 0 + $Get(baseId)
	Set type = $Zcvt(type,"l"), fx = 0
	If type="all" {
		Set tx = ""
		}
	ElseIf type="info" {
		Set tx = Trans("info")
	}
	ElseIf type="infouser" {
		Set tx = Trans("info"), fx = 1
	}
	ElseIf type="startstop" {
		Set tx = Trans("info"), fx = 2
	}
	ElseIf type="error" {
		Set tx = Trans("error")
	}
	ElseIf type="trace" {
		Set tx = Trans("trace")
	}
	ElseIf type="warning" {
		Set tx = Trans("warning")
	}
	ElseIf type="alert" {
		Set tx = Trans("alert")
	}
	ElseIf type="assert" {
		Set tx = Trans("assert")
	}
	ElseIf type="other" {
		Set tx = "other"
	}
	Else  {
		Quit $$$ERROR($$$GeneralError,"Unrecognized event log type '"_type_"'")
	}
	Set tx = $Zcvt(tx,"l")
	Set query = "SELECT ID,TimeLogged,Type,Job,SessionId,ConfigName,SourceClass,SourceMethod,Text,Stack"
	Set query = query_" FROM Ens_Util.Log WHERE ID>="_baseId_" ORDER BY ID"
	Set rs = ##class(%ResultSet).%New()
	Set rs.RuntimeMode = 2 // external
	Set tSC = rs.Prepare(query)
	If $$$ISERR(tSC) Quit tSC
	Set tSC = rs.Execute()
	If $$$ISERR(tSC) Quit tSC
	While rs.Next() {
		If tx'="", tx'="other" {
			Set t = $Zcvt(rs.Get("Type"),"l")
			If Trans(t)'=tx Continue
			If fx {
				// Check whether it's start / stop / update
				Set fss = 0, sc = rs.Get("SourceClass"), sm = rs.Get("SourceMethod")
				If sc="Ens.Director", (sm="StartProduction") || (sm="StopProduction") || (sm="UpdateProduction") {
					Set fss=1
				}
				If sc="Ens.Job", sm="Start" {
					Set fss=1
				}
				If fx=1, fss Continue
				If fx=2, 'fss Continue
			}
		}
		If tx="other" {
			If $D(Trans(t)) Continue
		}
		If name'="", rs.Get("ConfigName")'=name Continue
		Set v=$I(v), New = New+1
		For c = "ID","TimeLogged","Type","Job","SessionId","ConfigName","SourceClass","SourceMethod","Text","Stack" {
			Set v(v,c) = rs.Get(c)
		}
	}
	Do rs.Close()
	Set rs = ""
	Do ##class(Feeder.Util).DebugMerge("v",.v)
	Do ##class(Feeder.Util).DebugTEST("ErrCount = "_New)
	Quit $$$OK
}

ClassMethod GetMessages(type As %String = "all", name As %String = "", baseId As %Integer, ByRef v As %String, Output New As %Integer, Output Begin As %String, Output End As %String) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.Ensemble - GetMessages")
	Set (Begin,End) = ""
	Set New = 0
	Set baseId = 0 + $Get(baseId)
	Set col1 = "ID, Banked, BusinessProcessId, CorrespondingMessageId, Description, ErrorStatus, Invocation, IsError, "
	Set col2 = "MessageBodyClassName, MessageBodyId, Priority, Resent, ReturnQueueName, SessionId, "
	Set col3 = "SourceBusinessType, SourceConfigName, Status, SuperSession, "
	Set col4 = "TargetBusinessType, TargetConfigName, TargetQueueName, TimeCreated, TimeProcessed, Type"
	Set query = "SELECT "_col1_col2_col3_col4
	Set query = query_" FROM Ens.MessageHeader WHERE ID>="_baseId_" ORDER BY ID"
	Set rs = ##class(%ResultSet).%New()
	Set rs.RuntimeMode = 2 // external
	Set tSC = rs.Prepare(query)
	If $$$ISERR(tSC) Quit tSC
	Set tSC = rs.Execute()
	If $$$ISERR(tSC) Quit tSC
	While rs.Next() {
		Set source = rs.Get("SourceConfigName")
		If (source = "Ens.ScheduleService") Continue
		If (name '= ""),(name '= source) Continue
		Set New = New + 1
		/*
		Set v=$I(v)
		For c = "ID","TimeCreated","TimeProcessed","Type","MessageBodyId","SessionId","Status" {
			Set v(v,c) = rs.Get(c)
		}
		*/
		If (Begin = "") Set Begin = rs.Get("TimeCreated")
		Set End = rs.Get("TimeProcessed")
	}
	Do rs.Close()
	Set rs = ""
	//Do ##class(Feeder.Util).DebugMerge("v",.v)
	Do ##class(Feeder.Util).DebugTEST("MsgCount = "_New)
	Do ##class(Feeder.Util).DebugTEST("Begin = "_Begin)
	Do ##class(Feeder.Util).DebugTEST("End = "_End)
	Quit $$$OK
}

ClassMethod GetProductionStatus(Output pProductionName As %String, Output pState As %String) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.Ensemble - GetProductionStatus")
	Set tSC = ##class(Ens.Director).GetProductionStatus(.pProductionName, .pState)
	Do ##class(Feeder.Util).DebugTEST("pProductionName = "_pProductionName)
	Do ##class(Feeder.Util).DebugTEST("pState = "_pState)
	If pState = $$$eProductionStateRunning Set pState = "Running" Quit $$$OK
	If pState = $$$eProductionStateStopped Set pState = "Stopped" Quit $$$OK
	If pState = $$$eProductionStateSuspended Set pState = "Suspended" Quit $$$OK
	If pState = $$$eProductionStateTroubled Set pState = "Troubled" Quit $$$OK
	Quit $$$OK
}

ClassMethod GetSetting(production As %String = "", configName As %String = "", setting As %String = "", Output value As %String) As %Status
{
	Kill value
	Quit ..ChangeOrGetSetting("Get", production, configName, setting, .value)
}

/// Internal method called by GetSetting and ChangeSetting.
ClassMethod ChangeOrGetSetting(operation As %String = "Get", production As %String = "", configName As %String = "", setting As %String = "", ByRef value As %String = "") As %Status [ Internal, Private ]
{
	Set op = (operation="Change") // 0 = Get, 1 = Change
	If $c(0)[production Set production = ##class(Ens.Director).GetActiveProductionName()
	If production="" Quit $$$ERROR($$$GeneralError, "Missing production name")
	If $c(0)[configName Quit $$$ERROR($$$GeneralError, "Missing config name")
	If $c(0)[setting Quit $$$ERROR($$$GeneralError, "Missing setting name")
	If $c(0)[value Set value = "" If op Quit $$$ERROR($$$GeneralError, "Missing value")
	Set oItem = ""
	Set rsql = ##class(%ResultSet.SQL).%Prepare("select %id as mid from Ens_Config.Item where Production='"_production_"' and Name='"_configName_"' order by Enabled desc")
	If rsql.%SQLCODE=100 Quit $$$ERROR($$$GeneralError, "Can't find item: Production '"_production_"' ConfigName '"_configName_"'")
	If '(rsql.%SQLCODE) If rsql.%Next() Set oItem = rsql.mid
	If '$IsObject(oItem) Quit $$$ERROR($$$GeneralError, "Can't open item: Production '"_production_"' ConfigName '"_configName_"' Error: "_rsql.%SQLCODE_" ("_rsql.%Message_")")
	// Look for existing setting
	Set f = 0, new = 0, ok = 1
	For i = 1:1:oItem.Settings.Count() {
		Set o = oItem.Settings.GetAt(i)
		If o.Name=setting Set f = 1, v = o.Value Quit
	}
	If f, 'op Set value = v Quit $$$OK // Get
	If 'f Set new = 1, oS = ##class(Ens.Config.Setting).%New() // It's a new setting
	// Look up all host settings
	Set f = 0
	Set rs = ##class(%ResultSet).%New()
	Set rs.ClassName = oItem.ClassName
	Set rs.QueryName = "EnumerateSettings"
	If (rs.QueryIsValid()) {
		Set tSC = rs.Execute()
		While rs.Next() && 'f {
			Set name = $G(rs.Data("Name"))
			If name=setting {
				If 'f Set f = 1 Set:new oS.Target = "Host"
				If 'op Set v = oS.Value
				Else  Set ok = $classmethod(oItem.ClassName, setting_"IsValid", value)
				Quit
			}
		}
	}
	Do rs.Close()
	Set rs = ""
	If f, 'op Set value = v Quit $$$OK // Get
	If 'f {
		// Look up all adapter settings
		Set rs = ##class(%ResultSet).%New()
		Set rs.ClassName = oItem.AdapterClassName()
		Set rs.QueryName = "EnumerateSettings"
		If (rs.QueryIsValid()) {
			Set tSC = rs.Execute()
			While (rs.Next()) && 'f {
				Set name = $G(rs.Data("Name"))
				If name=setting {
					If 'f Set f = 1 Set:new oS.Target = "Adapter"
					If 'op Set v = oS.Value
					Else  Set ok = $classmethod(oItem.AdapterClassName(), setting_"IsValid", value)
					Quit
				}
			}
		}
		Do rs.Close()
		Set rs = ""
	}
	If f, 'op Set value = v Quit $$$OK // Get
	If 'f || 'op Quit $$$ERROR($$$GeneralError, "Can't find setting name '"_setting_"' for Production '"_production_"' ConfigName '"_configName_"'") Quit
	If 'ok Quit $$$ERROR($$$GeneralError, "Invalid value '"_value_"' for setting name '"_setting_"' for Production '"_production_"' ConfigName '"_configName_"'") Quit
	If new {
		Set oS.Name = setting
		Set oS.Value = value
		Do oItem.Settings.Insert(oS)
		}
	Else  {
		Set o.Value = value
	}
	Set s = oItem.%Save()
	Quit s
}

/// https://community.intersystems.com/post/adding-business-hosts-programmatically-pre-existing-production
ClassMethod InsertConfigItem(productionName As %Dictionary.CacheClassname, name As %String = "", class As %Dictionary.CacheClassname) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.Ensemble - InsertConfigItem")
	If $Get(productionName) = "" Set productionName = ##class(Ens.Director).GetActiveProductionName()
	Do ##class(Feeder.Util).DebugTEST("productionName ="_productionName)
    Set production = ##class(Ens.Config.Production).%OpenId(productionName)
	Do ##class(Feeder.Util).DebugTEST("production ="_production)
	If '$IsObject(production) {
		Set tSC = $$$ERROR($$$GeneralError,"Production error")
	    Do ##class(Feeder.Util).DebugStatus(tSC)
		Quit tSC
	}
    Set item = ##class(Ens.Config.Item).%New()
	Do ##class(Feeder.Util).DebugTEST("item ="_item)
    Set item.PoolSize = 1
    Set item.Name = name
    Set item.ClassName = class
    Set:item.Name="" item.Name = item.ClassName
    Set item.Enabled = $$$YES
    Set tSC = production.Items.Insert(item)
    Do ##class(Feeder.Util).DebugStatus(tSC)
    Quit:$$$ISERR(tSC) tSC
    //Set sc = $$$AuditModifyProductionConfig(production.Name,item.Name,$$$Text("Item added to production using generator in " _ $classname()))
    Quit:$$$ISERR(tSC) tSC   
    Set tSC = ##class(EnsPortal.Template.prodConfigSCPage).CallProductionUpdateAndSaveToClass(production,"","SaveProduction")
    Do ##class(Feeder.Util).DebugStatus(tSC)
	Quit tSC
}

/// This method starts the production running.
/// pProductionName: The name of the production to be started.  If not specified, defaults to the "last" production used (if any).
ClassMethod StartProduction(pProductionName As %String = {$GET(^Ens.Configuration("csp","LastProduction"))}) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.Ensemble - StartProduction")
	Try {
		Set tSC = ##class(Ens.Director).StartProduction(pProductionName)
	} Catch {
		Do ##class(Feeder.Util).DebugTEST("Something went wrong")
	}
	Do ##class(Feeder.Util).DebugStatus(tSC)
	Quit tSC
}

/// This method stops the running production.
/// pTimeout: How many seconds to wait for the jobs to go down.
/// pForce:   It indicates if we should forcefully kill the jobs which can not stop by themselves.
ClassMethod StopProduction(pTimeout As %Numeric = 10, pForce As %Boolean = 0) As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.Ensemble - StopProduction")
	Set tSC = ##class(Ens.Director).StopProduction(pTimeout, pForce)
	Do ##class(Feeder.Util).DebugStatus(tSC)
	Quit tSC
}

ClassMethod TEST(FILENAME As %String = "") As %Status
{
	Do ##class(Feeder.Util).DebugTEST("Feeder.Ensemble - TEST")
	Quit $$$OK
}

ClassMethod ValidateConfigItem(pName As %String = "") As %Status
{
	Set tProdName = ##class(Ens.Director).GetActiveProductionName()
	Set strWhere = "Name = '"_pName_"' and Production = '"_tProdName_"'"
	Set strSQL = "select * from Ens_Config.Item where "_strWhere
	Set tStatement = ##class(%SQL.Statement).%New()
	Set qStatus = tStatement.%Prepare(strSQL)
	If $$$ISERR(qStatus) {
		Do ##class(Feeder.Util).DebugTEST("strSQL = "_strSQL)
		Set msg = $system.Status.GetOneErrorText(qStatus)
		Do ##class(Feeder.Util).DebugTEST("Utility:ValidateConfigItem %Prepare failed : "_msg)
		Quit qStatus
	}
	#dim rset As %SQL.StatementResult
	Set rset = tStatement.%Execute()
	If rset.%SQLCODE'=0 {
		//rset.%SQLCODE=-361 { WRITE !,"Query exists: ",rset.%Message }
		Do ##class(Feeder.Util).DebugTEST("Utility:ValidateConfigItem rset.%SQLCODE : "_rset.%SQLCODE)
		Do ##class(Feeder.Util).DebugTEST("Utility:ValidateConfigItem rset.%Message : "_rset.%Message)
		Quit $$$ERROR($$$GeneralError,"Unable to run SQL "_strSQL)
	}
	While rset.%Next() {
		Set recCount = rset.%ROWCOUNT
		//Do ##class(Feeder.Util).DebugTEST("%ROWCOUNT : "_recCount)
		Set tEnabled = rset.Enabled
		//Do ##class(Feeder.Util).DebugTEST("tEnabled : "_tEnabled)
	}
	Quit ($Get(tEnabled) = 1)
}

}
