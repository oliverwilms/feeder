/// Import CSV files
Class Feeder.Process Extends Ens.BusinessProcessBPL
{

Storage Default
{
<Type>%Storage.Persistent</Type>
}

/// BPL Definition
XData BPL [ XMLNamespace = "http://www.intersystems.com/bpl" ]
{
<process language='objectscript' request='Ens.StreamContainer' response='Ens.Response' height='2000' width='2000' >
<sequence xend='200' yend='600' >
<if name='CSV' condition='$ZCONVERT($EXTRACT(request.OriginalFilename,*-3,*),"U")=".CSV"' xpos='200' ypos='250' xend='200' yend='500' >
<true>
<code name='import file' xpos='335' ypos='400' >
<![CDATA[ do ##class(community.csvgen).Generate(request.OriginalFilename)]]>
</code>
</true>
</if>
<call name='CSP Operation' target='CSP Operation' async='1' xpos='628' ypos='520' >
<request type='Ens.StreamContainer' >
<assign property="callrequest" value="request" action="set" />
</request>
<response type='Ens.Response' />
</call>
</sequence>
</process>
}

}
