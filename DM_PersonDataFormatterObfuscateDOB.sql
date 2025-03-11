USE yfCNT
GO
--redo since last count was way off 
SELECT TOP (100000) 
      [Id],
      [RecordSeriesId],
      ISNULL([FirstName], '') AS FirstName, -- Replace NULL with empty string
      ISNULL([LastName], '') AS LastName,   -- Replace NULL with empty string
      ISNULL([MiddleName], '') AS MiddleName, -- Replace NULL with empty string
      CONVERT(VARCHAR, DATEADD(DAY, 1000, [DateofBirth]), 101) AS DateofBirth, -- Offset date by 1000 days and convert format
      CASE 
          WHEN LEFT([IdentificationNumber], 1) = '0' THEN '''' + [IdentificationNumber] -- Add single quote for leading 0s
          ELSE ISNULL([IdentificationNumber], '') -- Replace NULL with empty string
      END AS IdentificationNumber, 
      CASE 
          WHEN [Status] = 0 THEN 'Archive'
          WHEN [Status] = 1 THEN 'Active'
          ELSE 'Unknown' -- For cases where status is neither 0 nor 1 (optional)
      END AS Status,
      ISNULL([Suffix], '') AS Suffix, -- Replace NULL with empty string
      ISNULL([Alias], '') AS Alias,   -- Replace NULL with empty string
      ISNULL([ScanType], '') AS ScanType, -- Replace NULL with empty string
      ISNULL([InsertUpdateFlag], '') AS InsertUpdateFlag -- Replace NULL with empty string
  FROM [yfCNT].[dbo].[tPersonData]
  WHERE RecordSeriesId = 3;
