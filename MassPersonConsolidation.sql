-- ! Find and replace "OrderByClause" before running !
-- ! The OrderByClause will dictate the manner in which we decide which is selected as the master PersonDataId !
-- Set these variables.
DECLARE @RecordSeries varchar(4) = 'SR' -- (SR/SPED/HR)
DECLARE @ArchiveAll varchar(3) = 'No' -- Pass No to skip archival of persons and documents. Pass Yes to perform archival. Perform only once in conjunction with "PerformConsolidation". Do not perform on additional passes.
DECLARE @PerformConsolidation varchar(3) = 'No' -- Pass No to perform a select of the results. Pass Yes to update the tables.

-- Internal variables.
DECLARE @RecordSeriesID int = (SELECT Id FROM [mAcctIdentity] WHERE AttrAbbr = @RecordSeries AND AttrType = 'RecordSeries')

IF @RecordSeriesID IN (1,2,3)
BEGIN
-- Create the consolidation tables to be used by the CTEs.
IF OBJECT_ID('dbo._Person_Duplicates_InitialConsolidation', 'U') IS NOT NULL DROP TABLE [_Person_Duplicates_InitialConsolidation]
CREATE TABLE [_Person_Duplicates_InitialConsolidation] (
	PersonDataId int
	,FirstName varchar(100)
	,LastName varchar(100)
	,DateofBirth date
	,IdentificationNumber varchar(200)
	,RowNumber tinyint
	)

IF OBJECT_ID('dbo._Person_Duplicates_FinalConsolidation', 'U') IS NOT NULL DROP TABLE [_Person_Duplicates_FinalConsolidation]
CREATE TABLE [_Person_Duplicates_FinalConsolidation] (
	CorrectIdent varchar(200)
	,IncorrectIdent varchar(200)
	,CorrectId int
	,IncorrectId int
	,FirstName varchar(100)
	,LastName varchar(100)
	,DateofBirth date
	)
END
-- Collect the duplicates by IdentificationNumbers.
;WITH [DuplicatesByIdent] AS (
SELECT
	tPD.IdentificationNumber
	,COUNT(*) AS 'Count'
FROM
	[tPersonData] tPD
WHERE
	tPD.RecordSeriesId = @RecordSeriesID
	AND tPD.IdentificationNumber IS NOT NULL
GROUP BY
	tPD.IdentificationNumber
HAVING
	COUNT(*) = 2
)
-- Collect the duplicates by FirstName, LastName, and DateofBirth.
,[DuplicatesByFnLnDob] AS (
SELECT
	tPD.FirstName
	,tPD.LastName
	,CAST(tPD.DateofBirth as date) AS 'DateofBirth'
	,COUNT(*) AS 'Count'
FROM
	[tPersonData] tPD
WHERE
	tPD.RecordSeriesId = @RecordSeriesID
	AND tPD.IdentificationNumber NOT IN (SELECT DBI.IdentificationNumber FROM [DuplicatesByIdent] DBI)
GROUP BY
	tPD.FirstName
	,tPD.LastName
	,CAST(tPD.DateofBirth as date)
HAVING
	COUNT(*) = 2
)

-- Insert the collection of duplicates into a consolidated table.
INSERT INTO [_Person_Duplicates_InitialConsolidation] (
	PersonDataId
	,FirstName
	,LastName
	,DateofBirth
	,IdentificationNumber
	,RowNumber
	)
SELECT
	tPD.Id
	,tPD.FirstName
	,tPD.LastName
	,CAST(tPD.DateofBirth as date) AS 'DateofBirth'
	,tPD.IdentificationNumber
	,ROW_NUMBER() OVER (PARTITION BY tPD.IdentificationNumber ORDER BY Id ASC) AS 'RowNumber'
FROM
	[DuplicatesByIdent] DBI
	JOIN [tPersonData] tPD
		ON DBI.IdentificationNumber = tPD.IdentificationNumber
WHERE
	tPD.RecordSeriesId = @RecordSeriesID
UNION
SELECT
	tPD.Id
	,tPD.FirstName
	,tPD.LastName
	,CAST(tPD.DateofBirth as date) AS 'DateofBirth'
	,tPD.IdentificationNumber
	,ROW_NUMBER() OVER (PARTITION BY tPD.FirstName, tPD.LastName, CAST(tPD.DateofBirth as date) ORDER BY CASE WHEN tPD.IdentificationNumber  LIKE '0%' THEN 1 ELSE 2 END) AS 'RowNumber' -- OrderByClause that must be updated per case.
FROM
	[DuplicatesByFnLnDob] DBN
	JOIN [tPersonData] tPD
		ON DBN.FirstName = tPD.FirstName
		AND DBN.LastName = tPD.LastName
		AND DBN.DateofBirth = CAST(tPD.DateofBirth as date)
WHERE
	tPD.RecordSeriesId = @RecordSeriesID
	AND (tPD.IdentificationNumber NOT IN (SELECT DBI.IdentificationNumber FROM [DuplicatesByIdent] DBI) OR tPD.IdentificationNumber IS NULL)

--Insert the set of correct IdentificationNumbers into the _Person_Duplicates_FinalConsolidation table.
INSERT INTO [_Person_Duplicates_FinalConsolidation] (
	CorrectIdent
	,IncorrectIdent
	,CorrectId
	,IncorrectId
	,FirstName
	,LastName
	,DateofBirth
	)
SELECT
	IC.IdentificationNumber AS 'CorrectIdent'
	,NULL AS 'IncorrectIdent'
	,IC.PersonDataId AS 'CorrectId'
	,NULL AS 'IncorrectId'
	,IC.FirstName
	,IC.LastName
	,IC.DateofBirth
FROM
	[_Person_Duplicates_InitialConsolidation] IC
WHERE
	IC.RowNumber = 1

-- Update the _Person_Duplicates_FinalConsolidation table with the erroneous IdentificationNumber (IncorrectIdent)/PersonDataId (IncorrectId) where there is an exact match on IdentificationNumber.
UPDATE
	FC
SET
	FC.IncorrectIdent = IC.IdentificationNumber
	,FC.IncorrectId = IC.PersonDataId
FROM
	[_Person_Duplicates_InitialConsolidation] IC
	JOIN [_Person_Duplicates_FinalConsolidation] FC
		ON IC.IdentificationNumber = FC.CorrectIdent
WHERE
	IC.RowNumber = 2

-- Update the _Person_Duplicates_FinalConsolidation table with the erroneous IdentificationNumber (IncorrectIdent)/PersonDataId (IncorrectId) on a match of FN-LN-DOB.
UPDATE
	FC
SET
	FC.IncorrectIdent = IC.IdentificationNumber
	,FC.IncorrectId = IC.PersonDataId
FROM
	[_Person_Duplicates_InitialConsolidation] IC
	JOIN [_Person_Duplicates_FinalConsolidation] FC
		ON IC.FirstName = FC.FirstName
		AND IC.LastName = FC.LastName
		AND IC.DateofBirth = FC.DateofBirth
WHERE
	IC.RowNumber = 2
	AND FC.IncorrectIdent IS NULL

-- Perform the final clean up.
SET XACT_ABORT ON
DECLARE @StartTranCount INT;
BEGIN
BEGIN TRY
    SELECT @StartTranCount = @@TRANCOUNT -- Error handling.
    IF @StartTranCount = 0
    BEGIN TRANSACTION

IF @PerformConsolidation = 'No'
BEGIN
	SELECT
		*
	FROM
		[_Person_Duplicates_FinalConsolidation]
END
IF @PerformConsolidation = 'Yes'
BEGIN

	-- If ArchiveAll is passed as true, we need to first archive all persons and documents associated to them.
	IF @ArchiveAll = 'Yes'
	BEGIN
		UPDATE
			tPD
		SET
			tPD.[Status] = 0
		FROM
			[tPersonData] tPD
			JOIN [tDocDetails] tDD
				ON tPD.Id = tDD.PersonDataId
		WHERE
			tPD.RecordSeriesId = @RecordSeriesID
		
		UPDATE
			tDD
		SET
			tDD.[IsActiveDoc] = 0
		FROM
			[tPersonData] tPD
			JOIN [tDocDetails] tDD
				ON tPD.Id = tDD.PersonDataId
		WHERE
			tPD.RecordSeriesId = @RecordSeriesID
	END

	-- Associate documents to the correct PersonData entry.
	UPDATE
		tDD
	SET
		tDD.PersonDataId = FC.CorrectID
	FROM
		[tDocDetails] tDD
		JOIN [_Person_Duplicates_FinalConsolidation] FC
		   ON tDD.PersonDataId = FC.IncorrectID
	WHERE
		tDD.RSId = @RecordSeriesID

	-- Clear campus relationships.
	DELETE FROM
		[tStudentCampus]
	WHERE
		PersonDataId IN (SELECT IncorrectID FROM [_Person_Duplicates_FinalConsolidation])
		AND RecordSeriesId = @RecordSeriesID

	-- Clear grade relationships.
	DELETE FROM
		[tStudentGrade]
	WHERE
		PersonDataId IN (SELECT IncorrectID FROM [_Person_Duplicates_FinalConsolidation])
		AND RecordSeriesId = @RecordSeriesID

	-- Record Series specific table cleanup. 
	-- Student Records
	IF @RecordSeriesID = 1
		BEGIN
		DELETE FROM
			[tPersonDataSR]
		WHERE
			PersonDataId IN (SELECT IncorrectID FROM [_Person_Duplicates_FinalConsolidation])
		END
	-- Secial Education Records
	IF @RecordSeriesID = 2
	BEGIN
	DELETE FROM
		[tPersonDataSPED]
	WHERE
		PersonDataId IN (SELECT IncorrectID FROM [_Person_Duplicates_FinalConsolidation])
	END
	-- Human Resource Records
	IF @RecordSeriesID = 3
	BEGIN
	DELETE FROM
		[tPersonDataHR]
	WHERE
		PersonDataId IN (SELECT IncorrectID FROM [_Person_Duplicates_FinalConsolidation])
	END

	-- Delete primary erroneous record.
	DELETE FROM
		[tPersonData]
	WHERE
		Id IN (SELECT IncorrectID FROM [_Person_Duplicates_FinalConsolidation])
		AND RecordSeriesId = @RecordSeriesID
END

    IF @StartTranCount = 0
    COMMIT TRANSACTION
END TRY
BEGIN CATCH -- Error handling.
    IF XACT_STATE() <> 0 AND @StartTranCount = 0
		ROLLBACK TRANSACTION
	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
    SELECT
		@ErrorMessage = ERROR_MESSAGE(),
		@ErrorSeverity = ERROR_SEVERITY(),
		@ErrorState = ERROR_STATE();
    RAISERROR 
		(@ErrorMessage
		,@ErrorSeverity
		,@ErrorState
		);
END CATCH
END;
