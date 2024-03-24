--DATA CLEANING USING SQL QUERIES
SELECT * FROM [dbo].[NashvilleHousing]
---------------------------------------------------------------------------------------------------------------------------------------------------

--STANDADIZING DATE FORMAT, OUR DATE (SaleDate)COLUMN HAS TIME FORMAT BESIDE IT AND ITS' OF NO USE
SELECT SaleDate FROM NashvilleHousingProject.dbo.NashvilleHousing

--SELECT SaleDate, CONVERT(Date,SaleDate)
--FROM NashvilleHousingProject.dbo.NashvilleHousing

--UPDATE NashvilleHousing
--SET SaleDate = CONVERT(Date,SaleDate)
----ABOVE DID NOT WORK OUT

----SO I ADDED A NEW COLUMN
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date

----UPDATED THE NEW COLUMN AND SETTING IT TO OUR CONVERT(Date,SaleDate)
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

----WHERE IT CREATED A NEW COLUMN WITH THE PREVIOUS COLUMN
SELECT SaleDateConverted, CONVERT(Date,SaleDate) FROM NashvilleHousingProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing DROP COLUMN SaleDate --DROPPED THE INITIAL COLUMN SaleDate
EXEC sp_rename 'NashvilleHousing.SaleDateConverted', 'SaleDate' --RENAMED SaleDateConverted TO SaleDate
SELECT * FROM NashvilleHousing

---------------------------------------------------------------------------------------------------------------------------------------------------

----POPULATE COLUMN (PropertyAddress) BASED ON ANOTHER COLUMN (ParcelID)
----POPULATING A COLUMN REFERS TO ADDING DATA TO IT BASED ON ANOTHER COLUMN
SELECT * 
FROM NashvilleHousingProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL

----FROM OUR ParcelID COLUMN, WHEN THERE IS SIMILAR ID, ITS ALWAYS THE SAME PropertyAddress. 
--SO BASICLLY, IF A ParcelID WITH PropertyAddress AND THE SAME ParcelID(ANOTHER ROW) WITH NO PropertyAddress, POPULATE WITH THE FIRST PropertyAddress
SELECT * 
FROM NashvilleHousingProject.dbo.NashvilleHousing
ORDER BY ParcelID

----LETS DO A SELF JOIN
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM NashvilleHousingProject.dbo.NashvilleHousing a
join NashvilleHousingProject.dbo.NashvilleHousing b
  on a.ParcelID = b.ParcelID
  AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

--LETS POPULATE USING ISNULL
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
ISNULL(a.PropertyAddress, b.PropertyAddress)
----THIS MEANS, WHAT ARE WE CHECKING TO SEE IF ITS NULL, IF NULL  POPULATE WITH THE ORTHER
FROM NashvilleHousingProject.dbo.NashvilleHousing a
join NashvilleHousingProject.dbo.NashvilleHousing b
  on a.ParcelID = b.ParcelID
  AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

----LETS UPDATE 
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousingProject.dbo.NashvilleHousing a
join NashvilleHousingProject.dbo.NashvilleHousing b
  on a.ParcelID = b.ParcelID
  AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL
----RERUN THE ABOVE AND YOU FIND OUT THERE'S NO LONGER A NULL VALUES IN PropertyAddress

SELECT * FROM NashvilleHousingProject.dbo.NashvilleHousing
WHERE PropertyAddress IS NULL

---------------------------------------------------------------------------------------------------------------------------------------------------

----BREAKING OUT PropertyAddress COLUMN TO INDIVIDUAL COLUMNS (Address, City) USING SUBSTRING AND CHARINDEX
--CHARINDEX FUNCTION SEARCHES FOR A SUBSTRING IN A STRING, AND RETURNS THE POSITION IE 
--CHARINDEX(expressionToFind, expressionToSearch[,Start_location])
SELECT PropertyAddress FROM NashvilleHousing

SELECT PropertyAddress,
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1) AS PropertySplitAddress, 
-- -1 excludes the delimiter(comma) after the address and also avoid printing out numbers.
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress)) AS PropertySplitCity
--SINCE WE ARE NOT STARTING AT FIRST POSITION, WE EXCLUDED THE ,1 AND ALSO WE ADDED +1 BECAUSE WE DON'T WANT TO INCLUDE THE DELIMITER(,)
  --AND LEN(PropertyAddress) IS USED TO SPECIFY WHERE IT NEEDS TO GOTO.
FROM NashvilleHousing

----LETS CREATE NEW COLUMNS (Address and City)FOR THE SPLITTED COLUMNS
ALTER TABLE NashvilleHousing
ADD Address Nvarchar(255)

UPDATE NashvilleHousing
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1)
EXEC sp_rename 'NashvilleHousing.Address', 'AddressOfProperty'


ALTER TABLE NashvilleHousing
ADD City Nvarchar(255)

UPDATE NashvilleHousing
SET City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN(PropertyAddress))
EXEC sp_rename  'NashvilleHousing.City', 'CityOfProperty'

SELECT * FROM NashvilleHousing


---ANOTHER METHOD OF SPLITTING COLUMN
---BREAKING OUT OwnerAddress COLUMN TO INDIVIDUAL COLUMNS (Address, City and State) USING PARSENAME FUNCTION
---PARSENAME FUNCTION IS USED TO EXTRACT CERTAIN PARTS OF AN OBJECT NAME, COLUMN NAME OR DATABASE NAME BASED ON A SPECIFIED DELIMITER
---USES THE REPLACE FUNCTION TO REPLACE THE DELIMITER WITH A PERIOD(.)
SELECT
OwnerAddress,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS Address,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS City,
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS State
FROM NashvilleHousing

---LETS CREATE NEW COLUMNS AND EQUATE TO ABOVE QUERIES
ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255)

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerCity nvarchar(255)

UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerState nvarchar(255)

UPDATE NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


---------------------------------------------------------------------------------------------------------------------------------------------------

----CHANGING ROWS WITH INCORRECT VALUES FOR A COLUMN 
----CHANGE Y AND N TO YES AND NO IN SoldAsVacant column
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM NashvilleHousing 
GROUP BY SoldAsVacant
ORDER BY 2
----WE HAD COUNT OF Y=52, N=399, Yes=4623 and No=51403, LETS USE THE CASE STATEMENT

SELECT SoldAsVacant,
CASE WHEN SoldAsVacant='Y' THEN 'Yes'
     WHEN SoldAsVacant='N' THEN 'No'
	 ELSE SoldAsVacant
END
FROM NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant='Y' THEN 'Yes'
     WHEN SoldAsVacant='N' THEN 'No'
	 ELSE SoldAsVacant
END

SELECT DISTINCT(SoldAsVacant) FROM NashvilleHousing


---------------------------------------------------------------------------------------------------------------------------------------------------

----REMOVING DUPLICATES- Removing Duplicates with ROW_NUMBER
--LETS VIEW DUPLICATE ROWS
SELECT *,
    ROW_NUMBER() OVER(
    PARTITION BY ParcelID,
	             PropertyAddress,
				 SalePrice,
				 LegalReference
				 ORDER BY UniqueID) AS row_num
FROM NashvilleHousing
ORDER BY ParcelID
--WHERE row_num >1, WHERE CLAUSE CAN'T BE USED IN WINDOWS FUNCTIONS SO WE ARE GOING TO CREATE A CTE (WE WANT TO SEE THE DUPLICATED ROWS ONLY)
--ORDER BY CANT WORK WITHIN CTE, USE WHEN PULLING OUT TABLE

WITH RowNumCTE AS 
(
SELECT *,
    ROW_NUMBER() OVER(
    PARTITION BY ParcelID,
	             PropertyAddress,
				 SalePrice,
				 LegalReference
				 ORDER BY UniqueID) AS row_num
FROM NashvilleHousing
--ORDER BY ParcelID
)
SELECT * FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

----ABOUT 121 ROWS WHERE DUPLICATES, SO LET DELETE THE DUPLICATES
WITH RowNumCTE AS 
(
SELECT *,
    ROW_NUMBER() OVER(
    PARTITION BY ParcelID,
	             PropertyAddress,
				 SalePrice,
				 LegalReference
				 ORDER BY UniqueID) AS row_num
FROM NashvilleHousing
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1
--ORDER BY PropertyAddress, WILL NOT WORK HERE
--RE-RUN THE PREVIOUS ABOVE AND NO MORE DUPLICATES

---------------------------------------------------------------------------------------------------------------------------------------------------
----DELETING UNUSED COLUMNS
SELECT * FROM NashvilleHousing

ALTER TABLE NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict
