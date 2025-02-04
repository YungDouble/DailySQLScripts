-- Pipe-delimited variable for choosing which Record Series to pull.
-- E.g., 'SR|SPED|HR' or 'SR|SPED'

USE yfNSH;
GO

DECLARE @RecordSeries varchar(16) = 'SR';

-- Create a table variable to hold the subset of DocIdMetaData values
DECLARE @SelectedDocIdMetaData TABLE (DocIdMetaData VARCHAR(255));

-- Insert the specific DocIdMetaData values you want to filter
INSERT INTO @SelectedDocIdMetaData (DocIdMetaData)
VALUES 
    ('16066261'), ('16066363'), ('16066377'), ('16066468'), ('16066716'), 
    ('16066852'), ('16067034'), ('16067374'), ('16067544'), ('16067689');

-- Generate tree structure for extract.
DECLARE @RecordSeriesId INT = (
	SELECT
		CASE @RecordSeries 
            WHEN 'SR' THEN 1 
            WHEN 'SPED' THEN 2 
            WHEN 'HR' THEN 3 
            WHEN 'AR' THEN 4 
            ELSE 5 
		END AS [RecordSeriesId]
);

-- Generate the DocIdMetaData for duplicates.
IF (@RecordSeriesId IN (1, 2, 3))
BEGIN
    ;WITH [DocIdMetaData] AS (
        SELECT
            [tDD].[Id] AS 'DocDatabaseId',
            CASE 
                WHEN ROW_NUMBER() OVER(PARTITION BY [tDD].[DocIdMetaData] ORDER BY [tDD].[Id] ASC) = 1 
                    THEN [tDD].[DocIdMetaData]
                ELSE 
                    [tDD].[DocIdMetaData] + '_' + CAST(ROW_NUMBER() OVER(PARTITION BY [tDD].[DocIdMetaData] ORDER BY [tDD].[Id] ASC) AS VARCHAR(100))
            END AS 'DocIdMetaData'
        FROM
            [dbo].[tDocDetails] [tDD] (NOLOCK)
        WHERE
            [tDD].[RSId] = @RecordSeriesId
            AND [tDD].[IsDeleted] <> 1
            AND [tDD].[DocIdMetaData] IN (SELECT DocIdMetaData FROM @SelectedDocIdMetaData) -- Filter applied here
    ),
    [DocVersionIdMetaData] AS (
        SELECT
            [tDV].[Id] AS 'DocVersionDatabaseId',
            CASE 
                WHEN ROW_NUMBER() OVER(PARTITION BY [tDV].[DocIdMetaData] ORDER BY [tDV].[Id] ASC) = 1 
                    THEN [tDV].[DocIdMetaData]
                ELSE 
                    [tDV].[DocIdMetaData] + '_' + CAST(ROW_NUMBER() OVER(PARTITION BY [tDV].[DocIdMetaData] ORDER BY [tDV].[Id] ASC) AS VARCHAR(100))
            END AS 'DocVersionIdMetaData'
        FROM
            [dbo].[tDocVersion] [tDV] (NOLOCK)
        JOIN 
            [dbo].[tDocDetails] [tDD] (NOLOCK) 
            ON [tDV].[DocDetailsId] = [tDD].[Id]
        WHERE
            [tDD].[RSId] = @RecordSeriesId
            AND [tDD].[IsDeleted] <> 1
            AND [tDD].[DocIdMetaData] IN (SELECT DocIdMetaData FROM @SelectedDocIdMetaData) -- Filter applied here
    )
    SELECT
        [tDD].[Id] AS 'DocDatabaseId',
        [MD].[DocIdMetaData] AS 'DocIdMetaData',
        CONCAT([tARS].[DMSDocStorageActivePath], '\', [tDD].[DocGUID], '.', [mFT].[FileType]) AS 'PhysicalFilePath',
        -- Account for document version
        CONCAT(
            '\', DB_NAME(), '\', [mAI].[AttrAbbr],
            CASE 
                WHEN [tDD].[IsActiveDoc] = 1 THEN '\Active\' + 
                    CONCAT(
                        [dbo].[fn_ReplaceIllegalCharacters]([mC].[CampusName]), '\',
                        LEFT(LTRIM(RTRIM([tPD].[LastName])), 1), '\',
                        ISNULL(LTRIM(RTRIM([tPD].[LastName])), '') + ', ' + ISNULL(LTRIM(RTRIM([tPD].[FirstName])), '') + 
                        ' - ' + 
                        CASE 
                            WHEN ISNULL([tPD].[IdentificationNumber], '') = '' 
                                THEN ISNULL(LTRIM(RTRIM(CONVERT(VARCHAR(10), [tPD].[DateofBirth]))), '') 
                            ELSE [tPD].[IdentificationNumber] 
                        END, '\'
                    )
                ELSE '\Archive\' + 
                    CONCAT(
                        [mC].[CampusName], '\',
                        LEFT(LTRIM(RTRIM([tPD].[LastName])), 1), '\',
                        ISNULL(LTRIM(RTRIM([tPD].[LastName])), '') + ', ' + ISNULL(LTRIM(RTRIM([tPD].[FirstName])), '') + 
                        ' - ' + 
                        CASE 
                            WHEN ISNULL([tPD].[IdentificationNumber], '') = '' 
                                THEN ISNULL(LTRIM(RTRIM(CONVERT(VARCHAR(10), [tPD].[DateofBirth]))), '') 
                            ELSE [tPD].[IdentificationNumber] 
                        END, '\'
                    )
            END,
            -- Construct file name
            CASE 
                WHEN ISNULL(LTRIM(RTRIM([tDD].[CustomDocumentName])), '') <> '' 
                    THEN REPLACE(LTRIM(RTRIM([tDD].[CustomDocumentName])), '.pdf', '') + 
                         ' - (' + ISNULL([MD].[DocIdMetaData], 'NoDocIdMetaData') + ').' + [mFT].[FileType]
                ELSE
                    ISNULL(LTRIM(RTRIM([tPD].[LastName])), '') + ' - ' + 
                    ISNULL(LTRIM(RTRIM([tPD].[FirstName])), '') + ' - (' + 
                    ISNULL([MD].[DocIdMetaData], 'NoDocIdMetaData') + ')'
            END
        ) AS 'RelativeFilePath'
    FROM
        [dbo].[tDocDetails] [tDD] (NOLOCK)
    JOIN 
        [DocIdMetaData] [MD] 
        ON [tDD].[Id] = [MD].[DocDatabaseId]
    JOIN 
        [dbo].[tAcctRecordSeries] [tARS] (NOLOCK) 
        ON [tDD].[RSId] = [tARS].[RecordSeriesId]
    JOIN 
        [dbo].[mAcctIdentity] [mAI] (NOLOCK) 
        ON [tDD].[RSId] = [mAI].[Id] AND [mAI].[AttrType] = 'RecordSeries'
    JOIN 
        [dbo].[mFileTypes] [mFT] (NOLOCK) 
        ON [tDD].[FileTypeId] = [mFT].[Id]
    JOIN 
        [dbo].[mCampus] [mC] (NOLOCK) 
        ON [tDD].[CampusId] = [mC].[Id]
    JOIN 
        [dbo].[tPersonData] [tPD] (NOLOCK) 
        ON [tDD].[PersonDataId] = [tPD].[Id]
    WHERE
        [tDD].[RSId] = @RecordSeriesId
        AND [tDD].[IsDeleted] <> 1
        AND [MD].[DocIdMetaData] IN (SELECT DocIdMetaData FROM @SelectedDocIdMetaData); -- Final filter
END;
