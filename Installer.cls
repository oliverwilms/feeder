Class App.Installer
{

XData setup
{
<Manifest>
  <Default Name="SourceDir" Value="/opt/feeder/src"/>
  <Default Name="Namespace" Value="FEEDER"/>
  <Default Name="app" Value="feeder" />

  <Namespace Name="${Namespace}" Code="${Namespace}" Data="${Namespace}" Create="yes" Ensemble="1">

    <Configuration>
      <Database Name="${Namespace}" Dir="/opt/${app}/data" Create="yes" Resource="%DB_${Namespace}"/>
    </Configuration>
    <Import File="${SourceDir}" Flags="ck" Recurse="1"/>
    <If Condition='(##class(Security.Applications).Exists("/csp/feeder")=0)'>
      <Log Text="Creating web application /csp/feeder" Level="0"/>
      <RunInstall Class="App.Installer" Method="CreateWebAppFeeder"/>
    </If>
    <If Condition='(##class(Security.Applications).Exists("/restapi")=0)'>
      <Log Text="Creating web application /restapi" Level="0"/>
      <RunInstall Class="App.Installer" Method="CreateWebAppREST"/>
    </If>
  </Namespace>

</Manifest>
}

ClassMethod CreateWebAppFeeder(pVars,pLogLevel,tInstaller) As %Status
{
  Set Namespace = tInstaller.Evaluate("${Namespace}")
  Do tInstaller.PushNS("%SYS")
  Do ##class(Security.System).GetInstallationSecuritySetting(.security)
  If (security="None") {
    Set cspProperties("AutheEnabled") = $$$AutheUnauthenticated
  } Else {
    Set cspProperties("AutheEnabled") = $$$AutheCache // Password
  }
  Set cspName = "/csp/feeder"
  Set cspProperties("NameSpace") = $Get(Namespace,"FEEDER")
  Set cspProperties("Enabled") = 1
  Set cspProperties("AutheEnabled") = $$$AutheUnauthenticated
  Set cspProperties("DeepSeeEnabled") = 1
  Set cspProperties("iKnowEnabled") = 0
  Set cspProperties("Path") = "/voldata/csp/feeder"
  Set cspProperties("Resource") = ""
  Set cspProperties("ServeFiles") = 1
  Set tSC = ##class(Security.Applications).Create(cspName,.cspProperties)
  Do tInstaller.PopNS()
  If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
  Quit $$$OK
}

ClassMethod CreateWebAppREST(pVars,pLogLevel,tInstaller) As %Status
{
  Set Namespace = tInstaller.Evaluate("${Namespace}")
  Do tInstaller.PushNS("%SYS")
  Do ##class(Security.System).GetInstallationSecuritySetting(.security)
  If (security="None") {
    Set cspProperties("AutheEnabled") = $$$AutheUnauthenticated
  } Else {
    Set cspProperties("AutheEnabled") = $$$AutheCache // Password
  }
  Set cspName = "/restapi"
  Set cspProperties("NameSpace") = $Get(Namespace,"FEEDER")
  Set cspProperties("Enabled") = 1
  Set cspProperties("DeepSeeEnabled") = 1
  Set cspProperties("iKnowEnabled") = 0
  Set cspProperties("DispatchClass") = "Feeder.REST"
  Set cspProperties("Resource") = ""
  Set cspProperties("ServeFiles") = 1
  Set tSC = ##class(Security.Applications).Create(cspName,.cspProperties)
  Do tInstaller.PopNS()
  If $$$ISERR(tSC) Throw ##class(%Installer.Exception).CreateFromStatus(tSC)
  Quit $$$OK
}

ClassMethod setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
  #; Let XGL document generate code for this method. 
  Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "setup")
}

}
