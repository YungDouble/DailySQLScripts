USE yfSAG
GO
      

SELECT TOP (100000) 
      [Id],
      [RecordSeriesId],
      ISNULL([FirstName], '') AS FirstName, -- Replace NULL with empty string
      ISNULL([LastName], '') AS LastName,   -- Replace NULL with empty string
      ISNULL([MiddleName], '') AS MiddleName, -- Replace NULL with empty string
      CONVERT(VARCHAR, [DateofBirth], 101) AS DateofBirth, -- Convert date to mm/dd/yyyy format
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
  FROM [yfSAG].[dbo].[tPersonData]
  WHERE RecordSeriesId = 2;
