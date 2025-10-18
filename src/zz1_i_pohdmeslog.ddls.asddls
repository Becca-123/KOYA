@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'MES工單拋轉LOG'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZZ1_I_POHDMESLOG as select from zz1_pomes_log
{
    key api_type,
    key objectid,
    key serial_no,
        aufnr,
        auart,
        matnr,
        qty,
        aufnr_status,
        aufnr_up,
        aufnr_main,
        matnr_main,
        charg,
        data_status,
        wo_pick_type,
        reservation,
        reservation_item,
        item_part_no,
        item_group,
        item_group_index,
        warehouse_no,
        factory,
        movetype,
        type, 
        delfalg,  
        ernam,
        erdat,
        erfzeit,
        status,
        message
}
