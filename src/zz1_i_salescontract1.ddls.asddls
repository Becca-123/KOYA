@AbapCatalog.viewEnhancementCategory: [#PROJECTION_LIST]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '銷售契約未結明細表-銷售契約'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}

define root view entity ZZ1_I_salescontract1
  as select from    I_SalesContract
    left outer join I_SalesContractItem on I_SalesContract.SalesContract = I_SalesContractItem.SalesContract
    left outer join I_SalesDocumentItem on  I_SalesContractItem.SalesContract     = I_SalesDocumentItem.SalesDocument
                                        and I_SalesContractItem.SalesContractItem = I_SalesDocumentItem.SalesDocumentItem
  //left outer join  I_Customer on I_SalesContract.SoldToParty = I_Customer.Customer
  //association[0..1] to I_ReservationDocumentItemTP as _test on I_SalesContract.SalesContract = _test.YY1_CN_RDI_RES
  //association[0..1] to I_Customer as _test2 on I_SalesContract.SoldToParty = _test2.Customer
{
  key I_SalesContract.SalesContract,   
  key I_SalesContractItem.SalesContractItem,
      I_SalesContract.PurchaseOrderByCustomer,
      I_SalesContract.SalesContractDate,
      I_SalesContract.SoldToParty,
      I_SalesContractItem.Product,
      I_SalesContractItem.SalesContractItemText,
      I_SalesContractItem.Plant,
      I_SalesDocumentItem .YY1_STAGING_PLANT1_SDI,
      I_SalesContractItem.OrderQuantityUnit,
      @Semantics.quantity.unitOfMeasure: 'OrderQuantityUnit'
      I_SalesContractItem.TargetQuantity as OrderQuantity,
      I_SalesContract.CreatedByUser,
      I_SalesContract.CreationDate
      //_test,
      //_test2
      //    I_Customer.AddressSearchTerm2
}
