/*
Cleaning Data in SQL Queries
*/

select *, SaleDate 
from PortfolioProject..NashvilleHousing

--------------------------------------------------------------------------------------------------------------------
--Standardize Date Format

select SaleDate, 
SaleDate = convert(Date, SaleDate)
from PortfolioProject..NashvilleHousing

alter table NashvilleHousing
add SaleDateConverted Date;

update n
set SaleDateConverted = convert(Date, SaleDate)
from PortfolioProject..NashvilleHousing n

--------------------------------------------------------------------------------------------------------------------
--Populate Property Address Data

----Find records with missing Property Address

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..NashvilleHousing a
join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ] 
where a.PropertyAddress is null

----Populate Property Address values by ParcelID where found in other records

update a
set a.PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject..NashvilleHousing a
join PortfolioProject..NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ] 
where a.PropertyAddress is null

--------------------------------------------------------------------------------------------------------------------
--Breaking out Address into Individual Columns (Address, City, State)

select PropertyAddress
from PortfolioProject..NashvilleHousing
--where PropertyAddress is null
--order by ParcelID

select 
PropertySplitAddress = substring(PropertyAddress, 1, charindex(',', PropertyAddress) -1)
, PropertySplitCity =  substring(PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress))
from PortfolioProject..NashvilleHousing

alter table NashvilleHousing
add PropertySplitAddress nvarchar(255);

update n
set PropertySplitAddress = substring(PropertyAddress, 1, charindex(',', PropertyAddress) -1)
from PortfolioProject..NashvilleHousing n

alter table NashvilleHousing
add PropertySplitCity nvarchar(255);

update n
set PropertySplitCity =  substring(PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress))
from PortfolioProject..NashvilleHousing n

select OwnerAddress
from PortfolioProject..NashvilleHousing


--use parsename to split owner address info
select 
parsename(replace(OwnerAddress, ',', '.') ,3),
parsename(replace(OwnerAddress, ',', '.') ,2),
parsename(replace(OwnerAddress, ',', '.') ,1)
from PortfolioProject..NashvilleHousing
where parsename(replace(OwnerAddress, ',', '.') ,1) is not null


alter table NashvilleHousing
add OwnerSplitAddress nvarchar(255);

update n
set OwnerSplitAddress = parsename(replace(OwnerAddress, ',', '.') ,3)
from PortfolioProject..NashvilleHousing n

alter table NashvilleHousing
add OwnerSplitCity nvarchar(255);

update n
set OwnerSplitCity = parsename(replace(OwnerAddress, ',', '.') ,2)
from PortfolioProject..NashvilleHousing n

alter table NashvilleHousing
add OwnerSplitState nvarchar(255);

update n
set OwnerSplitState = parsename(replace(OwnerAddress, ',', '.') ,1)
from PortfolioProject..NashvilleHousing n

--------------------------------------------------------------------------------------------------------------------

--Change Y and N to Yes and No in "Sold as Vacant" field

select distinct(SoldAsVacant), count(SoldAsVacant)
from PortfolioProject..NashvilleHousing
group by SoldAsVacant


select SoldAsVacant
, case when SoldAsVacant = 'N' then 'No'
	   when SoldAsVacant = 'Y' then 'Yes'
	   else SoldAsVacant 
	   end
from PortfolioProject..NashvilleHousing
--where SoldAsVacant in ('N', 'Y')

update n
set n.SoldAsVacant = case when SoldAsVacant = 'N' then 'No'
	   when SoldAsVacant = 'Y' then 'Yes'
	   else SoldAsVacant 
	   end
from PortfolioProject..NashvilleHousing n

--------------------------------------------------------------------------------------------------------------------
--Remove Duplicates
--...not standard practice to remove duplicates, particularly from raw/source data...we would typically mark these as bad records and let business management decide what to do with them

--The following fields are the same across two or more records, making duplicate records based on intent of dataset:  ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference

with RowNumCTE as (
select *, 
RowNum = row_number() over(
partition by ParcelID, 
			 PropertyAddress,
			 SalePrice,
			 SaleDate,
			 LegalReference
			 order by
				UniqueID
				)
from PortfolioProject..NashvilleHousing
)

select *
from RowNumCTE
where RowNum > 1

--104 duplicate records returned prior to DELETION

--Now let's delete the duplicates using a similar CTE

with RowNumCTE as (
select *, 
RowNum = row_number() over(
partition by ParcelID, 
			 PropertyAddress,
			 SalePrice,
			 SaleDate,
			 LegalReference
			 order by
				UniqueID
				)
from PortfolioProject..NashvilleHousing
)
DELETE 
from RowNumCTE
where RowNum > 1

--The CTE to find duplicates, above, now yields zero records after we successfully deleted the 104

--------------------------------------------------------------------------------------------------------------------
--Delete Unused Columns

select *
from PortfolioProject..NashvilleHousing

alter table PortfolioProject..NashvilleHousing
drop column OwnerAddress, TaxDistrict, PropertyAddress

alter table PortfolioProject..NashvilleHousing
drop column SaleDate

--Our data set is now CLEAN!!!
--------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------

