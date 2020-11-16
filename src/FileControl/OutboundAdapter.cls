/* Copyright (c) 2020 by InterSystems Corporation.
   Cambridge, Massachusetts, U.S.A.  All rights reserved.
   Confidential property of InterSystems Corporation. */

Include %sySystem

/// An Outbound Adapter class providing methods used to write data to files and do other OS level file manipulations.
Class FileControl.OutboundAdapter Extends EnsLib.File.OutboundAdapter [ ClassType = "", Inheritance = right, ProcedureBlock, System = 4 ]
{

/// Enter Queue name for inbound FileControl.
Property FileQueue As %String(MAXLEN = 1000);

Parameter SETTINGS = "RegistryID:Basic:selector?context={Ens.ServiceRegistry.External.ContextSearch/Services?Protocols_1=File},FilePath:Basic:directorySelector,FileQueue:Basic,Overwrite,Charset::selector?context={Ens.ContextSearch/CharacterSets},OpenTimeout";

/// Combine base Filename with Directory and filename Spec that may contain timestamp and counter templates
Method CreateFilename(
	pFilename As %String,
	pSpec As %String,
	pIsVMS As %Boolean,
	pDirectory As %String,
	pLocal As %Boolean) As %String
{
	#; Override to use FilePath as pDirectory in case %+ file existence-checking is called for
	Set:'$D(pDirectory)#2 pDirectory=..fixPath(..FilePath)
	Try {
		Set oBusinessHost = ..BusinessHost
		If $IsObject(oBusinessHost) Set tConfig = oBusinessHost.%ConfigName
	} Catch {
		Set tConfig = ""
	}
	Set tHost = $SYSTEM.INetInfo.LocalHostName()
	Set tOriginal = pFilename
	Set tQQ = $Increment(^TESTFilesDLAQQ)
	Set tLog = ##Class(%File).GetFilename(..CreateTimestamp(.pFilename,.pSpec,.pIsVMS,pDirectory,.pLocal))
	Set tFileQueue = ..FileQueue
	Set tSC = $$OUTFILE^ZFILECONTROL(tHost,tQQ,tConfig,pDirectory,tLog,tOriginal,tFileQueue)
	Quit tLog
}

}
