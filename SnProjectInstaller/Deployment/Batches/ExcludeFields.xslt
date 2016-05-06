<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" 
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:msxsl="urn:schemas-microsoft-com:xslt" 
                exclude-result-prefixes="msxsl">
    <xsl:output method="xml" encoding="utf-8" indent="yes"/>

    <xsl:template match="AvailableContentTypeFields"/>
    <xsl:template match="AvailableViews"/>
	<xsl:template match="WorkspaceSkin"/>
	<xsl:template match="CheckedOutTo"/>

    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()" />
        </xsl:copy>
    </xsl:template>
	
	<xsl:template match="Identity[@path = '/Root/IMS/BuiltIn/Portal/Creators']" />
</xsl:stylesheet>