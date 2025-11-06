@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '產品新增儲存地點'
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_DIMENSION, #CDS_MODELING_ASSOCIATION_TARGET, #SQL_DATA_SOURCE, #CDS_MODELING_DATA_SOURCE ]
define root view entity ZZ1_I_PRODUCTSTORAGELOCATION 
    as select from I_Product as _Product
    left outer join I_ProductPlantBasic as _ProductPlant on _Product.Product = _ProductPlant.Product
    left outer join I_StorageLocation as _StorageLocation on _ProductPlant.Plant = _StorageLocation.Plant
    
    association[0..1] to I_ProductStorageLocationBasic as _ProductStorageLocationBasic on _Product.Product = _ProductStorageLocationBasic.Product
                                                                                       and _ProductPlant.Plant = _ProductStorageLocationBasic.Plant
                                                                                       and _StorageLocation.StorageLocation = _ProductStorageLocationBasic.StorageLocation
{
    
    key _Product.Product,
    key _ProductPlant.Plant,
    key _StorageLocation.StorageLocation,
         _ProductStorageLocationBasic.StorageLocation as ProductStorageLocation
} where  _ProductStorageLocationBasic.StorageLocation is null
