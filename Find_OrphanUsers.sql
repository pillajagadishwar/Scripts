-- GetAccounts
USE master  
DECLARE @DBName             VARCHAR(500) 
DECLARE @SQLCmd             VARCHAR(1024) 
SELECT  sid, 
        loginname AS [Login Name],  
        dbname AS [Default Database], 
        CASE isntname WHEN 1 THEN 'AD Login' ELSE 'SQL Login' END AS [Login Type], 
        CASE WHEN isntgroup = 1 THEN 'AD Group' WHEN isntuser = 1 THEN 'AD User' ELSE '' END AS [AD Login Type], 
        CASE sysadmin WHEN 1 THEN 'Yes' ELSE 'No' END AS [sysadmin], 
        CASE [securityadmin] WHEN 1 THEN 'Yes' ELSE 'No' END AS [securityadmin], 
        CASE [serveradmin] WHEN 1 THEN 'Yes' ELSE 'No' END AS [serveradmin], 
        CASE [setupadmin] WHEN 1 THEN 'Yes' ELSE 'No' END AS [setupadmin], 
        CASE [processadmin] WHEN 1 THEN 'Yes' ELSE 'No' END AS [processadmin], 
        CASE [diskadmin] WHEN 1 THEN 'Yes' ELSE 'No' END AS [diskadmin], 
        CASE [dbcreator] WHEN 1 THEN 'Yes' ELSE 'No' END AS [dbcreator], 
        CASE [bulkadmin] WHEN 1 THEN 'Yes' ELSE 'No' END AS [bulkadmin] 
INTO #Users 
FROM dbo.syslogins 
 
CREATE TABLE #DBUsers ( 
    [DBName]          VARCHAR(500), 
    [DBUserName]  VARCHAR(200), 
    [UserLogin]      VARCHAR(200), 
    [DBRole]     VARCHAR(100)) 
DECLARE csrDB CURSOR FOR  
    SELECT name FROM sysdatabases 
    WHERE name NOT IN ('master', 'model', 'msdb', 'tempdb', 'distribution') and DATABASEPROPERTYEX(name, 'status' ) = 'ONLINE' 
OPEN csrDB 
FETCH NEXT FROM csrDB INTO @DBName 
WHILE @@FETCH_STATUS = 0 
    BEGIN 
        SELECT @SQLCmd = 'INSERT #DBUsers ' + 
                         '  SELECT ''' + @DBName + ''' AS [DBName],' + 
                         '       su.[name] AS [DBUserName], ' + 
                         '       COALESCE (u.[Login Name], ''ORPHANED'') AS [UserLogin], ' + 
                         '       COALESCE (sug.name, ''Public'') AS [DBRole] ' + 
                         '    FROM [' + @DBName + '].[dbo].[sysusers] su' + 
                         '        LEFT OUTER JOIN #Users u' + 
                         '            ON su.sid = u.sid' + 
                         '        LEFT OUTER JOIN ([' + @DBName + '].[dbo].[sysmembers] sm ' + 
                         '                             INNER JOIN [' + @DBName + '].[dbo].[sysusers] sug  ' + 
                         '                                 ON sm.groupuid = sug.uid)' + 
                         '            ON su.uid = sm.memberuid ' + 
                         '    WHERE su.hasdbaccess = 1' + 
                         '      AND su.[name] != ''dbo'' ' 
        EXEC (@SQLCmd) 
        FETCH NEXT FROM csrDB INTO @DBName 
    END 
CLOSE csrDB 
DEALLOCATE csrDB 
SELECT * FROM #DBUsers  
ORDER BY [DBName], [DBUserName]   
DROP TABLE #Users  
DROP TABLE #DBUsers
go
