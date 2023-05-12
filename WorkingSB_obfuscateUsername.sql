USE YellowFolderProd
GO

/* -----Select Stalled batches for all accounts except ANT----- */
SELECT DISTINCT b.pk_batch_id, b.batch_name,b.physical_box_name,b.fk_batch_status_id,b.tool_flag, ma.alias, b.fk_account_id, b.created_by
, b.created_date,LEFT(scm_user_name, 10), dd.PageNumber, dd.doc_size
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
--b.batch_name IN (
--'FRMD04262023-7204590_FRM_SR_Categorize Scan'
--,'FRMD04262023-7204592_FRM_SR_Categorize Scan'
--,'FRMD04262023-7204639_FRM_SR_Categorize Scan'
--)
--b.created_by = 11180
b.fk_account_id NOT IN (1130,79,1331)
--AND ma.alias = 'JFC'
AND b.scan_type = 'C'
AND b.batch_name NOT LIKE  (
'CKC_06%'
)
AND b.fk_batch_status_id IN (22) 
	AND ba.pk_batch_id NOT IN
	(
	SELECT 
		pk_batch_id FROM batch_audit ba (NOLOCK)
		WHERE fk_batch_status_id = 1031
		AND ba.action_date BETWEEN '2023-05-12' AND '2023-05-13'
	)
	AND b.created_date between '2023-01-01' and '2023-05-12'
	ORDER BY b.batch_name
