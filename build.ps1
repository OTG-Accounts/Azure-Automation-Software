[cmdletbinding()]
param (
    [parameter(Mandatory = $true)]
    [System.IO.FileInfo]$modulePath,

    [parameter(Mandatory = $true)]
    $moduleName
)
try {
    #region Generate a new version number
    $newVersion = New-Object version -ArgumentList 1, 0, 0, $env:BUILD_BUILDID
    #endregion
    #region Build out the release
    $relPath = "$PSScriptRoot\bin\release\$moduleName"
    "Version is $newVersion"
    "Module Path is $modulePath"
    "Module Name is $moduleName"
    "Release Path is $relPath"
    if (!(Test-Path $relPath)) {
        New-Item -Path $relPath -ItemType Directory -Force | Out-Null
    }
    Copy-Item "$modulePath\*" -Destination "$relPath" -Recurse -Exclude ".gitKeep"
    #endregion
    #region Generate a list of public functions and update the module manifest
    $functions = @(Get-ChildItem -Path $relPath\Public\*.ps1 -ErrorAction SilentlyContinue).basename
    Update-ModuleManifest -Path $relPath\$ModuleName.psd1 -ModuleVersion $newVersion -FunctionsToExport $functions
    $moduleManifest = get-content $relPath\$ModuleName.psd1 -raw | Invoke-Expression
    #endregion
    #region Generate the nuspec manifest
    $t = [xml](Get-Content $PSScriptRoot\module.nuspec -Raw)
    $t.package.metadata.id                          = $moduleName
    $t.package.metadata.version                     = $newVersion.ToString()
    $t.package.metadata.authors                     = $moduleManifest.author.ToString()
    $t.package.metadata.owners                      = $moduleManifest.author.ToString()
    $t.package.metadata.requireLicenseAcceptance    = "false"
    $t.package.metadata.description                 = (Get-Content $relPath\description.txt -raw).ToString()
    $t.package.metadata.releaseNotes                = (Get-Content $relPath\releaseNotes.txt -raw).ToString()
    $t.package.metadata.copyright                   = $moduleManifest.copyright.ToString()
    $t.package.metadata.tags                        = ($moduleManifest.PrivateData.PSData.Tags -join ',').ToString()
    $t.Save("$PSScriptRoot\$moduleName`.nuspec")
    #endregion
}
catch {
    $_
}