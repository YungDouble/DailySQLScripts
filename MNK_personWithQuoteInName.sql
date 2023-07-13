/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (100000) [Id]
      ,[RecordSeriesId]
      ,[FirstName]
      ,[LastName]
      ,[MiddleName]
     -- ,[DateofBirth]
      ,[IdentificationNumber]
      ,[Status]
      ,[Suffix]
      ,[Alias]
      ,[ScanType]
      ,[InsertUpdateFlag]
  FROM [yfMNK].[dbo].[tPersonData]
  WHERE IdentificationNumber = 'MA10241996'

  UPDATE dbo.tPersonData
  SET LastName = 'AHearn'
  WHERE [Id] = 18050
  AND IdentificationNumber = 'MA10241996'
