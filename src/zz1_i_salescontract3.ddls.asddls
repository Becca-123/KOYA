@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '銷售契約未結明細表-預留單'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZZ1_I_salescontract3 as select from I_ReservationDocumentHeader as head
    left outer join I_ReservationDocumentItem as item on head.Reservation = item.Reservation
{
    key head.Reservation,
    key item.ReservationItem,
    head.GoodsMovementType,
    item.EntryUnit,
    @Semantics.quantity.unitOfMeasure: 'EntryUnit'
    item.ResvnItmRequiredQtyInEntryUnit,
    item.Product
}
