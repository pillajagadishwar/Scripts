SELECT @@SERVERNAME AS [Server Name]
    ,@@VERSION AS [SQL VERSION]
    ,getdate() AS [Report Start Time]
FROM sys.syslogins WITH (NOLOCK)
WHERE loginname = N'NT AUTHORITY\SYSTEM'
    OR loginname = N'NT AUTHORITY\NETWORK SERVICE';
GO

SELECT DB_NAME(IPS.DATABASE_ID) AS DBNAME
    ,OBJECT_NAME(ips.object_id) AS table_name
    ,ips.index_type_desc
    ,ISNULL(i.NAME, ips.index_type_desc) AS index_name
    ,IPS.avg_fragmentation_in_percent
    ,IPS.partition_number
    ,IPS.index_level
    ,IPS.page_count
    ,IPS.avg_page_space_used_in_percent
    ,IPS.record_count
    ,IPS.fragment_count
    ,IPS.avg_fragment_size_in_pages
    ,ISNULL(REPLACE(RTRIM((
                    SELECT c.NAME + CASE 
                            WHEN c.is_identity = 1
                                THEN ' (IDENTITY)'
                            ELSE ''
                            END + CASE 
                            WHEN ic.is_descending_key = 0
                                THEN '  '
                            ELSE ' DESC  '
                            END
                    FROM sys.index_columns ic
                    INNER JOIN sys.columns c ON ic.object_id = c.object_id
                        AND ic.column_id = c.column_id
                    WHERE ic.object_id = ips.object_id
                        AND ic.index_id = ips.index_id
                        AND ic.is_included_column = 0
                    ORDER BY ic.key_ordinal
                    FOR XML PATH('')
                    )), '  ', ', '), ips.index_type_desc) AS index_keys
    ,(ips.page_count / 128.0) AS space_used_in_MB
    ,ips.avg_page_space_used_in_percent
    ,CASE 
        WHEN i.fill_factor = 0
            THEN 100
        ELSE i.fill_factor
        END AS fill_factor
    ,8096 / (ips.max_record_size_in_bytes + 2.00) AS min_rows_per_page
    ,8096 / (ips.avg_record_size_in_bytes + 2.00) AS avg_rows_per_page
    ,8096 / (ips.min_record_size_in_bytes + 2.00) AS max_rows_per_page
    ,8096 * (
        (
            100 - (
                CASE 
                    WHEN i.fill_factor = 0
                        THEN 100.00
                    ELSE i.fill_factor
                    END
                )
            ) / 100.00
        ) / (ips.avg_record_size_in_bytes + 2.0000) AS defined_free_rows_per_page
    ,8096 * ((100 - ips.avg_page_space_used_in_percent) / 100.00) / (ips.avg_record_size_in_bytes + 2) AS actual_free_rows_per_page
    ,reads = ISNULL(ius.user_seeks, 0) + ISNULL(ius.user_scans, 0) + ISNULL(ius.user_lookups, 0)
    ,writes = ISNULL(ius.user_updates, 0)
    ,1.00 * (ISNULL(ius.user_seeks, 0) + ISNULL(ius.user_scans, 0) + ISNULL(ius.user_lookups, 0)) / ISNULL(CASE 
            WHEN ius.user_updates > 0
                THEN ius.user_updates
            END, 1) AS reads_per_write
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'SAMPLED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id
    AND ips.index_id = i.index_id
LEFT OUTER JOIN sys.dm_db_index_usage_stats ius ON ius.database_id = DB_ID()
    AND ips.object_id = ius.object_id
    AND ips.index_id = ius.index_id
WHERE ips.alloc_unit_type_desc != 'LOB_DATA'
    AND ips.page_count > 1000 --  <== small indexes will report poorly and don't need rebuilding.
    AND ips.index_level = 0
    AND IPS.index_type_desc <> 'HEAP'
ORDER BY IPS.avg_fragmentation_in_percent DESC
GO

SELECT getdate() AS [Report END Time]
GO


