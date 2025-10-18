@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '工單啟用狀態'
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_DIMENSION, #CDS_MODELING_ASSOCIATION_TARGET, #SQL_DATA_SOURCE, #CDS_MODELING_DATA_SOURCE ]
define root view entity ZZ1_I_POSTATUS
    as select from I_ManufacturingOrderStatus as _Status
    left outer join I_SystemStatusText as _Text on _Status.StatusCode = _Text.SystemStatus and _Text.Language = $session.system_language
{
    
    key _Status.ManufacturingOrder,
    key _Status.StatusCode,
        _Text.SystemStatusShortName,
        _Status.StatusIsActive
        //_Status.StatusIsInactive
} where _Status.StatusIsActive ='X'
