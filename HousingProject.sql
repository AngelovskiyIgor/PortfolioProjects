-----------------------------------------------------------------------------------
--------- Housing Project

--------- Cleaning data in SQL
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
------ Exploring the dataset

SELECT TOP (100) *
FROM HousingProject..NashvilleHousing


-----------------------------------------------------------------------------------
------ Changing date format

ALTER TABLE HousingProject..NashvilleHousing
ALTER COLUMN SaleDate DATE

---- Check for changes

SELECT *
FROM HousingProject..NashvilleHousing


-----------------------------------------------------------------------------------
------ Fixing missing data (Property Address)

SELECT *
FROM HousingProject..NashvilleHousing
WHERE PropertyAddress is null

-- Some property addresses are missing. Possible solution: households with the same ParcelID have the same property address.

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM HousingProject..NashvilleHousing AS a
JOIN HousingProject..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ] -- to avoid altering of UniqueID when using JOIN (UniqueID is unique and should not repeat itself)
WHERE a.PropertyAddress is null

-- Now we can clearly see that households with the same ParcelID have the same address.
-- Now we need to populate property addresses based on the ParcelID as a reference.

---- Let's populate PropertyAddress:

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM HousingProject..NashvilleHousing AS a
JOIN HousingProject..NashvilleHousing AS b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ] -- to avoid altering of UniqueID when using JOIN (UniqueID is unique and should not repeat itself)

---- Check for changes

SELECT *
FROM HousingProject..NashvilleHousing
WHERE PropertyAddress is null


-----------------------------------------------------------------------------------
------ Spliting PropertyAddress into 2 columns: Address, City

---- Add new columns to the table

ALTER TABLE HousingProject..NashvilleHousing
ADD Property_Address NVARCHAR(500)

ALTER TABLE HousingProject..NashvilleHousing
ADD Property_City NVARCHAR(500)

UPDATE HousingProject..NashvilleHousing
SET Property_Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)
-- we are using SUBSTRING clause to extract data from original column,
-- we use CHARINDEX clause to index the ending point of data extracting

UPDATE HousingProject..NashvilleHousing
SET Property_City = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))
-- we use CHARINDEX clause to index the starting point of data extracting and LEN clause to index the ending point

---- Check for changes

SELECT *
FROM HousingProject..NashvilleHousing


------------------------------------------------------------------------------------
------ Spliting OwnerAddress into 3 columns: Address, City, State

---- Add new columns to the table

ALTER TABLE HousingProject..NashvilleHousing
ADD Owner_Address NVARCHAR(500)

ALTER TABLE HousingProject..NashvilleHousing
ADD Owner_City NVARCHAR(500)

ALTER TABLE HousingProject..NashvilleHousing
ADD Owner_State NVARCHAR(500)

-- in this step we used PARSENAME clause.
-- PARSENAME clause use '.' as a dilimiter, so first of all we used REPLACE to replace ',' with '.'

UPDATE HousingProject..NashvilleHousing
SET Owner_Address = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

UPDATE HousingProject..NashvilleHousing
SET Owner_City = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

UPDATE HousingProject..NashvilleHousing
SET Owner_State = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

---- Check for changes

SELECT *
FROM HousingProject..NashvilleHousing


------------------------------------------------------------------------------------
------ Changing SoldAsVacant column data

--- What values we have in SoldAsVacant column?

SELECT DISTINCT(SoldAsVacant)
FROM HousingProject..NashvilleHousing

-- We have four distinct values (Yes, No, Y, N). We are going to change 'N' and 'Y' to 'No' and 'Yes'.

UPDATE HousingProject..NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
WHEN SoldAsVacant = 'N' THEN 'No' ELSE SoldAsVacant
END

---- Check for changes

SELECT DISTINCT(SoldAsVacant)
FROM HousingProject..NashvilleHousing


------------------------------------------------------------------------------------
------ Removing duplicates

---- Let's find duplicates:

WITH RowNumberCTE AS (
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) RowNum

From HousingProject..NashvilleHousing
)
Select *
From RowNumberCTE
Where RowNum > 1
Order by ParcelID

-- we had to partition by things that should be unique to each observation (row): ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference.

---- Let's delete duplicates:

WITH RowNumberCTE AS (
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) RowNum

From HousingProject..NashvilleHousing
)
DELETE
From RowNumberCTE
Where RowNum > 1


------------------------------------------------------------------------------------
------ Removing unused columns

ALTER TABLE HousingProject..NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, SaleDate
