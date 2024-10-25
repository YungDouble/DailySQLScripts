USE yfOXF;

WITH CheckInOutCount AS (
    SELECT
        tad.DocDetailsId,
        MIN(tad.ID) AS ID,  -- Get the minimum ID to include in the final results (or you can choose MAX or another appropriate aggregation)
        MIN(tad.DocOperationId) AS DocOperationId,  -- Include DocOperationId if needed for the result display
        SUM(CASE WHEN mat.AttrName = 'CheckIn' THEN 1 ELSE 0 END) AS CheckInCount,
        SUM(CASE WHEN mat.AttrName = 'Cancel CheckOut' THEN 1 ELSE 0 END) AS CancelCheckOutCount,
        SUM(CASE WHEN mat.AttrName = 'CheckOut' THEN 1 ELSE 0 END) AS CheckOutCount
    FROM
        [yfOXF].[dbo].[tDocActivityDetails] tad
        JOIN [dbo].[mAcctIdentity] mat
            ON tad.DocOperationId = mat.[Id]
    WHERE
        tad.DocOperationId IN (27, 28, 29)
    GROUP BY
        tad.DocDetailsId
)
SELECT 
    ID,
    DocDetailsId,
    DocOperationId,
    CheckInCount,
    CancelCheckOutCount,
    CheckOutCount
FROM CheckInOutCount
WHERE 
    (CheckInCount + CancelCheckOutCount) <> CheckOutCount
    AND CheckOutCount > 0  -- Exclude cases where there are no check-outs
ORDER BY DocDetailsId;
