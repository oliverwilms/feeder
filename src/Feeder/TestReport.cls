Class Feeder.TestReport
{

ClassMethod Go(pUnitTest As %String = "") As %Status
{
	Set tSC = $$$OK
	If (pUnitTest = "") Set pUnitTest = $Get(^myUnitTests)
	Set tSC = ..WriteUnitTestReport(pUnitTest)
	Quit tSC
}

/// Most likely we need to report on recent tests - Do we need index?
ClassMethod WriteResponseReport(pUnitTest As %String = "") As %Status
{
	Set tSC = $$$OK
	Set query = "SELECT StatusCode,ReasonPhrase"
	Set query = query_" FROM Feeder.ResponseTime WHERE myUnitTest="_pUnitTest
	Set rs = ##class(%ResultSet).%New()
	Set rs.RuntimeMode = 2 // external
	Set tSC = rs.Prepare(query)
	If $$$ISERR(tSC) Quit tSC
	Set tSC = rs.Execute()
	If $$$ISERR(tSC) Quit tSC
	While rs.Next() {
		Set tStatusCode = rs.Get("StatusCode")
		If (tStatusCode '= "") {
			If $Increment(tStatusCode(tStatusCode)) = 1 {
				Set tReasonPhrase(tStatusCode) = rs.Get("ReasonPhrase")
			}
		}
	}
	Do rs.Close()
	Set tStatusCode = ""
	For {
		Set tStatusCode = $Order(tStatusCode(tStatusCode),1,tStatusCount)
		If (tStatusCode = "") Quit
		Write "  ",tStatusCount," responses were ",tStatusCode," / ",$Get(tReasonPhrase(tStatusCode)),!
	}
	Quit tSC
}

ClassMethod WriteUnitTestReport(pUnitTest As %String = "") As %Status
{
	Set tSC = $$$OK
	Set objUnitTest = ##class(Feeder.Test).%OpenId(pUnitTest)
	If '$IsObject(objUnitTest) { Quit tSC }
	Write "UnitTest ",pUnitTest," began ",##class(Util).TimeAdjust(objUnitTest.Start),!
	Set tMyMsgBegin = ##class(Util).Timeout(objUnitTest.myMsgBegin)
	Set tMyMsgEnd = ##class(Util).Timeout(objUnitTest.myMsgEnd)
	Set tMyMsgDiff = ##class(Util).GetDateTimeDiff(tMyMsgBegin,tMyMsgEnd)
	Set tTargetServer = ##class(Util).TranslateServer(objUnitTest.TargetServer)
	If ($Extract(tTargetServer,1,1) = "") Set tTargetServer = "ALB"
	Try {
		// <DIVIDE> error if tMyMsgDiff is zero
		Set tPerformance = $FNUMBER((objUnitTest.myMsgCount / tMyMsgDiff * 1000),"",3)
	}
	Catch {
		Set tPerformance = tMyMsgDiff
	}
	Write "  It sent ",objUnitTest.myMsgCount," messages between ",tMyMsgBegin," and ",tMyMsgEnd," (",tPerformance," mps)",!
	Write "    to ",tTargetServer,":",objUnitTest.TargetPort,objUnitTest.TargetURL,!
	//Write "  Outbound "_$Get(tPerformance)_" messages per second",!
	Set tSC = ..WriteResponseReport(pUnitTest)
	//Write "  DocID before: ",objUnitTest.DocIdBefore," - after: ",objUnitTest.DocIdAfter,!
	Set tSC = ..WriteUnitTestReportDocId(pUnitTest)
	//Set tSC = ..WriteUnitTestReportMsgBLog(pUnitTest,.pNodes)
	Write "  MsgBk before: ",objUnitTest.MsgBkBefore," - after: ",objUnitTest.MsgBkAfter,!
	Set tSC = ..WriteUnitTestReportMsgBank(pUnitTest,.pNodes)
	Set objUnitTest = ""
	Quit tSC
}

ClassMethod WriteUnitTestReportDocId(pUnitTest As %String = "") As %Status
{
	Set tSC = $$$OK
	Set objUnitTest = ##class(Feeder.Test).%OpenId(pUnitTest)
	If '$IsObject(objUnitTest) { Quit tSC }
	Set tDocIdBefore = objUnitTest.DocIdBefore
	Set (tDocIdAfter,tDocIdExtra) = objUnitTest.DocIdAfter
	Set objUnitTest = ""
	Set objUnitTest = ##class(Feeder.Test).%OpenId(pUnitTest + 1)
	If $IsObject(objUnitTest) {
		Set tDocIdExtra = objUnitTest.DocIdBefore
	} Else {
		Set tSC = ##class(Util).GetDocumentId(0,.tDocIdExtra)
	}
	Set objUnitTest = ""
	Set tDocIdCount = tDocIdExtra - tDocIdBefore
	If (tDocIdCount < 2) { Quit tSC }
	Set objDocId = ##class(HS.Local.VA.eSCM.Common.DocumentIDTable).%OpenId(tDocIdBefore + 1)
	If '$IsObject(objDocId) { Quit tSC }
	Set tMyMsgBegin = ##class(Util).Timeout(objDocId.DocIDInserted)
	Set objDocId = ""
	Set objDocId = ##class(HS.Local.VA.eSCM.Common.DocumentIDTable).%OpenId(tDocIdExtra)
	If '$IsObject(objDocId) { Quit tSC }
	Set tMyMsgEnd = ##class(Util).Timeout(objDocId.DocIDInserted)
	Set objDocId = ""
	Set tMyMsgDiff = ##class(Util).GetDateTimeDiff(tMyMsgBegin,tMyMsgEnd)
	//Write "UnitTest ",pUnitTest," began ",objUnitTest.Start,!
	//Write "  It sent ",objUnitTest.myMsgCount," messages between ",tMyMsgBegin," and ",tMyMsgEnd," (",tMyMsgDiff," ms)",!
	//Write "    to ",tTargetServer,":",objUnitTest.TargetPort,objUnitTest.TargetURL,!
	//Write "  DocID before: ",objUnitTest.DocIdBefore," - after: ",objUnitTest.DocIdAfter,!
	Set tSpace = $Select((tDocIdExtra = tDocIdAfter):"    ",1:"****")
	Write tSpace,tDocIdCount," documents inserted between ",tMyMsgBegin," and ",tMyMsgEnd," (",tMyMsgDiff," ms)",!
	Quit tSC
}

ClassMethod WriteUnitTestReportMsgBank(pUnitTest As %String = "", ByRef pNodes) As %Status
{
	//Write "  MsgBk before: ",objUnitTest.MsgBkBefore," - after: ",objUnitTest.MsgBkAfter,!
	Set pDEBUG = 0
	Set tSC = ##class(Util).GetMsgBankReport(0,pUnitTest,.pMsgBankReport,pDEBUG)
	Set tDelim = $Extract(pMsgBankReport,1)
	Set tMsgBankCount = $Piece(pMsgBankReport,tDelim,2)
	Set tDetails = ""
	If tMsgBankCount {
		Set tMyMsgBegin = $Piece(pMsgBankReport,tDelim,3)
		Set tMyMsgEnd = $Piece(pMsgBankReport,tDelim,4)
		Set tMyMsgDiff = ##class(Util).GetDateTimeDiff(tMyMsgBegin,tMyMsgEnd)
		Set tMyMsgBegin = ##class(Util).Timeout(tMyMsgBegin)
		Set tMyMsgEnd = ##class(Util).Timeout(tMyMsgEnd)
		Set tDetails = " between "_tMyMsgBegin_" and "_tMyMsgEnd_" ("_tMyMsgDiff_" ms)"
	}
	Write "    ",tMsgBankCount," messages banked",tDetails,!
	Set pNodes = ""
	For {
		Set pNodes = $Order(pMsgBankReport("NodeId",pNodes))
		If pNodes = "" Quit
		Set pNodes(pNodes,"MsgBankCount") = $Get(pNodes(pNodes,"MsgBankCount")) + $Get(pMsgBankReport("NodeId",pNodes))
		Set pNodes(pNodes,"MsgBankBegin") = $Get(pMsgBankReport("NodeId",pNodes,"Begin"))
		Set pNodes(pNodes,"MsgBankEnd") = $Get(pMsgBankReport("NodeId",pNodes,"End"))
	}

	Set pNodes = ""
	For {
		Set pNodes = $Order(pNodes(pNodes))
		If pNodes = "" Quit
		Set tMsgBankCount = $Get(pNodes(pNodes,"MsgBankCount"),0)
		Set tDetails = ""
		If tMsgBankCount {
			Set tMyMsgBegin = ##class(Util).Timeout($Get(pNodes(pNodes,"MsgBankBegin")))
			Set tMyMsgEnd = ##class(Util).Timeout($Get(pNodes(pNodes,"MsgBankEnd")))
			Set tMyMsgDiff = ##class(Util).GetDateTimeDiff(tMyMsgBegin,tMyMsgEnd)
			Set tDetails = " between "_tMyMsgBegin_" and "_tMyMsgEnd_" ("_tMyMsgDiff_" ms)"
		}
		Write "  Node ",pNodes," sent ",tMsgBankCount," mess.",tDetails,!
	}
	Write !
	Set tSource = ""
	For {
		Set tSource = $Order(pMsgBankReport("Source",tSource))
		If tSource = "" Quit
		Write "  Source ",tSource," banked ",$Get(pMsgBankReport("Source",tSource))," mess.",!
	}
	Write !
	Set tTarget = ""
	For {
		Set tTarget = $Order(pMsgBankReport("Target",tTarget))
		If tTarget = "" Quit
		Write "  Target ",tTarget," banked ",$Get(pMsgBankReport("Target",tTarget))," mess.",!
	}
	Quit tSC
}

}
