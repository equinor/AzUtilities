function Get-PSCallerPath {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Delimiter = '-',

        [Parameter()]
        [int] $Skip = 1,

        [Parameter()]
        [int] $SkipLast = 1
    )
    return (Get-PSCallStack | Select-Object -Skip $Skip | Select-Object -SkipLast $SkipLast | Select-Object -ExpandProperty Command) -join $Delimiter
}

function IsGUID {
    [Cmdletbinding()]
    [OutputType([bool])]
    param (
        [Parameter( Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string] $String
    )

    [regex]$guidRegex = '(?im)^[{(]?[0-9A-F]{8}[-]?(?:[0-9A-F]{4}[-]?){3}[0-9A-F]{12}[)}]?$'

    # Check GUID against regex
    return $String -match $guidRegex
}

function Search-GUID {
    [Cmdletbinding()]
    [OutputType([guid])]
    param(
        [Parameter( Mandatory = $true,
            Position = 0,
            ValueFromPipeline = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string] $String
    )
    Write-Verbose "Looking for a GUID in $String"
    $GUID = $String.ToLower() |
        Select-String -Pattern '[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12}' |
        Select-Object -ExpandProperty Matches |
        Select-Object -ExpandProperty Value
    Write-Verbose "Found GUID: $GUID"
    return $GUID
}

function IsNullOrEmpty {
    [Cmdletbinding()]
    [OutputType([bool])]
    param(
        [Parameter( Position = 0,
            ValueFromPipeline = $true)]
        $Object
    )

    if ($PSBoundParameters.Keys.Contains('Verbose')) {
        Write-Output 'Received object:'
        $Object
        Write-Output "Length is: $($Object.Length)" -ea continue
        Write-Output "Count is: $($Object.Count)" -ea continue
        try {
            Write-Output "Enumerator: $($Object.GetEnumerator())" -ea continue
        } catch {}

        'PSObject'
        $Object.PSObject
        'PSObject  --   BaseObject'
        $Object.PSObject.BaseObject

        'PSObject  --   BaseObject  --   BaseObject'
        $Object.PSObject.BaseObject.PSObject.BaseObject

        'PSObject  --   BaseObject  --   Properties'
        $Object.PSObject.BaseObject.PSObject.Properties | Select-Object Name, @{n = 'Type'; e = { $_.TypeNameOfValue } }, Value | Format-Table -AutoSize
        'PSObject  --   Properties'
        $Object.PSObject.Properties | Select-Object Name, @{n = 'Type'; e = { $_.TypeNameOfValue } }, Value | Format-Table -AutoSize
    }

    try {
        if ($null -eq $Object) {
            Write-Verbose 'Object is null'
            return $true
        }
        if ($Object -eq 0) {
            Write-Verbose 'Object is 0'
            return $true
        }
        if ($Object.GetType() -eq [string]) {
            if ([String]::IsNullOrWhiteSpace($Object)) {
                Write-Verbose 'Object is empty string'
                return $true
            } else {
                return $false
            }
        }
        if ($Object.count -eq 0) {
            Write-Verbose 'Object count is 0'
            return $true
        }
        if (-not $Object) {
            Write-Verbose 'Object evaluates to false'
            return $true
        }

        #Evaluate Empty objects
        if (($Object.GetType().Name -ne 'pscustomobject') -or $Object.GetType() -ne [pscustomobject]) {
            Write-Verbose 'Casting object to PSCustomObject'
            $Object = [pscustomobject]$Object
        }

        if (($Object.GetType().Name -eq 'pscustomobject') -or $Object.GetType() -eq [pscustomobject]) {
            if ($Object -eq (New-Object -TypeName pscustomobject)) {
                Write-Verbose 'Object is similar to empty PSCustomObject'
                return $true
            }
            if ($Object.psobject.Properties | IsNullOrEmpty) {
                Write-Verbose 'Object has no properties'
                return $true
            }
        }
    } catch {
        Write-Verbose 'Object triggered exception'
        return $true
    }

    return $false
}

function IsNotNullOrEmpty {
    [Cmdletbinding()]
    [OutputType([bool])]
    param(
        [Parameter( Position = 0,
            ValueFromPipeline = $true)]
        $Object
    )
    return -not ($Object | IsNullOrEmpty)

    <#
'' | IsNullOrEmpty -Verbose
'' | IsNotNullOrEmpty -Verbose

' ' | IsNullOrEmpty -Verbose
' ' | IsNotNullOrEmpty -Verbose

'a' | IsNullOrEmpty -Verbose
'a' | IsNotNullOrEmpty -Verbose

@'
'@ | IsNullOrEmpty -Verbose
@'
'@ | IsNotNullOrEmpty -Verbose

@'

'@ | IsNullOrEmpty -Verbose
@'

'@ | IsNotNullOrEmpty -Verbose

@'
Test
'@ | IsNullOrEmpty -Verbose
@'
Test
'@ | IsNotNullOrEmpty -Verbose


$null | IsNullOrEmpty -Verbose
$null | IsNotNullOrEmpty -Verbose
@{} | IsNullOrEmpty -Verbose
@{} | IsNotNullOrEmpty -Verbose

@{
    Test = 'Test'
} | IsNullOrEmpty -Verbose

@{
    Test = 'Test'
} | IsNotNullOrEmpty -Verbose

@{
    Test = $null
    Null = ''
} | IsNullOrEmpty -Verbose
@{
    Test = $null
    Null = ''
} | IsNotNullOrEmpty -Verbose

$Object = [pscustomobject]@{}
$Object | IsNullOrEmpty -Verbose
$Object | IsNotNullOrEmpty -Verbose

$Object = [pscustomobject]@{ Something = Get-Date }
$Object | IsNullOrEmpty -Verbose
$Object | IsNotNullOrEmpty -Verbose
#>
}

function Merge-Hashtables {
    [CmdletBinding()]
    param (
        $Main,
        $Overrides
    )

    $Main = [Hashtable]$Main
    $Overrides = [Hashtable]$Overrides

    $Output = $Main.Clone()
    ForEach ($Key in $Overrides.Keys) {
        if (($Output.Keys) -notcontains $Key) {
            $Output.$Key = $Overrides.$Key
        }
        if ($Overrides.item($Key) | IsNotNullOrEmpty) {
            $Output.$Key = $Overrides.$Key
        }
    }
    return $Output

    <#

$env = [ordered]@{
    Action            = ''
    ResourceGroupName = 'env'
    Subscription      = 'env'
    ManagementGroupID = ''
    Location          = 'env'
    ModuleName        = ''
    ModuleVersion     = ''
}
Write-Output '`r`nEnvironment variables:'
$env

$inputs = [ordered]@{
    Action              = 'inputs'
    ResourceGroupName   = ''
    Subscription        = ''
    ManagementGroupID   = ''
    Location            = ''
    ModuleName          = 'inputs'
    ModuleVersion       = 'inputs'
    ParameterFilePath   = ''
    ParameterFolderPath = ''
    ParameterOverrides  = 'inputs'
}
Write-Output "`r`nEnvironment overrides:"
$inputs

$Params = Merge-Hashtables -Main $env -Overrides $inputs
Write-Output "`r`nFinal parameters:"
$Params
#>
}

function Set-GitHubEnv {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $Name,
        [Parameter(Mandatory)]
        [string] $Value
    )
    if ($PSBoundParameters.ContainsKey('Verbose')) {
        @{ "$Name" = $Value } | Format-Table -HideTableHeaders -Wrap
    }
    Write-Output "$Name=$Value" | Out-File -FilePath $Env:GITHUB_ENV -Encoding utf8 -Append
}

function New-GitHubLogGroup {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $Title
    )
    Write-Output "::group::$Title"
}

function ConvertTo-Boolean {
    [CmdletBinding()]
    param(
        [Parameter(
            Position = 0,
            ValueFromPipeline = $true)]
        [string] $String
    )
    switch -regex ($String.Trim()) {
        '^(1|true|yes|on|enabled)$' { $true }

        default { $false }
    }
}

function Get-MSGraphToken {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $TenantID,
        [Parameter()]
        [string] $AppID,
        [Parameter()]
        [SecureString] $AppSecret,
        [Parameter()]
        [string] $Scope = 'https://graph.microsoft.com/.default'
    )

    # API Reference
    # https://docs.github.com/en/rest/reference/users#get-the-authenticated-user
    $APICall = @{
        Uri         = "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token"
        Headers     = @{}
        Method      = 'POST'
        ContentType = 'application/x-www-form-urlencoded'
        Body        = @{
            'tenant'        = $TenantID
            'client_id'     = $AppID
            'scope'         = $Scope
            'client_secret' = $AppSecret | ConvertFrom-SecureString -AsPlainText
            'grant_type'    = 'client_credentials'
        }
    }
    try {
        $Response = Invoke-RestMethod @APICall
    } catch {
        throw $_
    }
    return $Response.access_token
}

function Test-JSONParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string] $ParameterFilePath
    )

    $Task = ($MyInvocation.MyCommand.Name).split('.')[0]

    Write-Verbose "$Task - $ParameterFilePath - Finding"

    if (! (Test-Path -Path $ParameterFilePath)) {
        throw "$Task - $ParameterFilePath - File not found"
    }
    Write-Verbose "$Task - $ParameterFilePath - Processing"
    $ParameterFile = Get-Item -Path $ParameterFilePath
    $ParameterJSON = Get-Content -Path $ParameterFile -Raw
    if (! (Test-Json -Json $ParameterJSON -ErrorAction SilentlyContinue)) {
        throw "$Task - $ParameterFilePath - Not valid JSON"
    }
    $ParameterObject = $ParameterJSON | ConvertFrom-Json
    Write-Verbose "$Task - $ParameterFilePath - Checking schema"
    $Schema = $ParameterObject.'$schema'
    if (! $Schema) {
        throw "$Task - $ParameterFilePath - No schema present"
    }
    try {
        $SchemaContent = (Invoke-WebRequest -Uri $Schema).Content
    } catch {
        throw "$Task - $ParameterFilePath - Could not download schema"
    }

    if (! (Test-Json -Json $ParameterJSON -Schema $SchemaContent -ErrorAction SilentlyContinue)) {
        throw "$Task - $ParameterFilePath - Not valid JSON for given schema"
    }
    Write-Verbose "$Task - $ParameterFilePath - Schema verified successfully"

    if ($null -eq $ParameterObject.Parameters) {
        Write-Warning "$Task - $ParameterFilePath - Parameters is empty"
    }
    return $true
}

Export-ModuleMember -Function '*' -Cmdlet '*' -Variable '*' -Alias '*'
