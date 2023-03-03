USE YellowFolderProd
GO

/* -----Select Stalled batches for all accounts except ANT----- */
SELECT DISTINCT b.pk_batch_id, b.batch_name,b.physical_box_name,b.fk_batch_status_id,b.tool_flag, ma.alias, b.fk_account_id, b.created_by
, b.created_date,scm_user_name, dd.PageNumber, dd.doc_size
,dd.fk_doc_status_id, dd.doc_original_name, dd.doc_name,dd.doc_format, b.SalesForceTktId
FROM [batch] b (NOLOCK)
	 INNER JOIN [batch_audit] ba (NOLOCK)
	 ON ba.pk_batch_id = b.pk_batch_id
	 JOIN mst_user_info mui (NOLOCK)
	 ON mui.pk_user_info_id = b.created_by
	 JOIN mst_account ma (NOLOCK)
	 ON ma.pk_account_id = b.fk_account_id
	 LEFT JOIN document_details dd (NOLOCK)
	 ON b.pk_batch_id = dd.fk_batch_id
	 JOIN mst_status ms (NOLOCK)
	 ON ms.pk_status_id = b.fk_batch_status_id
WHERE
b.fk_account_id NOT IN (1130,79)
--AND b.tool_flag = 3
AND ma.alias = 'NCS'
--AND scm_user_name = 'Valerie.Miller@jcschools.us'
--AND b.batch_name IN (
--)
AND b.fk_batch_status_id IN (22,1031,3) 
	AND ba.pk_batch_id NOT IN
	(
	SELECT 
		pk_batch_id FROM batch_audit ba (NOLOCK)
		WHERE fk_batch_status_id = 1031
		AND ba.action_date BETWEEN '2023-03-03' AND '2023-03-04'
	)
	AND b.created_date between '2022-07-01' and '2023-03-02'
	ORDER BY dd.doc_name

	--NCSD07192022-6039163_NCS_HR_Manual Scan
	--follow up on the above batch, I am worried M batches run through the migrator may be going to IR

	--NCS Replacement batches
	--NCSD03032023-6921696_NCS_SR_Categorize Scan -- Replaced: NCSD02282023-6900145_NCS_SR_Categorize Scan

/* -----Select stalled batches for every account except Anytown----- */
SELECT *
--doc_original_name, doc_name
FROM [batch] b
   --JOIN [document_details] dd
   --  ON b.pk_batch_id = dd.fk_batch_id
   ----LEFT JOIN [queue] q
   -- ON b.pk_batch_id = q.fk_batch_id
WHERE
	b.fk_account_id NOT IN (1130)
	AND b.fk_batch_status_id IN (22,3)
	--b.created_by = 23857
	AND b.batch_name NOT LIKE 'JFC_06%'
	AND b.batch_name NOT LIKE 'CKC_06%'
--	AND b.created_date between '2021-01-02' and '2022-04-07'

--AVAD12212022-6655757_AVA_SPED_Categorize Scan
--AVAD12212022-6655758_AVA_SPED_Categorize Scan
--AVAD12212022-6655758_AVA_SPED_Categorize Scan
--AVAD12212022-6655759_AVA_SPED_Categorize Scan
--AVAD12212022-6655762_AVA_SPED_Categorize Scan
--CELD02272023-6893495_CEL_SR_Manual Scan

	--WML DMS account has 213 batches that we will need to move to the user mwilson once they reach VR

/* -----Select stalled batches for every account except Anytown----- */
--SELECT *
----doc_original_name, doc_name
--FROM [batch] b
--   --JOIN [document_details] dd
--   --  ON b.pk_batch_id = dd.fk_batch_id
--   ----LEFT JOIN [queue] q
--   -- ON b.pk_batch_id = q.fk_batch_id
--WHERE
--	b.fk_account_id NOT IN (1130)
--	AND b.fk_batch_status_id IN (22,3)
--	--b.created_by = 23857
--	AND b.batch_name NOT LIKE 'JFC_06%'
--	AND b.batch_name NOT LIKE 'CKC_06%'
--	AND b.created_date between '2021-01-02' and '2022-04-07'
--ORDER BY batch_name

/* -----Select Batches from Batch Audit Table----- */

SELECT * FROM batch_audit
WHERE pk_batch_id IN (
6271306
)
--AND fk_batch_status_id IN (1031)
ORDER by action_date

SELECT CONCAT(dd.doc_name, '.pdf'), dd.doc_original_name,physical_box_name, batch_name, pk_batch_id, fk_account_id, fk_batch_status_id, fk_doc_status_id
FROM [batch] b 
JOIN [document_details] dd
ON b.pk_batch_id = dd.fk_batch_id
WHERE dd.doc_original_name IN (
'MKAS SY22.23.pdf'
,'ParentInvitationT3ReviewMeetings 12wk.docx'
,'Section3B Update Declet, M SY22.23.docx'
,'AppendixDTierII KKing SY22.23.docx'
,'Tier 3 Minutes Initial jahmir williams academic SY22.23.docx'
,'T2 Rev. 1 johnston SY22.23.docx'
,'Sec. 3B grady nswrf SY22.23.docx'
,'T2 Rev 4 winston SY22.23.docx'
,'MTSS Referral SY22.23.docx'
,'TeacherFeedback SCanaan SY22.23.docx'
)
AND b.fk_account_id = 1430
ORDER BY doc_original_name

/* -----Select batches based off batch name----- */
--SELECT b.pk_batch_id,batch_name, b.fk_account_id,scm_user_name username,b.created_by, doc_name ,doc_original_name,b.fk_batch_status_id, dd.SalesForceTktId reasonRemoved, b.SalesForceTktId
--FROM [batch] b
--JOIN [document_details] dd
--ON b.pk_batch_id = dd.fk_batch_id
--JOIN dbo.mst_user_info mu
--ON b.created_by = mu.pk_user_info_id
--WHERE batch_name LIKE (
--'KDCD04202021-4104204%'
--)
--AND b.fk_account_id = 1143
----AND b.pk_batch_id IN (5826322,5826328,5847819)
--ORDER BY username ASC

--POWS02142022-5292087_POW_SPED_Categorize Scan created by 16303 heather.storrie@powhatan.k12.va.us
--Replacement Batch: POWD03232022-5437970_POW_SPED_Categorize Scan

--GFFD03152022-5405985_GFF_SR_Categorize Scan ZIP file uploaded by dbrewer@griffith.k12.in.us
--replacement GFFD04292022-5578924_GFF_SR_Categorize Scan

/* -----Select batches based off ERM Batch ID----- */
--SELECT * from [batch] b
--JOIN [document_details] dd
--ON b.pk_batch_id  = dd.fk_batch_id
--where pk_batch_id IN (
--5989535
--)
--order by b.pk_batch_id ASC



--UPDATE document_details
--SET doc_format = '.pdf'
--WHERE created_by IN (
--21188
--,24001
--,7724
--,7734
--,7749
--) 

Update batch
SET fk_batch_status_id = 8, SalesForceTktId = 'dupliate'
where pk_batch_id IN (
	6855421
	,6125832
	,6726364
	,6884472
	,6735434
	,6884471
)

UPDATE document_details
SET fk_doc_status_id = 8, SalesForceTktId = ''
WHERE 
fk_batch_id IN (
	6855421
	,6125832
	,6726364
	,6884472
	,6735434
	,6884471
)

UPDATE dbo.[queue]
SET fk_batch_status_id = 30
WHERE fk_batch_id IN (
	6855421
	,6125832
	,6726364
	,6884472
	,6735434
	,6884471
)

/*TO REMOVE SINGLE DOCUMENT FROM A BATCH */
--UPDATE document_details
--SET fk_doc_status_id = 8, SalesForceTktId = 'PW-29760'
--WHERE 
--doc_name IN (
--'BDG_SPED_D_02272023_8560082'
--)
--AND fk_batch_id IN (
--6897795
--)