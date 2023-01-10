--ERM Server
USE YellowFolderProd
GO

--21887	hardyt@greenvilleisd.com needs just SPED
--21009	ostens1@greenvilleisd.com needs just AR


SELECT *
FROM mst_user_info
WHERE scm_user_name IN (
'dmsadmin.her@yellowfolder.com'
)

SELECT * FROM dbo.mst_account
WHERE pk_account_id = 1443


SELECT * 
--DELETE 
FROM dbo.record_series_user_mapping rsum
WHERE fk_record_series_account_mapping_id = 1318



SELECT * FROM dbo.mst_user_info
WHERE pk_user_info_id IN (
7281
,5384
)

SELECT * FROM dbo.queue
WHERE created_by IN (
7281
,5384
)

SELECT * FROM dbo._ScannedImages
WHERE user_id IN (
7281
,5384
)
--Testing to see if making the FTS dms account Manual in record_series_user_mapping, created same behavior that Janice Murdock is experiencing
--UPDATE dbo.record_series_user_mapping
--SET scan_type = 'M'
--WHERE fk_user_info_id = 7281
--AND fk_record_series_id = 2

--SELECT * FROM mst_account
--WHERE pk_account_id = 1413


--SELECT * FROM mst_user_info
--WHERE last_name LIKE 'Stocke%'
--AND first_name LIKE 'James%'

--SELECT * FROM mst_user_info
--WHERE pk_user_info_id IN (

--)

--SELECT * FROM [dbo].[record_series_user_mapping]
--WHERE fk_record_series_account_mapping_id = ''

--Update mst_user_info
--set scanning_type = 'M' where scm_user_name IN ('dmsadmin.rcc@yellowfolder.com') and scanning_type = 'C'

--select *
--from mst_user_info
--where scm_user_name IN ('emily.burton@covington.kyschools.us')


--select *
--from mst_user_info
--where scm_user_name IN ('cory.allison@northpolk.org')

--select * from mst_user_info
--where scm_user_name IN ('therealdavos@gmail.com')

--Update mst_user_info
--SET is_active = 1
--where scm_user_name IN (
--'dmsadmin.her@yellowfolder.com'
--)

--Update mst_user_info
--SET scm_user_name = 'swyant@seapco.org'
--where scm_user_name IN ('smcevoy@seapco.org')

--UPDATE mst_user_info
--SET last_name = ''
--WHERE scm_user_name = ''








