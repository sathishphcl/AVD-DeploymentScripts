$Context = New-AzStorageContext -StorageAccountName "ucorpwvdprem" -StorageAccountKey "<StorageAccountKey>"
Get-AzStorageFileHandle -Context $Context -ShareName "fslogixoffice" -Recursive
Close-AzStorageFileHandle -Context $Context -ShareName "fslogixoffice" -CloseAll