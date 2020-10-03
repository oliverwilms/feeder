Class Feeder.FeederProduction Extends Ens.Production
{

/*
For new namespaces, InterSystems recommends that you specify different databases for routines and globals.

// https://docs.intersystems.com/irisforhealth20201/csp/docbook/Doc.View.cls?KEY=EGMG_storage
In most cases, productions are defined and run in the same namespace, but you can use InterSystems IRIS package mapping 
	to make a production class visible in a namespace other than the one it is defined in. 
	If you use package mapping and a production is visible in more than one namespace, 
	you should designate only one of these namespaces to compile and run the production, 
	You should not compile, modify, or run the production in any other namespace. 
	If you run or modify the same production in more than one namespace it can cause failures that are hard to diagnose. 
	Under no circumstances should you do this. 
	If you do not use package mapping to map a database to a namespace you do not need to be concerned about this issue.

// https://docs.intersystems.com/irisforhealth20201/csp/docbook/DocBook.UI.Page.cls?KEY=EGMG_C175393
You should always compile the production on the system that it is running. 
	Although you can compile InterSystems IRIS code on one system and copy the database “pre-compiled” to another system, 
	you should not attempt this with interoperability-enabled namespaces.
*/
XData ProductionDefinition
{
<Production Name="Feeder.FeederProduction" TestingEnabled="true" LogGeneralTraceEvents="true">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Setting Target="Adapter" Name="AlertNotificationManager">Ens.AlertNotification</Setting>
  <Setting Target="Adapter" Name="AlertNotificationOperation">EMail.AlertOperation</Setting>
  <Item Name="Ens.Alert" Category="Alert" ClassName="Ens.Alerting.AlertManager" PoolSize="1" Enabled="false" Foreground="false" Comment="Generates managed alerts on errors" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="CreateManagedAlertRule">HS.Local.VA.eSCM.DMLSS.Alert.ManagedAlertsRule</Setting>
  </Item>
  <Item Name="Ens.AlertNotification" Category="Alert" ClassName="Ens.Alerting.NotificationManager" PoolSize="1" Enabled="false" Foreground="false" Comment="Routes managed alerts to appropriate email operations" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="NotificationTransform">HS.Local.VA.eSCM.DMLSS.Alert.AlertRoutingTransformation</Setting>
  </Item>
  <Item Name="EMail.AlertOperation" Category="Alert" ClassName="EnsLib.EMail.AlertOperation" PoolSize="1" Enabled="false" Foreground="false" Comment="Send Email alert to FMS team" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="IncludeDetails">1</Setting>
    <Setting Target="Host" Name="SubjectPrefix">HC DMLSS Alert</Setting>
    <Setting Target="Adapter" Name="SMTPPort">25</Setting>
    <Setting Target="Adapter" Name="SMTPServer">smtp.va.gov</Setting>
    <Setting Target="Adapter" Name="From">HSH.Feeder@va.gov</Setting>
    <Setting Target="Host" Name="AlertOnError">0</Setting>
  </Item>
  <Item Name="ActivityMonitorLocal" Category="" ClassName="Ens.Activity.Operation.Local" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="CSP Operation" Category="" ClassName="Feeder.CSPOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="Port">52773</Setting>
    <Setting Target="Host" Name="Server">127.0.0.1</Setting>
    <Setting Target="Host" Name="URL">/csp/healthshare/DLA_IN/DLAIN.csp?FILENAME=</Setting>
  </Item>
  <Item Name="File Passthrough Service" Category="" ClassName="EnsLib.File.PassthroughService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="FilePath">/tmp/</Setting>
    <Setting Target="Adapter" Name="FileSpec">IVA*</Setting>
    <Setting Target="Adapter" Name="ConfirmComplete">2</Setting>
    <Setting Target="Host" Name="TargetConfigNames">CSP Operation</Setting>
    <Setting Target="Adapter" Name="ArchivePath"></Setting>
  </Item>
</Production>
}

}
