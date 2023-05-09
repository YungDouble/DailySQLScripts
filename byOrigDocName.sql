USE YellowFolderProd
GO

--681 @ 4:39
-- Manual Batches passed through parser may be on users dashboard as IR

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
b.fk_account_id NOT IN (1130,79,1331)
--AND b.batch_name = 'ILDD01032023-6688024_ILD_SPED_Categorize Scan'
AND ma.alias = 'ILD'
AND dd.doc_original_name LIKE (
'A.D. Initial OT Assessment%'
) 
AND b.created_date BETWEEN '2020-01-01' and '2023-05-08'
	ORDER BY b.batch_name
