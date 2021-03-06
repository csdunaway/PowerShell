function Get-TargetResource {
	
  [CmdletBinding()]
	[OutputType([Hashtable])]
	param	(
		[Parameter(Mandatory)]
    [ValidateSet('NonSecure', 'Secure')]
		[String]$UserAuthentication,
    
    [Parameter(Mandatory)]
    [ValidateSet('Absent', 'Present')]
		[String]$Ensure
	)

  $AuthCurrentSetting = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name 'UserAuthentication' |
                        Select-Object -ExpandProperty UserAuthentication

  $TSCurrentSetting = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' |
                      Select-Object -ExpandProperty fDenyTSConnections
  
	$returnValue = @{
		UserAuthentication = switch ($AuthCurrentSetting) {
      0 {'NonSecure'; Break}
      1 {'Secure'; Break}
    }
		Ensure = switch ($TSCurrentSetting) {
      0 {'Present'; Break}
      1 {'Absent'; Break}

	  }
  }

	$returnValue

}
function Set-TargetResource {

	[CmdletBinding()]
	param	(
		[Parameter(Mandatory)]
    [ValidateSet('NonSecure', 'Secure')]
		[String]$UserAuthentication,
    
    [Parameter(Mandatory)]
    [ValidateSet('Absent', 'Present')]
		[String]$Ensure
	)

  if (-not(Test-TargetResource -UserAuthentication $UserAuthentication -Ensure $Ensure)) {

    switch ($UserAuthentication) {
      'NonSecure' {$AuthDesiredSetting = 0}
      'Secure' {$AuthDesiredSetting = 1}
    }

    switch ($Ensure) {
      'Present' {$TSDesiredSetting = 0}
      'Absent' {$TSDesiredSetting = 1}
    }

    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' -Value $AuthDesiredSetting
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value $TSDesiredSetting

  }  

}
function Test-TargetResource {
	
  [CmdletBinding()]
	[OutputType([Boolean])]
	param	(
		[Parameter(Mandatory)]
    [ValidateSet('NonSecure', 'Secure')]
		[String]$UserAuthentication,
    
    [Parameter(Mandatory)]
    [ValidateSet('Absent', 'Present')]
		[String]$Ensure
	)
  
  switch ($Ensure) {
    'Present' {$TSDesiredSetting = 'Enabled'; Break}
    'Absent' {$TSDesiredSetting = 'Disabled'; Break}
  }

  $NetworkLevelAuth = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name 'UserAuthentication' |
                      Select-Object -ExpandProperty UserAuthentication

  $fDenyTSConnections = Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' |
                        Select-Object -ExpandProperty fDenyTSConnections

  switch ($NetworkLevelAuth) {
    0 {$AuthCurrentSetting = 'NonSecure'; Break}
    1 {$AuthCurrentSetting = 'Secure'; Break}
  }

  switch ($fDenyTSConnections) {
    0 {$TSCurrentSetting = 'Enabled'; Break}
    1 {$TSCurrentSetting = 'Disabled'; Break}
  }

  if ($UserAuthentication -eq $AuthCurrentSetting -and $TSDesiredSetting -eq $TSCurrentSetting) {
    Write-Verbose -Message 'RDP settings match the desired state'
    $bool = $true
  }
  else {  
    if ($UserAuthentication -ne $AuthCurrentSetting) {
      Write-Verbose -Message "User Authentication settings are non-compliant. User Authentication should be '$UserAuthentication' - Detected value is: '$AuthCurrentSetting'."
      $bool = $false 
    }
    if ($TSDesiredSetting -ne $TSCurrentSetting) {
      Write-Verbose "RDP settings are non-compliant. RDP should be '$TSDesiredSetting' - Detected value is: '$TSCurrentSetting'."
      $bool = $false   
    }
  }

  $bool

}

Export-ModuleMember -Function *-TargetResource