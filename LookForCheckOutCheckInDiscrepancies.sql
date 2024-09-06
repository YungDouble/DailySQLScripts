WITH CheckInOutCount AS (
	SELECT
		bld.BoxLevelDetailsId,
		SUM(CASE WHEN mat.AttrName = 'CheckIn' THEN 1 ELSE 0 END) AS CheckInCount,
		SUM(CASE WHEN mat.AttrName = 'CheckOut' THEN 1 ELSE 0 END) AS CheckOutCount
	FROM
		[yfALD].[dbo].[tBoxLevelActivityDetails] bld
		JOIN [dbo].[mAcctIdentity] mat
			ON bld.DocOperationId = mat.[Id]
	WHERE
		bld.DocOperationId IN (28,29)
	GROUP BY
		bld.BoxLevelDetailsId
)
SELECT * 
FROM CheckInOutCount
WHERE (CheckInCount = 1 AND CheckOutCount = 0)
	OR (CheckInCount = 0 AND CheckOutCount = 1)
ORDER BY BoxLevelDetailsId;

--SELECT * FROM dbo.tBoxLevelActivityDetails
--WHERE BoxLevelDetailsId IN (
--) AND DocOperationId = 29

--DELETE FROM dbo.tBoxLevelActivityDetails
--WHERE [Id] IN (
--1772,1789,1825,1850,1883,1907,1915,1929)
--AND BoxLevelDetailsId IN (
--134
--,127
--,138
--,130
--,152
--,182
--,148
--,116
--) AND DocOperationId = 29
