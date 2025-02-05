USE [YellowFolderProd]  -- Switch to the YellowFolderProd database
GO

SELECT 
    b.pk_batch_id,  -- Primary key of the batch
    b.alias,  -- Alias name for the batch
    b.fk_batch_status_id,  -- Foreign key referencing batch status
    
    -- Determine whether the batch is 'Resolved' or 'Unresolved'
    CASE 
        WHEN b.fk_batch_status_id IN (22, 21, 1031, 3) THEN 'Unresolved'
        ELSE 'Resolved'
    END AS Resolution,

    ms.status_type,  -- Type of status (from mst_status table)
    b.fk_account_id,  -- Foreign key referencing the account
    b.created_by,  -- User who created the batch

    -- Format the created date in 'YYYY-MM-DD HH:mm:ss' format
    FORMAT(b.created_date, 'yyyy-MM-dd HH:mm:ss') AS [Date],

    -- Extract the hour from the created date
    DATEPART(hour, b.created_date) AS HourCreated,

    -- Determine the tool used for batch creation
    CASE 
        WHEN b.tool_flag = 1 THEN 'Droplet'
        WHEN b.tool_flag = 2 THEN 'Virtual Printer'
        WHEN b.tool_flag = 3 THEN 'Scan & Upload'
        ELSE 'Undefined'  -- Default case for unknown values
    END AS tool_name

FROM 
    [dbo].[batch] b WITH (NOLOCK)  -- Main table storing batch records

    -- Join with document_details to get batch-related document information
    JOIN [dbo].[document_details] dd WITH (NOLOCK)
       ON b.pk_batch_id = dd.fk_batch_id

    -- Join with mst_account to get account details related to the batch
    JOIN [dbo].[mst_account] ma WITH (NOLOCK)
       ON ma.pk_account_id = b.fk_account_id

    -- Join with mst_status to get status type for the batch
    JOIN dbo.mst_status ms WITH (NOLOCK)
       ON ms.pk_status_id = b.fk_batch_status_id

WHERE
    -- Exclude a specific account ID (1130) from the results
    b.[fk_account_id] NOT IN (1130)

    -- Exclude certain batch statuses from the results
    AND b.[fk_batch_status_id] NOT IN (11, 12, 13)

    -- Filter results for batches created within the specified date range
    AND b.[created_date] BETWEEN '2025-02-03' AND '2025-02-04' 

ORDER BY 
    b.created_date DESC;  -- Sort results in descending order based on created date
