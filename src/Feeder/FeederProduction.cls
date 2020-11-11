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
  <Item Name="CSP Operation" Category="" ClassName="Feeder.CSPOperation" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="Port">52773</Setting>
    <Setting Target="Host" Name="URL">/csp/user/cache_status.cxw</Setting>
  </Item>
  <Item Name="File Passthrough Service" Category="" ClassName="EnsLib.File.PassthroughService" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
</Production>
}

}
