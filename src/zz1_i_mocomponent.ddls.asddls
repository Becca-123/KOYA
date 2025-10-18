@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '線邊倉發料拋轉MES'
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_DIMENSION, #CDS_MODELING_ASSOCIATION_TARGET, #SQL_DATA_SOURCE, #CDS_MODELING_DATA_SOURCE ]
define root view entity ZZ1_I_MOCOMPONENT 
    as select from I_ManufacturingOrder as _ManufacturingOrder
    join I_MfgOrderOperationComponent as _MfgOrderOperationComponent on _ManufacturingOrder.ManufacturingOrder = _MfgOrderOperationComponent.ManufacturingOrder
    join I_MaterialDocumentItem_2 as mseg on mseg.ManufacturingOrder = _ManufacturingOrder.ManufacturingOrder and _MfgOrderOperationComponent.Reservation = mseg.Reservation 
                                          and mseg.ReservationItem = _MfgOrderOperationComponent.ReservationItem
    join I_MaterialDocumentHeader_2 as mkpf on mseg.MaterialDocument = mkpf.MaterialDocument and mseg.MaterialDocumentYear = mkpf.MaterialDocumentYear
    //left outer join I_ProductSupplyPlanning as _ProductSupplyPlanning on _ManufacturingOrder.Material = _ProductSupplyPlanning.Product and _ManufacturingOrder.ProductionPlant = _ProductSupplyPlanning.Plant
    association[0..1] to ZZ1_I_WOTYPE as _WOTYPE on _ManufacturingOrder.ManufacturingOrderType = _WOTYPE.aufart
{
    
    key _ManufacturingOrder.ManufacturingOrder as WORK_ORDER, 
    key _MfgOrderOperationComponent.Reservation as Reservation, 
    key _MfgOrderOperationComponent.ReservationItem as ReservationItem, 
    key mseg.MaterialDocumentYear,
    key mseg.MaterialDocument,
    key mseg.MaterialDocumentItem,
    _ManufacturingOrder.Material as PART_NO,
    cast( '20' as abap.char(2) ) as WO_PICK_TYPE,
    //_ProductSupplyPlanning.DfltStorageLocationExtProcmt as WAREHOUSE_NO,
    mseg.StorageLocation as WAREHOUSE_NO,
    _MfgOrderOperationComponent.Material as ITEM_PART_NO,
    _MfgOrderOperationComponent.AlternativeItemGroup as ITEM_GROUP, 
    
    @Semantics.quantity.unitOfMeasure: 'EntryUnit'
    mseg.QuantityInEntryUnit as ITEM_COUNT,
    mseg.EntryUnit,
//    @Semantics.quantity.unitOfMeasure: 'BaseUnit'
//    _MfgOrderOperationComponent.RequiredQuantity, 
//    @Semantics.quantity.unitOfMeasure: 'BaseUnit'
//    _MfgOrderOperationComponent.WithdrawnQuantity, 
//    _MfgOrderOperationComponent.BaseUnit,
    _MfgOrderOperationComponent.Plant as FACTORY,
    _MfgOrderOperationComponent.GoodsMovementType as MoveType,
    cast( 
      case
        when mseg.GoodsMovementType = '262'
        then '3'
        else '1'
    end  as abap.char(1) ) as Data_Status,
    
    mseg.PostingDate,
    mkpf.CreatedByUser,
    _MfgOrderOperationComponent.AlternativeItemPriority, 
    _MfgOrderOperationComponent.MatlCompIsMarkedForDeletion
} where  ( ( _MfgOrderOperationComponent.GoodsMovementType = '261' and mseg.ReversedMaterialDocument is initial )
    or ( _MfgOrderOperationComponent.GoodsMovementType = '262' and mseg.ReversedMaterialDocument is not initial ) )
    and mkpf.CreatedByUser not like 'CC%' and _WOTYPE.aufart is null
    
