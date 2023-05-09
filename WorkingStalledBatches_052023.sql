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
--b.batch_name = 'NCSD06272022-5950584_NCS_SR_Categorize Scan'
b.fk_account_id NOT IN (1130,79,1331)
AND ma.alias = 'LWT'
--AND b.scan_type = 'C'
AND b.batch_name NOT LIKE  (
'CKC_06%'
)
AND b.fk_batch_status_id IN (22,1031,3) 
	AND ba.pk_batch_id NOT IN
	(
	SELECT 
		pk_batch_id FROM batch_audit ba (NOLOCK)
		WHERE fk_batch_status_id = 1031
		AND ba.action_date BETWEEN '2023-05-08' AND '2023-05-09'
	)
	AND b.created_date between '2021-01-01' and '2023-05-07'
	ORDER BY dd.doc_original_name
