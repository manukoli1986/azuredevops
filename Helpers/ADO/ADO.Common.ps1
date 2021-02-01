#THIS CODE IS PROVIDED AS IS WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.

function ConvertTo-StringList {
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Hashtable")]
        [System.Collections.Hashtable] $Hashtable,

        [Parameter(Mandatory = $false, HelpMessage = "Array")]
        [Array] $Array,

        [Parameter(Mandatory = $false, HelpMessage = "Key value delimiter")]
        [string] $Delimiter = ':',

        [Parameter(Mandatory = $false, HelpMessage = "Join items by")]
        [string] $JoinBy = [System.Environment]::NewLine
    )

    if ($Hashtable) {
        return ($Hashtable.GetEnumerator() | ForEach-Object { return "$($_.key)$Delimiter$($_.value)"}) -join $JoinBy    
    }

    if ($Array) {
        return ($Array.GetEnumerator() | ForEach-Object { return "$_"}) -join $JoinBy    
    }    

    return [string]::Empty
}

function ConvertTo-QueryString {
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Hashtable")]
        [System.Collections.Hashtable] $Hashtable
    )

    return ConvertTo-StringList -Hashtable $Hashtable -Delimiter '=' -JoinBy '&'
}