SELECT CONCAT(LastName, FirstName, IdentificationNumber) key_person
, LastName, FirstName, IdentificationNumber , DateofBirth
FROM dbo.tPersonData
WHERE RecordSeriesId = 3

SELECT * FROM dbo.tPersonData
WHERE IdentificationNumber IN (
'612'
,'411'
,'273'
)



SELECT * FROM dbo.tPersonData
WHERE IdentificationNumber = '0'

SELECT * FROM dbo.tPersonData
WHERE FirstName LIKE 'Index%'
AND RecordSeriesId = 3

SELECT * FROM dbo.tPersonData
WHERE IdentificationNumber = '0'
