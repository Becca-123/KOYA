@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'SAP Screen Personas取得工單資料'
define root view entity ZZ1_I_MANUFACTURINGORDER 
    as select from I_ManufacturingOrder as _ManufacturingOrder
    left outer join I_ManufacturingOrder as SuperiorOrder on _ManufacturingOrder.ManufacturingOrder = SuperiorOrder.ManufacturingOrder
    left outer join ZZ1_I_POSTATUS as rel on _ManufacturingOrder.ManufacturingOrder = rel.ManufacturingOrder and rel.SystemStatusShortName = 'REL'
{
    
    key _ManufacturingOrder.ManufacturingOrder,
        _ManufacturingOrder.ProductionPlant,
        _ManufacturingOrder.ManufacturingOrderType,
        _ManufacturingOrder.Material,
        rel.StatusIsActive,
        _ManufacturingOrder.LeadingOrder, //工單表頭紀錄上階工單
        _ManufacturingOrder.SuperiorOrder //工單表頭紀錄母工單
} where ( _ManufacturingOrder.LeadingOrder is not initial or _ManufacturingOrder.SuperiorOrder is not initial )
    and _ManufacturingOrder.ManufacturingOrder <> _ManufacturingOrder.LeadingOrder
