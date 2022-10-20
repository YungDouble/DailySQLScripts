USE yfPAD
GO

	--SELECT * FROM dbo.mAcctIdentity
	--WHERE RSLink = 1
	--AND AttrType = 'UCustomPerPro'

--Academic Testing
--Correspondence
--Learning Specialists
--Psych Evals

/*
This script is useful for insert / update DocType access for specific Permission Profile and DocType
*/

/*
SELECT
    mat.id
	,mat.CatName
	,mat.CatFolderLevel
	,mat.CatParentId
	,mat.IRISClassName
	,mat.IsDeleted
    --,tatrr.*

    --Soft Delete a DocType
--UPDATE mat SET mat.[IsDocType] = 0, isdeleted = 1
 
    --Update DocName
--UPDATE mat SET mat.[CatNameCSV] = 'Pre-Yellowfolder', mat.[CatName] = 'Pre-Yellowfolder', mat.[IRISClassName] = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE('Pre-Yellowfolder',' ',''),'/',''), '\',''),')',''),'(',''), '-',''),'.',''),',','')
  
    --Update Doctype in tDocDetails
--UPDATE tdd SET tdd.[AccountTemplateId] = 10
  
    --Update Retention Rules 
--UPDATE [tatrr] SET tatrr.[FirstRetentionRuleYears] = 10 --, tatrr.[SecondRetentionRuleYears] = 9999, tatrr.[ThirdRetentionRuleYears] = 9999
  
FROM
    dbo.[mAccountTemplate] mat (NOLOCK)
    --   JOIN
	   --dbo.[tDocDetails] tdd
	   --ON [mat].[Id] = [tdd].[AccountTemplateId]
    JOIN
	   dbo.[tAccountTemplateRecordSeries] tatrs (NOLOCK)
	   ON tatrs.[AccountTemplateId] = [mat].[Id]
    JOIN
	   dbo.[tAccountTemplateRetentionRule] tatrr (NOLOCK)
	   ON [mat].[Id] = [tatrr].[AccountTemplateId]
    WHERE 
	   tatrs.[RecordSeriesId] = 1  AND mat.[IsDeleted] <> 1 AND mat.[CatName] IN ( 
	   'Official Transcript and Grades (Attendance)')
ORDER BY
    mat.[CatName]
*/
    ---------------------------------------------------------------------------------
/*  
     DECLARE @SuperCategoryId int
	SET @SuperCategoryId = 0
	
	EXEC [sp_InsertDocumentCategoryAccountLevel_ForAllLevel]
	'Progress Reports',--@p_CatName Varchar(100),                          
	1,--@p_CatFolderLevel int,                          
	0,--@p_CatParentId int,                          
	1,--@p_IsDocType BIT,                          
	2,--@p_RecordSeriesId int,                          
	'Permanent',--@p_DocTypeRetention Varchar(100),  
	67,--@p_BasicFAId int,  
	68,--@p_BasicAdminFAId int,  
	68,--@p_PrivacyAdminFAId int,  
	66,--@p_NoAccessFAId int,  
	68,--@p_RMOAdminFAId int,  
	68,--@p_RSAAdminFAId int,  
	@SuperCategoryId output                        
	
	select @SuperCategoryId
*/
	----------------------------

--/*SET NOCOUNT ON

BEGIN TRY

BEGIN TRANSACTION

declare @RecordSeriesId int
declare @PerProfileId int
declare @DocTypeId int
declare @FileAccessId int

declare @RecordSeriesAbbrName varchar(4)
declare @PerProfile  varchar(500)
declare @FileAccess varchar(500)
declare @DocTypeName varchar(500)

------------------------Need to set below paramter--------
set @RecordSeriesAbbrName = 'SR' --(SR / SPED / HR / AR)
/*
@PerProfile 
It will be any default permission(Basic / Basic Admin / No Access / Privacy Admin / RMO Admin / RSA Admin
 or any Custom Permission Profile.
 Make sure we have added Custom Profile in database
*/
SET @PerProfile = 'School Counselor'
SET @DocTypeName = 'Psych Evals'-- Pass DocType Name for which you want to Add or Update FileAcess
set @FileAccess = 'View & Edit'--   (View / View & Edit / No Access)
------------------------End of need to set below paramter--------

-------------------
SET @RecordSeriesId = (select Id from mAcctIdentity where  AttrAbbr=@RecordSeriesAbbrName AND AttrType ='RecordSeries' and IsDeleted=1)
SET @PerProfileId = (select Id
						from mAcctIdentity 
						where AttrName = @PerProfile  
								and IsDeleted=1 
								AND (
											(AttrType ='UPerPro') OR (AttrType='UCustomPerPro' and RSLink=@RecordSeriesId and IsUDV=1)) 
									)

set @FileAccessId = (select Id from mAcctIdentity where  AttrName = @FileAccess and AttrType='FAccessRule' and IsDeleted=1)

SET @DocTypeId = (select mat.Id from mAccountTemplate mat
 inner join tAccountTemplateRecordSeries tatrs
  on mat.id = tatrs.AccountTemplateId
where mat.IsDocType=1
and mat.IsDeleted=0
and tatrs.RecordSeriesId=@RecordSeriesId
and mat.CatName = @DocTypeName)


	IF ISNULL(@DocTypeId,0)=0
	BEGIN   
		ROLLBACK TRANSACTION         
		SELECT 'DocType not present in DB : ' + @DocTypeName AS Result       
	 RETURN         
	END

	IF ISNULL(@PerProfileId,0)=0
	BEGIN   
		ROLLBACK TRANSACTION         
		SELECT 'Enter proper Permission Profile : ' + @PerProfile AS Result       
	 RETURN         
	END

	IF ISNULL(@RecordSeriesId,0)=0
	BEGIN   
		ROLLBACK TRANSACTION         
		SELECT 'Enter proper Record Series : ' + @RecordSeriesAbbrName AS Result       
	 RETURN         
	END
	
	IF ISNULL(@FileAccessId,0)=0
	BEGIN   
		ROLLBACK TRANSACTION         
		SELECT 'Enter proper File Access : ' + @FileAccess AS Result       
	 RETURN         
	END

if not EXISTS(select Id 
				from tDocTypePer 
				where AccountTemplateId=@DocTypeId
					AND RecordSeriesId=@RecordSeriesId 
					and PerProfileId = @PerProfileId
				)
BEGIN
INSERT INTO [dbo].[tDocTypePer]
           ([AccountTemplateId]
           ,[RecordSeriesId]
           ,[PerProfileId]
           ,[FileAccessRuleId])
     VALUES
           (@DocTypeId--<AccountTemplateId, int,>
           ,@RecordSeriesId--<RecordSeriesId, int,>
           ,@PerProfileId--<PerProfileId, int,>
           ,@FileAccessId--<FileAccessRuleId, int,>
		   )
END
ELSE
BEGIN
		update tDocTypePer 
		set FileAccessRuleId=@FileAccessId 
		where AccountTemplateId=@DocTypeId
			and RecordSeriesId=@RecordSeriesId
			and PerProfileId=@PerProfileId
END

COMMIT TRANSACTION

select 'DocType Add / Update successfully.' as 'Result'

END TRY

BEGIN CATCH
    IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION

    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    DECLARE @ErrorLine INT = ERROR_LINE();
    DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
    DECLARE @ErrorState INT = ERROR_STATE();

    PRINT 'Actual error number: ' + CAST(@ErrorNumber AS VARCHAR(10));
    PRINT 'Actual line number: ' + CAST(@ErrorLine AS VARCHAR(10));

    select @ErrorMessage as 'Result'

    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState)  
    
  END CATCH
  --*/
