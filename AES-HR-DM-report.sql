--For AES HR data migration reporting 

/****** Script for SelectTopNRows command from SSMS  ******/
SELECT td.RSId, td.CampusId, td.PersonDataId, LastName, FirstName, MiddleName,pd.IdentificationNumber,  td.AccountTemplateId, mat.CatNameCSV, td.DocDate, td.ScannedBy, td.BoxNumber, td.OriginalDocumentName, td.DocIdMetaData, td.CreateDt
  FROM [yfAES].[dbo].[tDocDetails] td
  JOIN dbo.tPersonData pd
  ON pd.[Id] = td.PersonDataId
  JOIN dbo.mAccountTemplate mat
  ON mat.[Id] = td.AccountTemplateId
  WHERE BoxNumber IN (
'AES-HR-DM-01022025-GoogleDrive-PartA1'
,'AES-HR-DM-01022025-GoogleDrive-PartA10'
,'AES-HR-DM-01022025-GoogleDrive-PartA2'
,'AES-HR-DM-01022025-GoogleDrive-PartA3'
,'AES-HR-DM-01022025-GoogleDrive-PartA4'
,'AES-HR-DM-01022025-GoogleDrive-PartA5'
,'AES-HR-DM-01022025-GoogleDrive-PartA6'
,'AES-HR-DM-01022025-GoogleDrive-PartA7'
,'AES-HR-DM-01022025-GoogleDrive-PartA8'
,'AES-HR-DM-01022025-GoogleDrive-PartA9'
,'AES-HR-DM-01032025-GoogleDrive-PartA1'
,'AES-HR-DM-01032025-GoogleDrive-PartA10'
,'AES-HR-DM-01032025-GoogleDrive-PartA2'
,'AES-HR-DM-01032025-GoogleDrive-PartA3'
,'AES-HR-DM-01032025-GoogleDrive-PartA4'
,'AES-HR-DM-01032025-GoogleDrive-PartA5'
,'AES-HR-DM-01032025-GoogleDrive-PartA6'
,'AES-HR-DM-01032025-GoogleDrive-PartA7'
,'AES-HR-DM-01032025-GoogleDrive-PartA8'
,'AES-HR-DM-01032025-GoogleDrive-PartA9'
,'AES-HR-DM-01082025-GoogleDocs-Part1'
,'AES-HR-DM-01082025-GoogleDocs-Part10'
,'AES-HR-DM-01082025-GoogleDocs-Part2'
,'AES-HR-DM-01082025-GoogleDocs-Part3'
,'AES-HR-DM-01082025-GoogleDocs-Part4'
,'AES-HR-DM-01082025-GoogleDocs-Part5'
,'AES-HR-DM-01082025-GoogleDocs-Part6'
,'AES-HR-DM-01082025-GoogleDocs-Part7'
,'AES-HR-DM-01082025-GoogleDocs-Part8'
,'AES-HR-DM-01082025-GoogleDocs-Part9'
,'AES-HR-DM-01092025-GoogleDocs-Part1'
,'AES-HR-DM-01092025-GoogleDocs-Part10'
,'AES-HR-DM-01092025-GoogleDocs-Part2'
,'AES-HR-DM-01092025-GoogleDocs-Part3'
,'AES-HR-DM-01092025-GoogleDocs-Part4'
,'AES-HR-DM-01092025-GoogleDocs-Part5'
,'AES-HR-DM-01092025-GoogleDocs-Part6'
,'AES-HR-DM-01092025-GoogleDocs-Part7'
,'AES-HR-DM-01092025-GoogleDocs-Part8'
,'AES-HR-DM-01092025-GoogleDocs-Part9'
,'AES-HR-DM-12302024-GoogleDrive-PartA1'
,'AES-HR-DM-12302024-GoogleDrive-PartA10'
,'AES-HR-DM-12302024-GoogleDrive-PartA2'
,'AES-HR-DM-12302024-GoogleDrive-PartA3'
,'AES-HR-DM-12302024-GoogleDrive-PartA4'
,'AES-HR-DM-12302024-GoogleDrive-PartA5'
,'AES-HR-DM-12302024-GoogleDrive-PartA6'
,'AES-HR-DM-12302024-GoogleDrive-PartA7'
,'AES-HR-DM-12302024-GoogleDrive-PartA8'
,'AES-HR-DM-12302024-GoogleDrive-PartA9'
  )
  --AND CatNameCSV LIKE '%A%'