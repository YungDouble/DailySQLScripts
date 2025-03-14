USE yfSAG
GO

    
--SELECT * FROM dbo.tDocDetails
--WHERE BoxNumber In (
--'BMHDM-06042024-PartA1'
--, 'BMHDM-06052024-PartA2'
--)

/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT TOP (125000) [Id]
--    [RSId]
--      ,[IsActiveDoc]
--      ,[PersonDataId]
--      ,[AccountTemplateId]
--      ,[DocDate]
--      ,[BoxNumber]
--      ,[ScannedBy]
--      ,[OriginalDocumentName]
--      ,[AccountIdMetaData]
--      ,[DocIdMetaData]
--      ,[CustomDocumentName]
--      ,[OriginalDocumentName_OldDMS]
--      ,[IsDeleted]
--  FROM [yfBMH].[dbo].[tDocDetails]
--  WHERE BoxNumber LIKE '%GeneralPersonn%'
--  AND RSId = 3

SELECT 
    'TOTAL' AS BoxNumber, 
    COUNT(*) AS FileCount,
    0 AS SortOrder  -- Ensures "TOTAL" appears first
FROM dbo.tDocDetails
WHERE RSId = 3
AND BoxNumber LIKE '%Part%'  -- Ensures only GeneralPersonnel box numbers
AND BoxNumber IS NOT NULL

UNION ALL

SELECT 
    CASE 
        WHEN BoxNumber LIKE '%-Part%' THEN LEFT(BoxNumber, CHARINDEX('-Part', BoxNumber) + 5) -- Groups "Part*" boxes together
        ELSE BoxNumber 
    END AS BoxNumber,
    COUNT(*) AS FileCount,
    1 AS SortOrder  -- Ensures grouped items appear below "TOTAL"
FROM dbo.tDocDetails
WHERE RSId = 2 
AND BoxNumber LIKE '%DM%'  -- Ensures only GeneralPersonnel box numbers
--AND BoxNumber NOT IN ('BMH-HR-DM-20240221-GeneralPersonnel_PartA') 
AND BoxNumber IS NOT NULL

GROUP BY 
    CASE 
        WHEN BoxNumber LIKE '%-Part%' THEN LEFT(BoxNumber, CHARINDEX('-Part', BoxNumber) + 5) 
        ELSE BoxNumber 
    END

ORDER BY SortOrder, BoxNumber;

--SELECT * FROM dbo.tPersonData
--WHERE LastName = 'Seres' AND FirstName = 'Jodi'
