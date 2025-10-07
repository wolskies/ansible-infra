<?xml version="1.0" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <!-- Change network interface to bridge mode on br0 -->
  <xsl:template match="/domain/devices/interface[@type='network']">
    <interface type='bridge'>
      <xsl:apply-templates select="mac"/>
      <source bridge='br0'/>
      <xsl:apply-templates select="target|model|alias|address"/>
    </interface>
  </xsl:template>

  <!-- Add metadata for testing -->
  <xsl:template match="/domain">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:element name="metadata">
        <xsl:element name="test">
          <xsl:attribute name="type">final-release</xsl:attribute>
          <xsl:attribute name="purpose">comprehensive-validation</xsl:attribute>
        </xsl:element>
      </xsl:element>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>
</xsl:stylesheet>
