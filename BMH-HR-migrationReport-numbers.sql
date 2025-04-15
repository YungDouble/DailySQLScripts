USE yfBMH
GO
    
SELECT 
    'TOTAL' AS BoxNumber, 
    COUNT(*) AS FileCount,
    0 AS SortOrder  -- Ensures "TOTAL" appears first
FROM dbo.tDocDetails
WHERE RSId = 3
AND BoxNumber LIKE '%GeneralPersonnel%'  -- Ensures only GeneralPersonnel box numbers
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
WHERE RSId = 3
AND BoxNumber LIKE '%GeneralPersonnel%'  -- Ensures only GeneralPersonnel box numbers
AND BoxNumber NOT IN ('BMH-HR-DM-20240221-GeneralPersonnel_PartA') 
AND BoxNumber IS NOT NULL

GROUP BY 
    CASE 
        WHEN BoxNumber LIKE '%-Part%' THEN LEFT(BoxNumber, CHARINDEX('-Part', BoxNumber) + 5) 
        ELSE BoxNumber 
    END

ORDER BY SortOrder, BoxNumber;

