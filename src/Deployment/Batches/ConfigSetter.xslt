<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt"
                exclude-result-prefixes="msxsl">
  <xsl:output method="xml" indent="yes" encoding="utf-8" standalone="yes"/>
  <xsl:param name="srv" select="'MySenseNetContentRepositoryDatasource'"/>
  <xsl:param name="ctg" select="'SenseNetContentRepository'"/>
  <xsl:param name="url" select="'SenseNetContentRepository'"/>

  <xsl:template match="node()">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="node()[not(node())]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template match="add[@name = 'SnCrMsSql']">
    <add name="SnCrMsSql" connectionString="Persist Security Info=False;Initial Catalog={$ctg};Data Source={$srv};Integrated Security=true" providerName="System.Data.SqlClient"/>
  </xsl:template>

  <!-- <xsl:template match="sensenet[not(urlList)]">
    <xsl:copy>
      <xsl:copy-of select="@*"/>
      <xsl:apply-templates select="node()"/>
      <xsl:call-template name="urlList"/>
    </xsl:copy>
  </xsl:template> -->

  <!--<xsl:template match="text()[contains(., 'urlList')]">
    <xsl:call-template name="urlList"/>
  </xsl:template>-->

  <xsl:template name="urlList" xml:space="preserve">
    <urlList>
      <sites>
        <site path="/Root/Sites/Default_Site">
          <urls>
            <url host="{$url}" auth="Forms" />
          </urls>
        </site>
      </sites>
    </urlList>
  </xsl:template>

</xsl:stylesheet>