metadata name = 'Compute Disks'
metadata description = 'This module deploys a Compute Disk'
metadata owner = 'Azure/module-maintainers'

@description('Required. The name of the disk that is being created.')
param name string

@description('Optional. Resource location.')
param location string = resourceGroup().location

@allowed([
  'Standard_LRS'
  'Premium_LRS'
  'StandardSSD_LRS'
  'UltraSSD_LRS'
  'Premium_ZRS'
  'Premium_ZRS'
  'PremiumV2_LRS'
])
@description('Required. The disks sku name. Can be .')
param sku string

@allowed([
  'x64'
  'Arm64'
  ''
])
@description('Optional. CPU architecture supported by an OS disk.')
param architecture string = ''

@description('Optional. Set to true to enable bursting beyond the provisioned performance target of the disk.')
param burstingEnabled bool = false

@description('Optional. Percentage complete for the background copy when a resource is created via the CopyStart operation.')
param completionPercent int = 100

@allowed([
  'Attach'
  'Copy'
  'CopyStart'
  'Empty'
  'FromImage'
  'Import'
  'ImportSecure'
  'Restore'
  'Upload'
  'UploadPreparedSecure'
])
@description('Optional. Sources of a disk creation.')
param createOption string = 'Empty'

@description('Optional. A relative uri containing either a Platform Image Repository or user image reference.')
param imageReferenceId string = ''

@description('Optional. Logical sector size in bytes for Ultra disks. Supported values are 512 ad 4096.')
param logicalSectorSize int = 4096

@description('Optional. If create option is ImportSecure, this is the URI of a blob to be imported into VM guest state.')
param securityDataUri string = ''

@description('Optional. If create option is Copy, this is the ARM ID of the source snapshot or disk.')
param sourceResourceId string = ''

@description('Optional. If create option is Import, this is the URI of a blob to be imported into a managed disk.')
param sourceUri string = ''

@description('Conditional. The resource ID of the storage account containing the blob to import as a disk. Required if create option is Import.')
param storageAccountId string = ''

@description('Optional. If create option is Upload, this is the size of the contents of the upload including the VHD footer.')
param uploadSizeBytes int = 20972032

@description('Conditional. The size of the disk to create. Required if create option is Empty.')
param diskSizeGB int = 0

@description('Optional. The number of IOPS allowed for this disk; only settable for UltraSSD disks.')
param diskIOPSReadWrite int = 0

@description('Optional. The bandwidth allowed for this disk; only settable for UltraSSD disks.')
param diskMBpsReadWrite int = 0

@allowed([
  'V1'
  'V2'
])
@description('Optional. The hypervisor generation of the Virtual Machine. Applicable to OS disks only.')
param hyperVGeneration string = 'V2'

@description('Optional. The maximum number of VMs that can attach to the disk at the same time. Default value is 0.')
param maxShares int = 1

@allowed([
  'AllowAll'
  'AllowPrivate'
  'DenyAll'
])
@description('Optional. Policy for accessing the disk via network.')
param networkAccessPolicy string = 'DenyAll'

@description('Optional. Setting this property to true improves reliability and performance of data disks that are frequently (more than 5 times a day) by detached from one virtual machine and attached to another. This property should not be set for disks that are not detached and attached frequently as it causes the disks to not align with the fault domain of the virtual machine.')
param optimizedForFrequentAttach bool = false

@allowed([
  'Windows'
  'Linux'
  ''
])
@description('Optional. Sources of a disk creation.')
param osType string = ''

@allowed([
  'Disabled'
  'Enabled'
])
@description('Optional. Policy for controlling export on the disk.')
param publicNetworkAccess string = 'Disabled'

@description('Optional. True if the image from which the OS disk is created supports accelerated networking.')
param acceleratedNetwork bool = false

@description('Optional. Tags of the availability set resource.')
param tags object = {}

resource disk 'Microsoft.Compute/disks@2022-07-02' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    burstingEnabled: burstingEnabled
    completionPercent: completionPercent
    creationData: {
      createOption: createOption
      imageReference: createOption != 'FromImage' ? null : {
        id: imageReferenceId
      }
      logicalSectorSize: contains(sku, 'Ultra') ? logicalSectorSize : null
      securityDataUri: createOption == 'ImportSecure' ? securityDataUri : null
      sourceResourceId: createOption == 'Copy' ? sourceResourceId : null
      sourceUri: createOption == 'Import' ? sourceUri : null
      storageAccountId: createOption == 'Import' ? storageAccountId : null
      uploadSizeBytes: createOption == 'Upload' ? uploadSizeBytes : null
    }
    diskIOPSReadWrite: contains(sku, 'Ultra') ? diskIOPSReadWrite : null
    diskMBpsReadWrite: contains(sku, 'Ultra') ? diskMBpsReadWrite : null
    diskSizeGB: createOption == 'Empty' ? diskSizeGB : null
    hyperVGeneration: empty(osType) ? null : hyperVGeneration
    maxShares: maxShares
    networkAccessPolicy: networkAccessPolicy
    optimizedForFrequentAttach: optimizedForFrequentAttach
    osType: empty(osType) ? any(null) : osType
    publicNetworkAccess: publicNetworkAccess
    supportedCapabilities: empty(osType) ? {} : {
      acceleratedNetwork: acceleratedNetwork
      architecture: empty(architecture) ? null : architecture
    }
  }
}

@description('The resource group the  disk was deployed into.')
output resourceGroupName string = resourceGroup().name

@description('The resource ID of the disk.')
output resourceId string = disk.id

@description('The name of the disk.')
output name string = disk.name

@description('The location the resource was deployed into.')
output location string = disk.location
