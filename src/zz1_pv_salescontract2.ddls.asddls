@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '匯出供應商發票_匯入'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZZ1_PV_SALESCONTRACT2 
    as select from  I_ReservationDocumentHeader

{
    key Reservation
 
}
