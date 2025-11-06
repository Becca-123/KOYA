@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'BOM上傳與更新'
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_DIMENSION, #CDS_MODELING_ASSOCIATION_TARGET, #SQL_DATA_SOURCE, #CDS_MODELING_DATA_SOURCE ]
define root view entity ZZ1_I_BOMCAU as select from zz1_bomcau
{   
    key bomcau_uuid,
        billofmaterial,
        material,
        plant,
        billofmaterialvariantusage,
        billofmaterialstatus,
        billofmaterialvariant,
        validitystartdate,
        bomheaderquantityinbaseunit,
        bomheaderbaseunit,
        billofmaterialitemnumber,
        billofmaterialitemcategory,
        billofmaterialcomponent,
        bomitemdescription,
        billofmaterialitemquantity,
        billofmaterialitemunit,
        prodorderissuelocation,
        alternativeitemgroup,
        alternativeitempriority,
        alternativeitemstrategy,
        usageprobabilitypercent,
        fixedquantity,
        bomsubitemnumbervalue,
        bomsubiteminstallationpoint,
        billofmaterialsubitemquantity,
        billofmaterialsubitemtext,
        status,
        msg,
        insert_date,
        insert_time,
        insert_user
}
