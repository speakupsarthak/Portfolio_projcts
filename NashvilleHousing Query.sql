
Select * From Housing

-- Altering the SaleDate format

Select SaleDate, convert(date, SaleDate) as SaleDay
From Housing

Alter table Housing
Add SaleDay date

Update Housing
Set SaleDay = convert(date, SaleDate)

-- Populating the Property addresses that are null

Select a.[UniqueID ], a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
	   ISNULL(a.PropertyAddress, b.PropertyAddress)
From Housing a
Join Housing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From Housing a
Join Housing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

-- Breaking out the Property address into 2 columns using Charindex

Select PropertyAddress, SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1),
	   SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, Len(PropertyAddress)) 
From Housing

Alter table Housing
Add Address nvarchar(255),
	City nvarchar(255)

Update Housing
Set Address = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1),
	City = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, Len(PropertyAddress))

-- Breaking out the Owner address into 3 columns using Parsename

Select OwnerAddress,
	   PARSENAME(Replace(OwnerAddress, ',', '.'), 3),
	   PARSENAME(Replace(OwnerAddress, ',', '.'), 2),
	   PARSENAME(Replace(OwnerAddress, ',', '.'), 1)
From Housing

Alter table Housing
Add OwnerSplitAddress nvarchar(255),
	OwnerSplitCity nvarchar(255),
	OwnerSplitState nvarchar(255)

Update Housing
Set OwnerSplitAddress = PARSENAME(Replace(OwnerAddress, ',', '.'), 3),
	OwnerSplitCity = PARSENAME(Replace(OwnerAddress, ',', '.'), 2),
	OwnerSplitState = PARSENAME(Replace(OwnerAddress, ',', '.'), 1)

-- Changing 'Y' to 'Yes' and 'N' to 'No' in Sold as vacant Column

Select SoldAsVacant, count(SoldAsVacant)
From Housing
Group by SoldAsVacant
Order by 2

Select Case
		When SoldAsVacant = 'N' Then REPLACE(SoldAsVacant, 'N', 'No')
		When SoldAsVacant = 'Y' Then REPLACE(SoldAsVacant, 'Y', 'Yes')
		Else SoldAsVacant
		End
From Housing

Update Housing
Set SoldAsVacant = Case
	When SoldAsVacant = 'N' Then REPLACE(SoldAsVacant, 'N', 'No')
	When SoldAsVacant = 'Y' Then REPLACE(SoldAsVacant, 'Y', 'Yes')
	Else SoldAsVacant
	End

-- Removing Duplicates using CTE and Partition by

With RowNumCTE as(
Select *,
	ROW_NUMBER() over(Partition by ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
					  Order by UniqueID) as Row_num
From Housing)

Delete From RowNumCTE
Where Row_num > 1

-- Dropping Columns: PropertyAddress, OwnerAddress, Tax District, SaleDate(Danger! Might lead to data loss)

Alter Table Housing
Drop Column PropertyAddress, OwnerAddress, TaxDistrict, SaleDate