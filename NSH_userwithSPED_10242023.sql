/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [pk_record_series_user_mapping_id]
      ,[fk_record_series_id]
      ,[fk_user_info_id]
      ,[fk_record_series_account_mapping_id]
      ,[scan_type]
      ,[created_by]
      ,[created_date]
      ,[modified_by]
      ,[modified_date]
      ,[ip_address]
      ,[fk_recordseries_access_id]
  FROM [YellowFolderProd].[dbo].[record_series_user_mapping]
  WHERE fk_user_info_id IN (27250,26319)
  ORDER BY 

--  26319	dmsadmin.nsh@yellowfolder.com
--  27250	jkleinfeldt@nssd112.org
