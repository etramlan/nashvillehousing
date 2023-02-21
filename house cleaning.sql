SELECT TOP (1000) [UniqueID]
      ,[ParcelID]
      ,[LandUse]
      ,[PropertyAddress]
      ,[SaleDate]
      ,[SalePrice]
      ,[LegalReference]
      ,[SoldAsVacant]
      ,[OwnerName]
      ,[OwnerAddress]
      ,[Acreage]
      ,[TaxDistrict]
      ,[LandValue]
      ,[BuildingValue]
      ,[TotalValue]
      ,[YearBuilt]
      ,[Bedrooms]
      ,[FullBath]
      ,[HalfBath]
  FROM [housing].[dbo].[nashville_housing]

  --- Cleaning up time

--check if the date format already standardized
  SELECT SaleDate, CONVERT(date, SaleDate)
  FROM housing.dbo.nashville_housing --date format is already fine


--POPULATE PROPERTY ADDRESS DATA

/*Some address is NULL but should not be because the address should correspond ParcelID,
So I have to somehow populate the NULL value in address with the address with the same ParcelID */

SELECT *
FROM housing.dbo.nashville_housing
ORDER BY ParcelID

-- Self join to "mirror" each one but with NULL as value in one(a) and correct address in other(b)

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM housing.dbo.nashville_housing a
JOIN housing.dbo.nashville_housing b
ON a.ParcelId = b.ParcelID
AND a.UniqueID <> b.UniqueID -- So we can find where exatcly the address with NULL value by exlcuding unique ID 
WHERE a.PropertyAddress IS NULL

 -- After checking where are the property address with NULL value now I will populate in table

UPDATE a -- using alias because i'm updating join query
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM housing.dbo.nashville_housing a
JOIN housing.dbo.nashville_housing b
ON a.ParcelId = b.ParcelID
AND a.UniqueID <> b.UniqueID 
WHERE a.PropertyAddress IS NULL 

-- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (ADDRESS, CITY, STATE)

SELECT PropertyAddress
FROM housing.dbo.nashville_housing

SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) as Address -- Extract address only in PropertyAddress column
, SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))  as City -- Extract City only in PropertyAddress column
FROM housing.dbo.nashville_housing

-- Add address column

ALTER TABLE housing.dbo.nashville_housing
Add Address NVARCHAR(255)

UPDATE housing.dbo.nashville_housing
SET Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

-- Add City column

ALTER TABLE housing.dbo.nashville_housing
Add City NVARCHAR(255)

UPDATE housing.dbo.nashville_housing
SET City = SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress)+1, LEN(PropertyAddress))


-- fix owner address

SELECT OwnerAddress
FROM housing.DBO.nashville_housing

-- break it down using PARSENAME
SELECT 
PARSENAME(REPLACE(OwnerAddress,',','.'),3), -- replace comma in OwneAddress to '.' because PARSENAME only recognize '.'
PARSENAME(REPLACE(OwnerAddress,',','.'),2),
PARSENAME(REPLACE(OwnerAddress,',','.'),1)
FROM housing.DBO.nashville_housing /*Unlike SUBSTRING, PARSENAME look for value in a backward manner
meaning that it looks for value (.) closest to the end of string first*/

-- Add owner address column

ALTER TABLE housing.dbo.nashville_housing
Add OwnerAddress_split NVARCHAR(255)

UPDATE housing.dbo.nashville_housing
SET OwnerAddress_split = PARSENAME(REPLACE(OwnerAddress,',','.'),3)

-- Add owner city column

ALTER TABLE housing.dbo.nashville_housing
Add owner_city NVARCHAR(255)

UPDATE housing.dbo.nashville_housing
SET owner_city = PARSENAME(REPLACE(OwnerAddress,',','.'),2)

-- Add owner State column

ALTER TABLE housing.dbo.nashville_housing
Add owner_state NVARCHAR(255)

UPDATE housing.dbo.nashville_housing
SET owner_state = PARSENAME(REPLACE(OwnerAddress,',','.'),1)

-- inspect at soldAsVacant column

SELECT DISTINCT SoldAsVacant
FROM housing.dbo.nashville_housing -- It seems that the value is 1 and 0

-- change to Yes and No to make it more sensible

SELECT SoldAsVacant,
    CAST(CASE WHEN SoldAsVacant = 1 THEN 'Yes' -- cast as string to convert the data from number
        WHEN SoldAsVacant = 0 THEN 'No'
        ELSE CAST(SoldAsVacant AS VARCHAR(10)) END AS VARCHAR(10))
FROM housing.dbo.nashville_housing

-- Now update the table 
-- but first let change the column value first

ALTER TABLE housing.dbo.nashville_housing -- need to change because it was in bit data type before
ALTER COLUMN SoldAsVacant VARCHAR(10) NULL

UPDATE housing.dbo.nashville_housing
SET SoldAsVacant = CASE
    WHEN SoldAsVacant = 1 THEN 'Yes'
    WHEN SoldAsVacant = 0 THEN 'No'
    ELSE CAST(SoldAsVacant AS VARCHAR(10))
END

SELECT *
FROM housing.dbo.nashville_housing -- voila



-- REMOVING DUPLICATES

WITH rownum AS 
(SELECT *, ROW_NUMBER()OVER(PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference -- to identify where the duplicates are located
ORDER by UniqueID) row_num
FROM housing.dbo.nashville_housing)
DELETE -- using temporary table I can now remove duplicates using DELETE
FROM rownum
WHERE row_num >1



-- Delete unused Columns


ALTER TABLE housing.dbo.nashville_housing -- because this is my personal project I can easily do this
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

SELECT * 
FROM housing.dbo.nashville_housing

