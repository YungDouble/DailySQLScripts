-- Pipe delimitted variable for choosing which Record Series to pull.
-- E.g. 'SR|SPED|HR' or 'SR|SPED'

USE yfNSH
GO

DECLARE @RecordSeries varchar(16) = 'SR';

-- Create a table variable to hold the subset of DocIdMetaData values
DECLARE @SelectedDocIdMetaData TABLE (DocIdMetaData VARCHAR(255));

-- Insert the specific DocIdMetaData values you want to filter
INSERT INTO @SelectedDocIdMetaData (DocIdMetaData)
VALUES 
    ('16066261'), ('16066363'), ('16066377'), ('16066468'), ('16066716'), 
('16066852'), ('16067034'), ('16067374'), ('16067544'), ('16067689')

-- Generate tree structure for extract.
DECLARE @RecordSeriesId INT = (
	SELECT
		CASE @RecordSeries WHEN 'SR' THEN 1 
		WHEN 'SPED' THEN 2 
		WHEN 'HR' THEN 3 
		WHEN 'AR' THEN 4 
		ELSE 5 
		END AS [RecordSeriesId]
	)
-- Generate the DocIdMetaData for duplicates.

IF(@RecordSeriesId in(1,2,3))
BEGIN
	;WITH [DocIdMetaData] AS (
	SELECT
		[tDD].[Id] AS 'DocDatabaseId'
		,CASE 
			WHEN ROW_NUMBER() OVER(PARTITION BY [tDD].[DocIdMetaData] ORDER BY [tDD].[Id] ASC) = 1 THEN [tDD].[DocIdMetaData]
			WHEN ROW_NUMBER() OVER(PARTITION BY [tDD].[DocIdMetaData] ORDER BY [tDD].[Id] ASC) > 1 THEN [tDD].[DocIdMetaData] + '_' + CAST(ROW_NUMBER() OVER(PARTITION BY [tDD].[DocIdMetaData] ORDER BY [tDD].[Id] ASC) AS varchar(100))
			ELSE [tDD].[DocIdMetaData]
	END AS 'DocIdMetaData'
		FROM
		[dbo].[tDocDetails] [tDD] (NOLOCK)
	WHERE
		[tDD].[RSId] = @RecordSeriesId
		AND [tDD].[IsDeleted] <> 1)
		AND [tDD].[DocIdMetaData] IN (SELECT DocIdMetaData FROM @SelectedDocIdMetaData),
	[DocVersionIdMetaData] AS
	(SELECT
		[tDV].[Id] AS 'DocVersionDatabaseId'
		,CASE 
			WHEN ROW_NUMBER() OVER(PARTITION BY [tDV].[DocIdMetaData] ORDER BY [tDV].[Id] ASC) = 1 THEN [tDV].[DocIdMetaData]
			WHEN ROW_NUMBER() OVER(PARTITION BY [tDV].[DocIdMetaData] ORDER BY [tDV].[Id] ASC) > 1 THEN [tDV].[DocIdMetaData] + '_' + CAST(ROW_NUMBER() OVER(PARTITION BY [tDV].[DocIdMetaData] ORDER BY [tDV].[Id] ASC) AS varchar(100))
			ELSE [tDV].[DocIdMetaData]
	END AS 'DocVersionIdMetaData'
		FROM
		[dbo].[tDocVersion] [tDV] (NOLOCK)
		JOIN [dbo].[tDocDetails] [tDD] (NOLOCK) ON [tDV].[DocDetailsId] = [tDD].[Id]
	WHERE
		[tDD].[RSId] = @RecordSeriesId
		AND [tDD].[IsDeleted] <> 1)	
	SELECT
		[tDD].[Id] AS 'DocDatabaseId'
		,[MD].[DocIdMetaData] AS 'DocIdMetaData'	
		,CONCAT([tARS].[DMSDocStorageActivePath], '\', [tDD].[DocGUID], '.', [mFT].[FileType]) AS 'PhysicalFilePath'
		-- Account for document version.  
	
		,CONCAT('\', DB_NAME(), '\' + [mAI].[AttrAbbr])
		+ CASE
			-- Active documents.
			WHEN [tDD].[IsActiveDoc] = 1 THEN	'\Active\'
											-- Campus name.
											+ CONCAT([dbo].[fn_ReplaceIllegalCharacters]([mC].[CampusName]), + '\')
											-- Person last name initial.
											+ CONCAT(LEFT(LTRIM(RTRIM([tPD].[LastName])),1), '\')
											-- Person folder. 
											+ CONCAT(ISNULL(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tPD].[LastName]))),''), ', ', ISNULL(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tPD].[FirstName]))),''), ' - ', ISNULL(CASE WHEN ISNULL([tPD].[IdentificationNumber],'') = '' THEN ISNULL(LTRIM(RTRIM(CONVERT(varchar(10),[tPD].[DateofBirth]))),'') ELSE [dbo].[fn_ReplaceIllegalCharacters]([tPD].[IdentificationNumber]) END,''), '\')
											-- Document category and type.
											+ CASE
												WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') = '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') = '' 
													THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
												WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') = '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') <> ''
													THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocCategory].[CatName]))), '\' + LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
												WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') <> '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') <> ''
													THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocSuperCategory].[CatName]))), '\', LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocCategory].[CatName]))), '\', LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
											END
			-- Archive documents.
			WHEN [tDD].[IsActiveDoc] = 0 THEN	'\Archive\' 
											-- Campus name.
											+ CONCAT([mC].[CampusName], + '\')
											-- Archival year.
											+ CONCAT(CASE
												WHEN [tDD].[RSId] = 1 
													THEN ISNULL(CAST(YEAR(CASE WHEN [tPDSR].[GraduationDate] IS NOT NULL THEN [tPDSR].[GraduationDate] WHEN [tPDSR].[GraduationDate] IS NULL AND [tPDSR].[WithdrawalDate] IS NOT NULL THEN [tPDSR].[WithdrawalDate] WHEN [tPDSR].[GraduationDate] IS NOT NULL AND [tPDSR].[WithdrawalDate] IS NOT NULL THEN [tPDSR].[GraduationDate] END) AS varchar(8)), 'No Year')
												WHEN [tDD].[RSId] = 2 
													THEN ISNULL(CAST(YEAR([tPDSPED].[MostRecentArdDate]) AS varchar(4)), 'No Year')
												WHEN [tDD].[RSId] = 3
													THEN ISNULL(CAST(YEAR([tPDHR].[TerminationDate]) AS varchar(4)), 'No Year')
											END, '\')
											-- Person last name initial.
											+ CONCAT(LEFT(LTRIM(RTRIM([tPD].[LastName])),1), '\')
											-- Person folder. 
											+ CONCAT(ISNULL(LTRIM(RTRIM([tPD].[LastName])),''), ', ', ISNULL(LTRIM(RTRIM([tPD].[FirstName])),''), ' - ', ISNULL(CASE WHEN ISNULL([tPD].[IdentificationNumber],'') = '' THEN ISNULL(LTRIM(RTRIM(CONVERT(varchar(10),[tPD].[DateofBirth]))),'') ELSE [tPD].[IdentificationNumber] END,''), '\')
											-- Document category and type.
											+ CASE
												WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') = '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') = '' 
													THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
												WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') = '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') <> ''
													THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocCategory].[CatName]))), '\' + LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
												WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') <> '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') <> ''
													THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocSuperCategory].[CatName]))), '\', LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocCategory].[CatName]))), '\', LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
											END

		END
		-- File name.
		+ CASE
			WHEN ISNULL(LTRIM(RTRIM([tDD].[CustomDocumentName])),'') <> ''
				THEN CONCAT(REPLACE(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tDD].[CustomDocumentName]))),'.pdf',''), ' - (', ISNULL([MD].[DocIdMetaData],'NoDocIdMetaData'), ')', '.', [mFT].[FileType])
			ELSE
		-- Construct file name when custom document name does not exist.
		(CONCAT(ISNULL(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))),''), ' - ', ISNULL(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tPD].[LastName]))),''), ', ', ISNULL(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tPD].[FirstName]))),''), ' - ',
		(CASE
			WHEN ISNULL(LTRIM(RTRIM([tPD].[IdentificationNumber])),'') <> '' 
				THEN LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tPD].[IdentificationNumber])))
			WHEN ISNULL(LTRIM(RTRIM([tPD].[IdentificationNumber])),'') = '' AND ISNULL(LTRIM(RTRIM(CAST([tPD].[DateofBirth] AS varchar(10)))),'') <> ''
				THEN LTRIM(RTRIM(CAST([tPD].[DateofBirth] AS varchar(10))))
			WHEN ISNULL(LTRIM(RTRIM([tPD].[IdentificationNumber])),'') = '' AND ISNULL(LTRIM(RTRIM(CAST([tPD].[DateofBirth] AS varchar(10)))),'') = ''
				THEN '0000-00-00'
		END),
		' - (', ISNULL([MD].[DocIdMetaData],'NoDocIdMetaData'), ')', ' - ', LEFT([tDD].[DocGUID],8), '.', [mFT].[FileType]))
		END AS 'RelativeFilePath'
	FROM
		[dbo].[tDocDetails] [tDD] (NOLOCK)
		JOIN [DocIdMetaData] [MD]
			ON [tDD].[Id] = [MD].[DocDatabaseId]	
		JOIN [dbo].[tAcctRecordSeries] [tARS] (NOLOCK)
			ON [tDD].[RSId] = [tARS].[RecordSeriesId]
		JOIN [dbo].[mAcctIdentity] [mAI] (NOLOCK)
			ON [tDD].[RSId] = [mAI].[Id]
			AND [mAI].[AttrType] = 'RecordSeries'
		JOIN [dbo].[mFileTypes] [mFT] (NOLOCK)
			ON [tDD].[FileTypeId] = [mFT].[Id]
		JOIN [dbo].[mCampus] [mC] (NOLOCK)
			ON [tDD].[CampusId] = [mC].[Id]
		-- Person data.
		JOIN [dbo].[tPersonData] [tPD] (NOLOCK)
			ON [tDD].[PersonDataId] = [tPD].[Id]
		LEFT JOIN [dbo].[tPersonDataSR] [tPDSR]
			ON [tPD].[Id] = [tPDSR].[PersonDataId]
			AND [tPD].[RecordSeriesId] = 1
		LEFT JOIN [dbo].[tPersonDataSPED] [tPDSPED] (NOLOCK)
			ON [tPD].[Id] = [tPDSPED].[PersonDataId]
			AND [tPD].[RecordSeriesId] = 2
		LEFT JOIN [dbo].[tPersonDataHR] [tPDHR] (NOLOCK)
			ON [tPD].[Id] = [tPDHR].[PersonDataId]
			AND [tPD].[RecordSeriesId] = 3
		-- Document category and type.
		JOIN [dbo].[mAccountTemplate] [mAT_DocType] (NOLOCK)
			ON [tDD].[AccountTemplateId] = [mAT_DocType].[Id]
			AND [mAT_DocType].[CatName] <> 'Recycle Bin - Trash'
		LEFT JOIN [dbo].[mAccountTemplate] [mAT_DocCategory] (NOLOCK)
			ON [mAT_DocCategory].[Id] = ISNULL([mAT_DocType].[CatParentId],0)
		LEFT JOIN [dbo].[mAccountTemplate] [mAT_DocSuperCategory] (NOLOCK)
			ON [mAT_DocSuperCategory].[Id] = ISNULL([mAT_DocCategory].[CatParentId],0)
	WHERE
		[tDD].[RSId] IN (1,2,3)
		AND [tDD].[RSId] = @RecordSeriesId
		AND [tDD].[IsDeleted] <> 1
	UNION
	SELECT
		[tDV].[Id] AS 'DocDatabaseId'
		,[MDV].[DocVersionIdMetaData] AS 'DocIdMetaData'	
		,CONCAT([tARS].[DMSDocStorageActivePath], '\', [tDV].[DocGUID], '.', [mFT].[FileType]) AS 'PhysicalFilePath'
		-- Account for document version.  
	
		,CONCAT('\', DB_NAME(), '\' + [mAI].[AttrAbbr])
		+ CASE
			-- Active documents.
			WHEN [tDD].[IsActiveDoc] = 1 THEN	'\Active\'
											-- Campus name.
											+ CONCAT([dbo].[fn_ReplaceIllegalCharacters]([mC].[CampusName]), + '\')
											-- Person last name initial.
											+ CONCAT(LEFT(LTRIM(RTRIM([tPD].[LastName])),1), '\')
											-- Person folder. 
											+ CONCAT(ISNULL(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tPD].[LastName]))),''), ', ', ISNULL(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tPD].[FirstName]))),''), ' - ', ISNULL(CASE WHEN ISNULL([tPD].[IdentificationNumber],'') = '' THEN ISNULL(LTRIM(RTRIM(CONVERT(varchar(10),[tPD].[DateofBirth]))),'') ELSE [dbo].[fn_ReplaceIllegalCharacters]([tPD].[IdentificationNumber]) END,''), '\')
											-- Document category and type.
											+ CASE
												WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') = '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') = '' 
													THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
												WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') = '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') <> ''
													THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocCategory].[CatName]))), '\' + LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
												WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') <> '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') <> ''
													THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocSuperCategory].[CatName]))), '\', LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocCategory].[CatName]))), '\', LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
											END
			-- Archive documents.
			WHEN [tDD].[IsActiveDoc] = 0 THEN	'\Archive\' 
											-- Campus name.
											+ CONCAT([mC].[CampusName], + '\')
											-- Archival year.
											+ CONCAT(CASE
												WHEN [tDD].[RSId] = 1 
													THEN ISNULL(CAST(YEAR(CASE WHEN [tPDSR].[GraduationDate] IS NOT NULL THEN [tPDSR].[GraduationDate] WHEN [tPDSR].[GraduationDate] IS NULL AND [tPDSR].[WithdrawalDate] IS NOT NULL THEN [tPDSR].[WithdrawalDate] WHEN [tPDSR].[GraduationDate] IS NOT NULL AND [tPDSR].[WithdrawalDate] IS NOT NULL THEN [tPDSR].[GraduationDate] END) AS varchar(8)), 'No Year')
												WHEN [tDD].[RSId] = 2 
													THEN ISNULL(CAST(YEAR([tPDSPED].[MostRecentArdDate]) AS varchar(4)), 'No Year')
												WHEN [tDD].[RSId] = 3
													THEN ISNULL(CAST(YEAR([tPDHR].[TerminationDate]) AS varchar(4)), 'No Year')
											END, '\')
											-- Person last name initial.
											+ CONCAT(LEFT(LTRIM(RTRIM([tPD].[LastName])),1), '\')
											-- Person folder. 
											+ CONCAT(ISNULL(LTRIM(RTRIM([tPD].[LastName])),''), ', ', ISNULL(LTRIM(RTRIM([tPD].[FirstName])),''), ' - ', ISNULL(CASE WHEN ISNULL([tPD].[IdentificationNumber],'') = '' THEN ISNULL(LTRIM(RTRIM(CONVERT(varchar(10),[tPD].[DateofBirth]))),'') ELSE [tPD].[IdentificationNumber] END,''), '\')
											-- Document category and type.
											+ CASE
												WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') = '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') = '' 
													THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
												WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') = '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') <> ''
													THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocCategory].[CatName]))), '\' + LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
												WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') <> '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') <> ''
													THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocSuperCategory].[CatName]))), '\', LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocCategory].[CatName]))), '\', LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
											END

		END
		-- File name.
		+ CASE
			WHEN ISNULL(LTRIM(RTRIM([tDD].[CustomDocumentName])),'') <> ''
				THEN CONCAT(REPLACE(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tDD].[CustomDocumentName]))),'.pdf',''), ' - (', ISNULL([MDV].[DocVersionIdMetaData],'NoDocIdMetaData'), ')', '.', [mFT].[FileType])
			ELSE
		-- Construct file name when custom document name does not exist.
		(CONCAT(ISNULL(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))),''), ' - ', ISNULL(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tPD].[LastName]))),''), ', ', ISNULL(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tPD].[FirstName]))),''), ' - ',
		(CASE
			WHEN ISNULL(LTRIM(RTRIM([tPD].[IdentificationNumber])),'') <> '' 
				THEN LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tPD].[IdentificationNumber])))
			WHEN ISNULL(LTRIM(RTRIM([tPD].[IdentificationNumber])),'') = '' AND ISNULL(LTRIM(RTRIM(CAST([tPD].[DateofBirth] AS varchar(10)))),'') <> ''
				THEN LTRIM(RTRIM(CAST([tPD].[DateofBirth] AS varchar(10))))
			WHEN ISNULL(LTRIM(RTRIM([tPD].[IdentificationNumber])),'') = '' AND ISNULL(LTRIM(RTRIM(CAST([tPD].[DateofBirth] AS varchar(10)))),'') = ''
				THEN '0000-00-00'
		END),
		' - (', ISNULL([MDV].[DocVersionIdMetaData],'NoDocIdMetaData'), ')', ' - ', LEFT([tDV].[DocGUID],8), '.', [mFT].[FileType]))
		END AS 'RelativeFilePath'
	FROM
		[dbo].[tDocVersion] [tDV] (NOLOCK)
		JOIN [dbo].[tDocDetails] [tDD] (NOLOCK) ON [tDV].[DocDetailsId] = [tDD].[Id]
		JOIN [DocVersionIdMetaData] [MDV]
			ON [tDV].[Id] = [MDV].[DocVersionDatabaseId]	
		JOIN [dbo].[tAcctRecordSeries] [tARS] (NOLOCK)
			ON [tDD].[RSId] = [tARS].[RecordSeriesId]
		JOIN [dbo].[mAcctIdentity] [mAI] (NOLOCK)
			ON [tDD].[RSId] = [mAI].[Id]
			AND [mAI].[AttrType] = 'RecordSeries'
		JOIN [dbo].[mFileTypes] [mFT] (NOLOCK)
			ON [tDV].[FileTypeId] = [mFT].[Id]
		JOIN [dbo].[mCampus] [mC] (NOLOCK)
			ON [tDD].[CampusId] = [mC].[Id]
		-- Person data.
		JOIN [dbo].[tPersonData] [tPD] (NOLOCK)
			ON [tDD].[PersonDataId] = [tPD].[Id]
		LEFT JOIN [dbo].[tPersonDataSR] [tPDSR]
			ON [tPD].[Id] = [tPDSR].[PersonDataId]
			AND [tPD].[RecordSeriesId] = 1
		LEFT JOIN [dbo].[tPersonDataSPED] [tPDSPED] (NOLOCK)
			ON [tPD].[Id] = [tPDSPED].[PersonDataId]
			AND [tPD].[RecordSeriesId] = 2
		LEFT JOIN [dbo].[tPersonDataHR] [tPDHR] (NOLOCK)
			ON [tPD].[Id] = [tPDHR].[PersonDataId]
			AND [tPD].[RecordSeriesId] = 3
		-- Document category and type.
		JOIN [dbo].[mAccountTemplate] [mAT_DocType] (NOLOCK)
			ON [tDD].[AccountTemplateId] = [mAT_DocType].[Id]
			AND [mAT_DocType].[CatName] <> 'Recycle Bin - Trash'
		LEFT JOIN [dbo].[mAccountTemplate] [mAT_DocCategory] (NOLOCK)
			ON [mAT_DocCategory].[Id] = ISNULL([mAT_DocType].[CatParentId],0)
		LEFT JOIN [dbo].[mAccountTemplate] [mAT_DocSuperCategory] (NOLOCK)
			ON [mAT_DocSuperCategory].[Id] = ISNULL([mAT_DocCategory].[CatParentId],0)
	WHERE
		[tDD].[RSId] IN (1,2,3)
		AND [tDD].[RSId] = @RecordSeriesId
		AND [tDD].[IsDeleted] <> 1
END

-- AR Extraction
--ELSE IF (@RecordSeriesId = 4)
--BEGIN

--;WITH [DocIdMetaData] AS (
--	SELECT
--		[tDD].[Id] AS 'DocDatabaseId'
--		,CASE 
--			WHEN ROW_NUMBER() OVER(PARTITION BY [tDD].[DocIdMetaData] ORDER BY [tDD].[Id] ASC) = 1 THEN [tDD].[DocIdMetaData]
--			WHEN ROW_NUMBER() OVER(PARTITION BY [tDD].[DocIdMetaData] ORDER BY [tDD].[Id] ASC) > 1 THEN [tDD].[DocIdMetaData] + '_' + CAST(ROW_NUMBER() OVER(PARTITION BY [tDD].[DocIdMetaData] ORDER BY [tDD].[Id] ASC) AS varchar(100))
--			ELSE [tDD].[DocIdMetaData]
--	END AS 'DocIdMetaData'
--		FROM
--		[dbo].[tDocDetails] [tDD] (NOLOCK)
--	WHERE
--		[tDD].[RSId] = @RecordSeriesId
--		AND [tDD].[IsDeleted] <> 1),
--	[DocVersionIdMetaData] AS
--	(SELECT
--		[tDV].[Id] AS 'DocVersionDatabaseId'
--		,CASE 
--			WHEN ROW_NUMBER() OVER(PARTITION BY [tDV].[DocIdMetaData] ORDER BY [tDV].[Id] ASC) = 1 THEN [tDV].[DocIdMetaData]
--			WHEN ROW_NUMBER() OVER(PARTITION BY [tDV].[DocIdMetaData] ORDER BY [tDV].[Id] ASC) > 1 THEN [tDV].[DocIdMetaData] + '_' + CAST(ROW_NUMBER() OVER(PARTITION BY [tDV].[DocIdMetaData] ORDER BY [tDV].[Id] ASC) AS varchar(100))
--			ELSE [tDV].[DocIdMetaData]
--	END AS 'DocVersionIdMetaData'
--		FROM
--		[dbo].[tDocVersion] [tDV] (NOLOCK)
--		JOIN [dbo].[tDocDetails] [tDD] (NOLOCK) ON [tDV].[DocDetailsId] = [tDD].[Id]
--	WHERE
--		[tDD].[RSId] = @RecordSeriesId
--		AND [tDD].[IsDeleted] <> 1)	
---- Generate tree structure for AR.
--SELECT
--	[tDD].[Id] AS 'DocDatabaseId'	
--	,[MD].[DocIdMetaData] AS 'DocIdMetaData'	
--	,CONCAT([tARS].[DMSDocStorageActivePath], '\', [tDD].[DocGUID], '.', [mFT].[FileType]) AS 'PhysicalFilePath'
--		-- Account for document version.  
	
--	,CONCAT('\', DB_NAME(), '\AR\')
--	-- File path.
--	-- Document category and type.
--	+ CASE
--		WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') = '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') = '' 
--			THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
--			THEN CONCAT(LTRIM(RTRI		WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') = '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') <> ''
--M([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocCategory].[CatName]))), '\' + LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
--		WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') <> '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') <> ''
--			THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocSuperCategory].[CatName]))), '\', LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocCategory].[CatName]))), '\', LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
--	END
--	-- File name.
--	+ CASE
--		WHEN ISNULL(LTRIM(RTRIM([tDD].[CustomDocumentName])),'') <> ''
--			THEN CONCAT(REPLACE(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tDD].[CustomDocumentName]))),'.pdf',''), ' - (', ISNULL([MD].[DocIdMetaData],'NoDocIdMetaData'), ')', '.', [mFT].[FileType])
--		ELSE
--	-- Construct file name when custom document name does not exist.
--	(CONCAT(ISNULL(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))),''),
--    ' - (', ISNULL([MD].[DocIdMetaData],'NoDocIdMetaData'), ')', ' - ', LEFT([tDD].[DocGUID],8), '.', [mFT].[FileType]))
--	END AS 'RelativeFilePath'
--FROM
--	[dbo].[tDocDetails] [tDD] (NOLOCK)
--	JOIN [DocIdMetaData] [MD]
--		ON [tDD].[DocIdMetaData] = [MD].[DocIdMetaData]	
--	JOIN [dbo].[tAcctRecordSeries] [tARS] (NOLOCK)
--		ON [tDD].[RSId] = [tARS].[RecordSeriesId]
--	JOIN [dbo].[mFileTypes] [mFT] (NOLOCK)
--		ON [tDD].[FileTypeId] = [mFT].[Id]
--	-- Person data.
--	JOIN [dbo].[tPersonData] [tPD] (NOLOCK)
--		ON [tDD].[PersonDataId] = [tPD].[Id]
--	-- Document category and type.
--	JOIN [dbo].[mAccountTemplate] [mAT_DocType] (NOLOCK)
--		ON [tDD].[AccountTemplateId] = [mAT_DocType].[Id]
--		AND [mAT_DocType].[CatName] <> 'Recycle Bin - Trash'
--	LEFT JOIN [dbo].[mAccountTemplate] [mAT_DocCategory] (NOLOCK)
--		ON [mAT_DocCategory].[Id] = ISNULL([mAT_DocType].[CatParentId],0)
--	LEFT JOIN [dbo].[mAccountTemplate] [mAT_DocSuperCategory] (NOLOCK)
--		ON [mAT_DocSuperCategory].[Id] = ISNULL([mAT_DocCategory].[CatParentId],0)
--WHERE
--	[tDD].[RSId] = 4
--	AND [tDD].[RSId] = @RecordSeriesId
--	AND [tDD].[IsDeleted] <> 1

--UNION

--SELECT
--	[tDV].[Id] AS 'DocDatabaseId'	
--	,[MDV].[DocVersionIdMetaData] AS 'DocIdMetaData'	
--	,CONCAT([tARS].[DMSDocStorageActivePath], '\', [tDV].[DocGUID], '.', [mFT].[FileType]) AS 'PhysicalFilePath'
--		-- Account for document version.  
	
--	,CONCAT('\', DB_NAME(), '\AR\')
--	-- File path.
--	-- Document category and type.
--	+ CASE
--		WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') = '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') = '' 
--			THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
--		WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') = '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') <> ''
--			THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocCategory].[CatName]))), '\' + LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
--		WHEN ISNULL(LTRIM(RTRIM([mAT_DocSuperCategory].[CatName])),'') <> '' AND ISNULL(LTRIM(RTRIM([mAT_DocCategory].[CatName])),'') <> ''
--			THEN CONCAT(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocSuperCategory].[CatName]))), '\', LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocCategory].[CatName]))), '\', LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))), '\')
--	END
--	-- File name.
--	+ CASE
--		WHEN ISNULL(LTRIM(RTRIM([tDD].[CustomDocumentName])),'') <> ''
--			THEN CONCAT(REPLACE(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([tDD].[CustomDocumentName]))),'.pdf',''), ' - (', ISNULL([MDV].[DocVersionIdMetaData],'NoDocIdMetaData'), ')', '.', [mFT].[FileType])
--		ELSE
--	-- Construct file name when custom document name does not exist.
--	(CONCAT(ISNULL(LTRIM(RTRIM([dbo].[fn_ReplaceIllegalCharacters]([mAT_DocType].[CatName]))),''),
--    ' - (', ISNULL([MDV].[DocVersionIdMetaData],'NoDocIdMetaData'), ')', ' - ', LEFT([tDV].[DocGUID],8), '.', [mFT].[FileType]))
--	END AS 'RelativeFilePath'
--FROM
--	[dbo].[tDocVersion] [tDV] (NOLOCK)
--	JOIN [dbo].[tDocDetails] [tDD] (NOLOCK) ON [tDV].[DocDetailsId] = [tDD].[Id]
--	JOIN [DocVersionIdMetaData] [MDV]
--		ON [tDV].[DocIdMetaData] = [MDV].[DocVersionIdMetaData]	
--	JOIN [dbo].[tAcctRecordSeries] [tARS] (NOLOCK)
--		ON [tDD].[RSId] = [tARS].[RecordSeriesId]
--	JOIN [dbo].[mFileTypes] [mFT] (NOLOCK)
--		ON [tDV].[FileTypeId] = [mFT].[Id]
--	-- Person data.
--	JOIN [dbo].[tPersonData] [tPD] (NOLOCK)
--		ON [tDD].[PersonDataId] = [tPD].[Id]
--	-- Document category and type.
--	JOIN [dbo].[mAccountTemplate] [mAT_DocType] (NOLOCK)
--		ON [tDD].[AccountTemplateId] = [mAT_DocType].[Id]
--		AND [mAT_DocType].[CatName] <> 'Recycle Bin - Trash'
--	LEFT JOIN [dbo].[mAccountTemplate] [mAT_DocCategory] (NOLOCK)
--		ON [mAT_DocCategory].[Id] = ISNULL([mAT_DocType].[CatParentId],0)
--	LEFT JOIN [dbo].[mAccountTemplate] [mAT_DocSuperCategory] (NOLOCK)
--		ON [mAT_DocSuperCategory].[Id] = ISNULL([mAT_DocCategory].[CatParentId],0)
--WHERE
--	[tDD].[RSId] = 4
--	AND [tDD].[RSId] = @RecordSeriesId
--	AND [tDD].[IsDeleted] <> 1;
--END
