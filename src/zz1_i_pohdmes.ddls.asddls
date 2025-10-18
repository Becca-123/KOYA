@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '工單MES拋轉作業'
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_DIMENSION, #CDS_MODELING_ASSOCIATION_TARGET, #SQL_DATA_SOURCE, #CDS_MODELING_DATA_SOURCE ]
@ObjectModel.semanticKey: ['ManufacturingOrder']
define root view entity ZZ1_I_POHDMES
    as select from I_ManufacturingOrder as _ManufacturingOrder
    left outer join I_ManufacturingOrder as SuperiorOrder on _ManufacturingOrder.ManufacturingOrder = SuperiorOrder.ManufacturingOrder
    left outer join ZZ1_I_POSTATUS as crtd on _ManufacturingOrder.ManufacturingOrder = crtd.ManufacturingOrder and crtd.SystemStatusShortName = 'CRTD'
    left outer join ZZ1_I_POSTATUS as lkd on _ManufacturingOrder.ManufacturingOrder = lkd.ManufacturingOrder and lkd.SystemStatusShortName = 'LKD'
    left outer join ZZ1_I_POSTATUS as rel on _ManufacturingOrder.ManufacturingOrder = rel.ManufacturingOrder and rel.SystemStatusShortName = 'REL'
    left outer join ZZ1_I_POSTATUS as teco on _ManufacturingOrder.ManufacturingOrder = teco.ManufacturingOrder and teco.SystemStatusShortName = 'TECO'
    left outer join ZZ1_I_POSTATUS as clsd on _ManufacturingOrder.ManufacturingOrder = clsd.ManufacturingOrder and clsd.SystemStatusShortName = 'CLSD'
    left outer join ZZ1_I_POSTATUS as dlfl on _ManufacturingOrder.ManufacturingOrder = dlfl.ManufacturingOrder and dlfl.SystemStatusShortName = 'DLFL'
    left outer join I_ProductText as makt on _ManufacturingOrder.Material = makt.Product and makt.Language = $session.system_language
    
    association[0..1] to ZZ1_I_WOTYPE as _WOTYPE on _ManufacturingOrder.ManufacturingOrderType = _WOTYPE.aufart
    
//    association [0..1] to ZZ1_I_POSTATUS as crtd on _ManufacturingOrder.ManufacturingOrder = crtd.ManufacturingOrder and crtd.SystemStatusShortName = 'CRTD'
//    association [0..1] to ZZ1_I_POSTATUS as lkd on _ManufacturingOrder.ManufacturingOrder = lkd.ManufacturingOrder and lkd.SystemStatusShortName = 'LKD'
//    association [0..1] to ZZ1_I_POSTATUS as rel on _ManufacturingOrder.ManufacturingOrder = rel.ManufacturingOrder and rel.SystemStatusShortName = 'REL'
//    association [0..1] to ZZ1_I_POSTATUS as teco on _ManufacturingOrder.ManufacturingOrder = teco.ManufacturingOrder and teco.SystemStatusShortName = 'TECO'
//    association [0..1] to ZZ1_I_POSTATUS as clsd on _ManufacturingOrder.ManufacturingOrder = clsd.ManufacturingOrder and clsd.SystemStatusShortName = 'CLSD'
//    association [0..1] to ZZ1_I_POSTATUS as dlfl on _ManufacturingOrder.ManufacturingOrder = dlfl.ManufacturingOrder and dlfl.SystemStatusShortName = 'DLFL'
{
    key _ManufacturingOrder.ManufacturingOrder,
        _ManufacturingOrder.ProductionPlant,
        _ManufacturingOrder.ManufacturingOrderType,
        _ManufacturingOrder.Material,
        @Semantics.quantity.unitOfMeasure: 'ProductionUnit'
        _ManufacturingOrder.MfgOrderPlannedTotalQty, //工單表頭總數量
        _ManufacturingOrder.ProductionUnit,
        _ManufacturingOrder.MfgOrderPlannedStartDate,
        _ManufacturingOrder.MfgOrderPlannedEndDate,
        makt.ProductName,
        case 
            when dlfl.StatusIsActive = 'X'
                then '7'
            when clsd.StatusIsActive = 'X'
                then '6'
            when teco.StatusIsActive = 'X'
                then '6'
            when lkd.StatusIsActive = 'X'
                then '4'
            when rel.StatusIsActive = 'X'
                then '2'
            when crtd.StatusIsActive = 'X'
                then '0'
        end as wo_status,  //工單表頭狀態：(CRTD=0 LKD=4 REL=2 TECO/CLSD=6 DLFL=7
        _ManufacturingOrder.LeadingOrder, //工單表頭紀錄上階工單
        _ManufacturingOrder.SuperiorOrder, //工單表頭紀錄母工單
        SuperiorOrder.Material as wo_option7, //工單表頭紀錄母工單生產物料編號
        _ManufacturingOrder.YY1_PO_CHARG_ORD, //工單批次號碼
        case 
            when _ManufacturingOrder.YY1_MES_PO_ORD is initial
                then '1'
            when dlfl.StatusIsActive = 'X'
                then '3'
            when ( _ManufacturingOrder.YY1_MES_PO_ORD = 'X' and dlfl.StatusIsActive is initial )
                then '2'
        end as Data_Status, //工單第一次傳MES=1 第二次起傳輸=2 工單狀態為DLFL=3 
        
        _ManufacturingOrder.YY1_MES_STATUS_ORD,   //MES拋轉狀態              
        _ManufacturingOrder.YY1_MES_PO_ORD, //已拋轉過MES
        _ManufacturingOrder.YY1_MATERIAL_DELIVERY_ORD,
        cast( '' as abap.char( 1 ) ) as sendvalue,
        cast( '' as abap.char( 1 ) ) as MaterialConfirmation
       
        
} where ( ( clsd.StatusIsActive = 'X' or lkd.StatusIsActive = 'X' or rel.StatusIsActive = 'X' ) or
          ( _ManufacturingOrder.YY1_MES_PO_ORD = 'X' and ( dlfl.StatusIsActive = 'X' or  teco.StatusIsActive = 'X' ) ) //若是沒有拋過但是已上TECO跟DLFL的也不顯示
         ) and _WOTYPE.aufart is null
