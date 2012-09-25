<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
xmlns:xccdf="http://checklists.nist.gov/xccdf/1.1"
xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:date="http://exslt.org/dates-and-times" extension-element-prefixes="date"
exclude-result-prefixes="xccdf xhtml">

<xsl:include href="constants.xslt"/>

<xsl:variable name="ovalpath">oval:org.scap-security-guide.rhel:def:</xsl:variable>
<xsl:variable name="ovalfile">rhel6-oval.xml</xsl:variable>

<xsl:variable name="defaultseverity" select="'low'" />


  <!-- Content:template -->
  <xsl:template match="Benchmark">
    <xsl:copy>
      <xsl:attribute name="xmlns">
        <xsl:text>http://checklists.nist.gov/xccdf/1.1</xsl:text>
      </xsl:attribute>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>

  <!-- insert current date -->
  <xsl:template match="Benchmark/status/@date">
    <xsl:attribute name="date">
       <xsl:value-of select="date:date()"/>
    </xsl:attribute>
  </xsl:template>

  <!-- hack for OpenSCAP validation quirk: must place reference after description/warning, but prior to others -->
  <xsl:template match="Rule">
    <xsl:copy>
      <xsl:apply-templates select="@*" />
      <!-- also: add severity of "low" to each Rule if otherwise unspecified -->
      <xsl:if test="not(@severity)">
          <xsl:attribute name="severity">
              <xsl:value-of select="$defaultseverity" />
          </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates select="title"/>
      <xsl:apply-templates select="description"/>
      <xsl:apply-templates select="warning"/> 
      <xsl:apply-templates select="ref"/> 
      <xsl:apply-templates select="rationale"/> 
      <xsl:apply-templates select="ident"/> 
      <xsl:apply-templates select="node()[not(self::title|self::description|self::warning|self::ref|self::rationale|self::ident)]"/>
    </xsl:copy>
  </xsl:template> 


  <xsl:template match="Group">
    <xsl:copy>
      <xsl:apply-templates select="@*" />
      <xsl:apply-templates select="title"/>
      <xsl:apply-templates select="description"/>
      <xsl:apply-templates select="warning"/> 
      <xsl:apply-templates select="ref"/> 
      <xsl:apply-templates select="rationale"/> 
      <xsl:apply-templates select="node()[not(self::title|self::description|self::warning|self::ref|self::rationale)]"/>
    </xsl:copy>
  </xsl:template> 


  <!-- expand reference to ident types -->
  <xsl:template match="Rule/ident">
    <xsl:for-each select="@*">
      <ident>
        <xsl:choose>
          <xsl:when test="name() = 'cce'">
            <xsl:attribute name="system">
              <xsl:value-of select="$cceuri" />
            </xsl:attribute>
            <xsl:choose>
              <xsl:when test="starts-with(translate(., 'ce', 'CE'), 'CCE')">
                <xsl:value-of select="." />
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="concat('CCE-', .)" />
              </xsl:otherwise>
            </xsl:choose>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="." />
          </xsl:otherwise>
        </xsl:choose>
      </ident>
    </xsl:for-each>
  </xsl:template>

  <!-- expand ref attributes to reference tags, one item per reference -->
  <xsl:template match="ref"> 
    <xsl:for-each select="@*">
       <xsl:call-template name="ref-info" >
          <xsl:with-param name="refsource" select="name()" />
          <xsl:with-param name="refitems" select="." />
       </xsl:call-template>
    </xsl:for-each>
  </xsl:template>

  <!-- expands individual reference source -->
  <xsl:template name="ref-info">
      <xsl:param name="refsource"/>
      <xsl:param name="refitems"/>
      <xsl:variable name="delim" select="','" />
       <xsl:choose>
           <xsl:when test="$delim and contains($refitems, $delim)">
             <!-- output the reference -->
             <xsl:call-template name="ref-output" >
               <xsl:with-param name="refsource" select="$refsource" />
               <xsl:with-param name="refitem" select="substring-before($refitems, $delim)" />
             </xsl:call-template>
             <!-- recurse for additional refs -->
             <xsl:call-template name="ref-info">
               <xsl:with-param name="refsource" select="$refsource" />
               <xsl:with-param name="refitems" select="substring-after($refitems, $delim)" />
             </xsl:call-template>
           </xsl:when>

           <xsl:otherwise>
             <xsl:call-template name="ref-output" >
               <xsl:with-param name="refsource" select="$refsource" />
               <xsl:with-param name="refitem" select="$refitems" />
             </xsl:call-template>
           </xsl:otherwise>
       </xsl:choose>
  </xsl:template>

  <!-- output individual reference -->
  <xsl:template name="ref-output">
      <xsl:param name="refsource"/>
      <xsl:param name="refitem"/>
      <reference>
        <xsl:attribute name="href">
        <!-- populate the href attribute with a global reference-->
          <xsl:if test="$refsource = 'nist'">
            <xsl:value-of select="$nist800-53uri" />
          </xsl:if>
          <xsl:if test="$refsource = 'cnss'">
            <xsl:value-of select="$cnss1253uri" />
          </xsl:if>
          <xsl:if test="$refsource = 'dcid'">
            <xsl:value-of select="$dcid63uri" />
          </xsl:if>
          <xsl:if test="$refsource = 'disa'">
            <xsl:value-of select="$disa-cciuri" />
          </xsl:if>
        </xsl:attribute>
        <xsl:value-of select="$refitem" />
      </reference>
  </xsl:template>

  <!-- expand reference to OVAL ID -->
  <xsl:template match="Rule/oval">
    <check>
      <xsl:attribute name="system">
        <xsl:value-of select="$ovaluri" />
      </xsl:attribute>

      <xsl:if test="@value">
      <check-export>
      <xsl:attribute name="export-name">
        <xsl:value-of select="@value" />
      </xsl:attribute>
      <xsl:attribute name="value-id">
        <xsl:value-of select="@value" />
      </xsl:attribute>
      </check-export>
      </xsl:if> 

      <check-content-ref>
        <xsl:attribute name="href">
          <xsl:value-of select="$ovalfile" />
        </xsl:attribute>
        <xsl:attribute name="name">
          <xsl:value-of select="@id" />
        </xsl:attribute>
      </check-content-ref>
    </check>
  </xsl:template>


  <!-- expand reference to would-be OCIL (inline) -->
  <xsl:template match="Rule/ocil">
      <check>
        <xsl:attribute name="system">ocil-transitional</xsl:attribute>
          <check-export>

          <xsl:attribute name="export-name">
          <!-- add clauses if specific macros are found within -->
            <xsl:if test="sysctl-check-macro">the correct value is not returned</xsl:if>
            <xsl:if test="fileperms-check-macro or fileowner-check-macro or filegroupowner-check-macro">it does not</xsl:if>
            <xsl:if test="partition-check-macro">no line is returned</xsl:if>
            <xsl:if test="service-disable-check-macro">the service is running</xsl:if>
            <xsl:if test="service-enable-check-macro">the service is not running</xsl:if>
            <xsl:if test="package-check-macro">the package is installed</xsl:if>
            <xsl:if test="module-disable-check-macro">no line is returned</xsl:if>
            <xsl:if test="audit-syscall-check-macro">no line is returned</xsl:if>
          </xsl:attribute>

          <!-- add clause if explicitly specified (and also override any above) -->
          <xsl:if test="@clause">
            <xsl:attribute name="export-name"><xsl:value-of select="@clause" /></xsl:attribute>
          </xsl:if>

          <xsl:attribute name="value-id">conditional_clause</xsl:attribute>
          </check-export>
        <!-- add the actual manual checking text -->
        <check-content>
        <xsl:apply-templates select="node()"/>
        </check-content>
      </check>
   </xsl:template>


  <xsl:template match="@*|node()">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()" />
    </xsl:copy>
  </xsl:template>



  <!-- convenience macros for XCCDF prose -->
  <xsl:template match="sysctl-desc-macro">
    To set the runtime status of the <xhtml:code><xsl:value-of select="@sysctl"/></xhtml:code> kernel parameter,
    run the following command:
    <xhtml:pre># sysctl -w <xsl:value-of select="@sysctl"/> <xsl:value-of select="@value"/></xhtml:pre>
  </xsl:template>

  <xsl:template match="sysctl-check-macro">
    The status of the <xhtml:code><xsl:value-of select="@sysctl"/></xhtml:code> kernel parameter can be queried
    by running the following command:
    <xhtml:pre>$ sysctl <xsl:value-of select="@sysctl"/></xhtml:pre>
    The output of the command should indicate a value of <xhtml:code><xsl:value-of select="@value"/></xhtml:code>.
    If this value is not the default value, investigate how it could have been adjusted at runtime, and verify
    that it is not set improperly in <xhtml:code>/etc/sysctl.conf</xhtml:code>.
  </xsl:template>

  <xsl:template match="fileperms-desc-macro">
    To properly set the permissions of <xhtml:code><xsl:value-of select="@file"/></xhtml:code>, run the command:
    <xhtml:pre xml:space="preserve"># chmod <xsl:value-of select="@perms"/> <xsl:value-of select="@file"/></xhtml:pre>
  </xsl:template>

  <xsl:template match="fileowner-desc-macro">
    To properly set the owner of <xhtml:code><xsl:value-of select="@file"/></xhtml:code>, run the command:
    <xhtml:pre xml:space="preserve"># chown <xsl:value-of select="@owner"/> <xsl:value-of select="@file"/> </xhtml:pre>
  </xsl:template>

  <xsl:template match="filegroupowner-desc-macro">
    To properly set the group owner of <xhtml:code><xsl:value-of select="@file"/></xhtml:code>, run the command:
    <xhtml:pre xml:space="preserve"># chgrp <xsl:value-of select="@group"/> <xsl:value-of select="@file"/> </xhtml:pre>
  </xsl:template>

  <xsl:template match="fileperms-check-macro">
    To check the permissions of <xhtml:code><xsl:value-of select="@file"/></xhtml:code>, run the command:
    <xhtml:pre>$ ls -l <xsl:value-of select="@file"/></xhtml:pre>
    If properly configured, the output should indicate the following permissions:
    <xhtml:code><xsl:value-of select="@perms"/></xhtml:code>
  </xsl:template>

  <xsl:template match="fileowner-check-macro">
    To check the ownership of <xhtml:code><xsl:value-of select="@file"/></xhtml:code>, run the command:
    <xhtml:pre>$ ls -l <xsl:value-of select="@file"/></xhtml:pre>
    If properly configured, the output should indicate the following owner:
    <xhtml:code><xsl:value-of select="@owner"/></xhtml:code>
  </xsl:template>

  <xsl:template match="filegroupowner-check-macro">
    To check the group ownership of <xhtml:code><xsl:value-of select="@file"/></xhtml:code>, run the command:
    <xhtml:pre>$ ls -l <xsl:value-of select="@file"/></xhtml:pre>
    If properly configured, the output should indicate the following group-owner:
    <xhtml:code><xsl:value-of select="@group"/></xhtml:code>
  </xsl:template>

  <xsl:template match="fileperms-check-macro">
    To check the permissions of <xhtml:code><xsl:value-of select="@file"/></xhtml:code>, run the command:
    <xhtml:pre>$ ls -l <xsl:value-of select="@file"/></xhtml:pre>
    If properly configured, the output should indicate the following permissions:
    <xhtml:code><xsl:value-of select="@perms"/></xhtml:code>
  </xsl:template>

  <xsl:template match="package-install-macro">
    The <xhtml:code><xsl:value-of select="@package"/></xhtml:code> package can be installed with the following command:
    <xhtml:pre># yum install <xsl:value-of select="@package"/></xhtml:pre>
  </xsl:template>

  <xsl:template match="package-remove-macro">
    The <xhtml:code><xsl:value-of select="@package"/></xhtml:code> package can be removed with the following command:
    <xhtml:pre># yum erase <xsl:value-of select="@package"/></xhtml:pre>
  </xsl:template>

  <xsl:template match="partition-check-macro">
    Run the following command to verify that <xhtml:code><xsl:value-of select="@part"/></xhtml:code> lives on its own partition:
  <xhtml:pre># df -h <xsl:value-of select="@part"/> </xhtml:pre>
    It will return a line for <xhtml:code><xsl:value-of select="@part"/></xhtml:code> if it is on its own partition. 
  </xsl:template>

  <xsl:template match="service-disable-macro">
    The <xhtml:code><xsl:value-of select="@service"/></xhtml:code> service can be disabled with the following command:
    <xhtml:pre># chkconfig <xsl:value-of select="@service"/> off</xhtml:pre>
  </xsl:template>

  <xsl:template match="service-enable-macro">
    The <xhtml:code><xsl:value-of select="@service"/></xhtml:code> service can be enabled with the following command:
    <xhtml:pre># chkconfig <xsl:value-of select="@service"/> on</xhtml:pre>
  </xsl:template>

  <xsl:template match="service-disable-check-macro">
    It is prudent to check that the <xhtml:code><xsl:value-of select="@service"/></xhtml:code> service is disabled in system boot
    configuration via <xhtml:code>chkconfig</xhtml:code> and not currently running on the system (runtime configuration).

    Run the following command to verify <xhtml:code><xsl:value-of select="@service"/></xhtml:code> is disabled through current
    runtime configuration:
    <xhtml:pre># service <xsl:value-of select="@service"/> status</xhtml:pre>

    If the service is disabled, the command will return:
    <xhtml:pre><xsl:value-of select="@service"/> is stopped</xhtml:pre>

    Run the following command to verify <xhtml:code><xsl:value-of select="@service"/></xhtml:code> is disabled through system
    boot configuration:
    <xhtml:pre># chkconfig <xhtml:code><xsl:value-of select="@service"/></xhtml:code> --list</xhtml:pre>
 
    Output should indicate the <xhtml:code><xsl:value-of select="@service"/></xhtml:code> service has been disabled at all runlevels,
    as shown in the example below:
    <xhtml:pre># chkconfig <xhtml:code><xsl:value-of select="@service"/></xhtml:code> --list
<xhtml:code><xsl:value-of select="@service"/></xhtml:code>       0:off   1:off   2:off   3:off   4:off   5:off   6:off</xhtml:pre>
  </xsl:template>

  <xsl:template match="service-enable-check-macro">
    Run the following command to determine the current status of the
<xhtml:code><xsl:value-of select="@service"/></xhtml:code> service:
  <xhtml:pre># service <xsl:value-of select="@service"/> status</xhtml:pre>
    If the service is enabled, it should return: <xhtml:pre><xsl:value-of select="@service"/> is running...</xhtml:pre>
  </xsl:template>

  <xsl:template match="package-check-macro">
    Run the following command to determine if the <xhtml:code><xsl:value-of select="@package"/></xhtml:code> package is installed:
    <xhtml:pre># rpm -q <xsl:value-of select="@package"/></xhtml:pre>
  </xsl:template>


  <xsl:template match="module-disable-macro">
To configure the system to prevent the <xhtml:code><xsl:value-of select="@module"/></xhtml:code>
kernel module from being loaded, add the following line to a file in the directory <xhtml:code>/etc/modprobe.d</xhtml:code>:
<xhtml:pre xml:space="preserve">install <xsl:value-of select="@module"/> /bin/true</xhtml:pre>
  </xsl:template>

  <xsl:template match="module-disable-check-macro">
If the system is configured to prevent the loading of the
<xhtml:code><xsl:value-of select="@module"/></xhtml:code> kernel module,
it will contain lines inside any file in <xhtml:code>/etc/modprobe.d</xhtml:code> or the deprecated<xhtml:code>/etc/modprobe.conf</xhtml:code>.
These lines instruct the module loading system to run another program (such as
<xhtml:code>/bin/true</xhtml:code>) upon a module <xhtml:code>install</xhtml:code> event.
Run the following command to search for such lines in all files in <xhtml:code>/etc/modprobe.d</xhtml:code>
and the deprecated <xhtml:code>/etc/modprobe.conf</xhtml:code>:
<xhtml:pre xml:space="preserve">$ grep -r <xsl:value-of select="@module"/> /etc/modprobe.conf /etc/modprobe.d</xhtml:pre>
  </xsl:template>

  <xsl:template match="audit-syscall-check-macro">
To determine if the system is configured to audit calls to
the <xhtml:code><xsl:value-of select="@syscall"/></xhtml:code>
system call, run the following command:
<xhtml:pre xml:space="preserve"># auditctl -l | grep syscall | grep <xsl:value-of select="@syscall"/></xhtml:pre>
If the system is configured to audit this activity, it will return a line.
  </xsl:template>


  <!-- CORRECTING TERRIBLE ABUSE OF NAMESPACES BELOW -->
  <!-- (expanding xhtml tags back into the xhtml namespace) -->
  <xsl:template match="br">
    <xhtml:br />
  </xsl:template>

  <xsl:template match="ul">
    <xhtml:ul>
        <xsl:apply-templates select="@*|node()" />
    </xhtml:ul>
  </xsl:template>

  <xsl:template match="li">
    <xhtml:li>
        <xsl:apply-templates select="@*|node()" />
    </xhtml:li>
  </xsl:template>

  <xsl:template match="tt">
    <xhtml:code>
        <xsl:apply-templates select="@*|node()" />
    </xhtml:code>
  </xsl:template>


  <!-- remove use of tt in titles; xhtml in titles is not allowed -->
  <xsl:template match="title/tt">
        <xsl:apply-templates select="@*|node()" />
  </xsl:template>

  <xsl:template match="code">
    <xhtml:code>
        <xsl:apply-templates select="@*|node()" />
    </xhtml:code>
  </xsl:template>

  <xsl:template match="strong">
    <xhtml:strong>
        <xsl:apply-templates select="@*|node()" />
    </xhtml:strong>
  </xsl:template>

  <xsl:template match="b">
    <xhtml:b>
        <xsl:apply-templates select="@*|node()" />
    </xhtml:b>
  </xsl:template>

  <xsl:template match="em">
    <xhtml:em>
        <xsl:apply-templates select="@*|node()" />
    </xhtml:em>
  </xsl:template>

  <xsl:template match="i">
    <xhtml:i>
        <xsl:apply-templates select="@*|node()" />
    </xhtml:i>
  </xsl:template>

  <xsl:template match="ol">
    <xhtml:ol>
        <xsl:apply-templates select="@*|node()" />
    </xhtml:ol>
  </xsl:template>

  <xsl:template match="pre">
    <xhtml:pre>
        <xsl:apply-templates select="@*|node()" />
    </xhtml:pre>
  </xsl:template>
</xsl:stylesheet>
