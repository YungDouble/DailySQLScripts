USE yfHNT
GO

/****** Script to show that the HNT boxes were checked in with new versions ******/
SELECT 
BoxCode,
DocOperationId,
AttrName,
OperationDate
  FROM [yfHNT].[dbo].[tBoxLevelActivityDetails] bld
  JOIN dbo.mAcctIdentity ma
  ON ma.[Id] = bld.DocOperationId
  JOIN dbo.tBoxLevelDetails bl
  ON bl.[Id] = bld.BoxLevelDetailsId
  WHERE BoxLevelDetailsId IN (
  1
,71
,72
,73
,74
,76
  )
  AND OperationDate BETWEEN '2023-05-04' AND '2023-05-05'
  AND DocOperationId = 28
  ORDER BY OperationDate DESC
