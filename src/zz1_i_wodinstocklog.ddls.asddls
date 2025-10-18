@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '拆解工單入庫拋轉MES LOG'
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_DIMENSION, #CDS_MODELING_ASSOCIATION_TARGET, #SQL_DATA_SOURCE, #CDS_MODELING_DATA_SOURCE ]
define root view entity ZZ1_I_WODINSTOCKLOG as select from zz1_wodins_log
{
    
      key objectid,
      key serial_no,
      work_order,
      part_no,
      wotype,
      factory_name,
      item,
      warehouse_no,
      item_part_no,
      qty,
      unit,
      factory_name_it,
      movetype,
      reservation,
      reservation_item,
      data_status,
      postingdate,
      materialdocumentyear,
      materialdocument,
      materialdocumentitem,
      task_no,
      type,
      code,
      ernam,
      erdat,
      erfzeit,
      status,
      message
}
