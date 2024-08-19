USE [YellowFolderProd]
GO

SELECT 
    pk_batch_id,
    alias,
    fk_batch_status_id,
    CASE WHEN b.fk_batch_status_id IN (22, 21, 1031, 3)
        THEN 'Unresolved'
        ELSE 'Resolved'
    END AS Resolution,
    status_type,
    fk_account_id,
    b.created_by,
    FORMAT(b.created_date, 'yyy-MM-dd HH:mm:ss') AS [Date]
	,DATEPART(hour, b.created_date) AS HourCreated,
    CASE WHEN b.tool_flag = 1 
        THEN 'Droplet'
        WHEN b.tool_flag = 2 
        THEN 'Virtual Printer'
        WHEN b.tool_flag = 3
        THEN 'Scan & Upload'
        ELSE 'Undefined'
    END AS tool_name
FROM 
    [dbo].[batch] b WITH (NOLOCK)
    JOIN [document_details] dd WITH (NOLOCK)
       ON b.pk_batch_id = dd.fk_batch_id
    JOIN mst_account ma WITH (NOLOCK)
       ON ma.pk_account_id = b.fk_account_id
    JOIN dbo.mst_status ms WITH (NOLOCK)
       ON ms.pk_status_id = b.fk_batch_status_id
WHERE
    b.[fk_account_id] NOT IN (1130)
    AND b.[fk_batch_status_id] NOT IN (11, 12, 13)
    AND b.[created_date] BETWEEN '2024-08-07' AND '2024-08-08' 
ORDER BY b.created_date DESC;
