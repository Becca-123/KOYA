@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '拆解工單入庫拋轉MES'
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_DIMENSION, #CDS_MODELING_ASSOCIATION_TARGET, #SQL_DATA_SOURCE, #CDS_MODELING_DATA_SOURCE ]
define root view entity ZZ1_I_WODINSTOCK
    as select from I_ManufacturingOrder as _ManufacturingOrder
    join I_MfgOrderOperationComponent as _MfgOrderOperationComponent on _ManufacturingOrder.ManufacturingOrder = _MfgOrderOperationComponent.ManufacturingOrder 
    join I_MaterialDocumentItem_2 as mseg on mseg.ManufacturingOrder = _ManufacturingOrder.ManufacturingOrder and _MfgOrderOperationComponent.Reservation = mseg.Reservation 
                                            and mseg.ReservationItem = _MfgOrderOperationComponent.ReservationItem
    join I_MaterialDocumentHeader_2 as mkpf on mseg.MaterialDocument = mkpf.MaterialDocument and mseg.MaterialDocumentYear = mkpf.MaterialDocumentYear
    //left outer join I_ProductSupplyPlanning as _ProductSupplyPlanning on _ManufacturingOrder.Material = _ProductSupplyPlanning.Product and _ManufacturingOrder.ProductionPlant = _ProductSupplyPlanning.Plant
    join ZZ1_I_WOTYPE as _WOTYPE on _ManufacturingOrder.ManufacturingOrderType = _WOTYPE.aufart
{
    
    key _ManufacturingOrder.ManufacturingOrder as WORK_ORDER, 
    key _MfgOrderOperationComponent.BillOfMaterialItemNumber as Item,
    key _MfgOrderOperationComponent.Reservation as Reservation, 
    key _MfgOrderOperationComponent.ReservationItem as ReservationItem, 
    key mseg.MaterialDocumentYear,
    key mseg.MaterialDocument,
    key mseg.MaterialDocumentItem,
    _ManufacturingOrder.Material as PART_NO,
    _ManufacturingOrder.ManufacturingOrderType as WOType,
    _ManufacturingOrder.ProductionPlant as FACTORY_NAME,
    //_ProductSupplyPlanning.DfltStorageLocationExtProcmt as WAREHOUSE_NO,
    mseg.StorageLocation as WAREHOUSE_NO,
    _MfgOrderOperationComponent.Material as ITEM_PART_NO,
    @Semantics.quantity.unitOfMeasure: 'UNIT'
    mseg.QuantityInEntryUnit as QTY,
    mseg.EntryUnit as UNIT,
    mseg.Plant as FACTORY_NAME_IT,
    mseg.GoodsMovementType as MoveType,

    cast( 
      case
        when mseg.GoodsMovementType = '261'
        then '3'
        else '1'
    end  as abap.char(1) ) as Data_Status,
    
    mseg.PostingDate,
    mkpf.CreatedByUser
} where ( ( mseg.GoodsMovementType = '261' and mseg.ReversedMaterialDocument is not initial )
    or ( mseg.GoodsMovementType = '262' and mseg.ReversedMaterialDocument is initial ) )
    and mkpf.CreatedByUser not like 'CC%'
