[string[]]$serverlist = Get-Content -Path "C:\Users\jagadishwar_pilla\Desktop\Dell Backup\Desktop\Jagadish\Process Docs\Powershell_Add_DataFiles\Server_List.txt"
[string[]]$Databaselist = Get-Content -Path "C:\Users\jagadishwar_pilla\Desktop\Dell Backup\Desktop\Jagadish\Process Docs\Powershell_Add_DataFiles\Databases.txt"

foreach($server in $serverlist)
{
 foreach ($DB in $Databaselist)
{​​​
write-host $DB
$Datafile1=$DB+'_data4'
$Datafile2=$DB+'_data5'
$Datafile3=$DB+'_data6'

Invoke-Sqlcmd -serverinstance $server -Database $DB -Query "

ALTER DATABASE [$DB] ADD FILE ( NAME = '$Datafile1', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\$Datafile1.ndf' , SIZE = 102400KB , FILEGROWTH = 10%) TO FILEGROUP [PRIMARY]
go"

Invoke-Sqlcmd -serverinstance $server -Database $DB -Query "

ALTER DATABASE [$DB] ADD FILE ( NAME = '$Datafile2', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\$Datafile2.ndf' , SIZE = 102400KB , FILEGROWTH = 10%) TO FILEGROUP [PRIMARY]
go
"

Invoke-Sqlcmd -serverinstance $server -Database $DB -Query "

ALTER DATABASE [$DB] ADD FILE ( NAME = '$Datafile3', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\$Datafile3.ndf' , SIZE = 102400KB , FILEGROWTH = 10%) TO FILEGROUP [PRIMARY]
go
"

Write-host "Data files addd successfully on $DB

}
}