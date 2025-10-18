@AccessControl.authorizationCheck: #NOT_REQUIRED
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_DIMENSION, #CDS_MODELING_ASSOCIATION_TARGET, #SQL_DATA_SOURCE, #CDS_MODELING_DATA_SOURCE ]
@EndUserText.label: '拆解工單類型維護'
define root view entity ZZ1_I_WOTYPE
  as select from zz1_wotype
{
  key aufart,
      @Semantics.user.createdBy: true
      ernam,
      @Semantics.systemDateTime.createdAt: true
      ertmp
}
