@EndUserText.label: '工作類型VH'
@ObjectModel.representativeKey: 'worktype'
@ObjectModel.usageType.dataClass: #META
@ObjectModel.usageType.serviceQuality: #A
@ObjectModel.usageType.sizeCategory: #S
@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.dataCategory: #VALUE_HELP
@ObjectModel.modelingPattern:         #ANALYTICAL_DIMENSION
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_DIMENSION,
                                      #CDS_MODELING_DATA_SOURCE,
                                      #CDS_MODELING_ASSOCIATION_TARGET,
                                      #SEARCHABLE_ENTITY,
                                      #SQL_DATA_SOURCE,
                                      #VALUE_HELP_PROVIDER ]
@Analytics.dataCategory: #DIMENSION
@VDM.viewType: #BASIC
@AccessControl.authorizationCheck:  #NOT_REQUIRED
@AbapCatalog: {
  sqlViewName: 'ZZ1WORKTYPEVH',
  preserveKey: true
}
@Search.searchable: true
@Consumption.ranked: true
@Metadata.ignorePropagatedAnnotations: true

define view ZZ1_I_WORKTYPEVH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE_T( p_domain_name: 'ZZ1_WORKTYPE')
{   
      @ObjectModel.text.element: ['worktypetext']  
  key cast(substring( DDCDS_CUSTOMER_DOMAIN_VALUE_T.value_low, 1, 1) as zz1_worktype  preserving type) as worktype,
      @Semantics.text: true
      text as worktypetext
}

where
  language = 'E'
