$script:ErrorActionPreference = "Stop"
$password = .\Get-ConfigurationPropertyValue.ps1 Password
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

$domain = .\Get-ConfigurationPropertyValue.ps1 Domain
$userName = .\Get-ConfigurationPropertyValue.ps1 UserName
$credential = new-object Management.Automation.PSCredential(($domain+"\"+$userName),$securePassword)

$computerName = .\Get-ConfigurationPropertyValue.ps1 SutComputerName
$siteCollectionUrl = .\Get-ConfigurationPropertyValue.ps1 SiteCollectionUrl
$mainUrl = "http://" + $computerName

$siteName = .\Get-ConfigurationPropertyValue.ps1 SiteName

$ret = invoke-command -computer $computerName -Credential $credential -scriptblock{
param(
    [string]$siteName,
    [string]$webName,
    [string]$mainUrl,
    [string]$siteCollectionUrl
)
    $script:ErrorActionPreference = "Stop"
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint")

    $result = $false
    try
    {
        if([string]::IsNullOrEmpty($siteCollectionUrl))
        {
            $spSite = new-object Microsoft.SharePoint.SPSite($mainUrl)
        }
        else
        {
            $spSite = new-object Microsoft.SharePoint.SPSite($siteCollectionUrl)
        }
        $spSiteRef = $spSite.openweb($siteName)
        $webs = $spSiteRef.webs

        try
        {
            $webs.delete($webName)
            $result = $true
        }
        catch [System.IO.FileNotFoundException]
        {
            Write-Host $_.Exception.ToString()
        }
    }
    finally
    {
        if ($spSiteRef -ne $null)
        {
            $spSiteRef.Dispose()
        }
        if ($spSite -ne $null)
        {
            $spSite.Close()
            $spSite.Dispose()
        }
    }

    return $result
}-argumentlist $siteName, $webName, $mainUrl, $siteCollectionUrl

return $ret