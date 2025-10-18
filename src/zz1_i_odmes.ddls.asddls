@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '出貨通知單拋轉MES'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZZ1_I_ODMES   
    as select from    I_DeliveryDocument      as _OutboundDelivery
    join              I_DeliveryDocumentItem  as _OutboundDeliveryItem on _OutboundDeliveryItem.DeliveryDocument = _OutboundDelivery.DeliveryDocument
    left outer join   I_SDDocumentPartner as vbpa on _OutboundDelivery.DeliveryDocument = vbpa.SDDocument and vbpa.PartnerFunction = 'WE'
    left outer join   ZZ1_I_ADDRESS_2     as adrc on vbpa.AddressID = adrc.AddressID

{
  key _OutboundDelivery.DeliveryDocument as DN_NO,                      //DN单号码
  key _OutboundDeliveryItem.DeliveryDocumentItem as DN_ITEM,            //DN项次
      _OutboundDelivery.ShipToParty as CUSTOMER_ID,                     //客户代码(收貨方)
      adrc.StreetName as SHIP_TO,                                       // 运送地点
      _OutboundDelivery.DeliveryDate,                                   //交货日期
      _OutboundDelivery.IncotermsClassification as incoterms,                        //贸易条款(國貿條件)
      //FACTORY_NAME 厂别
      _OutboundDelivery.SalesOrganization as Compnay_Code,              //销售公司别            
      _OutboundDeliveryItem.Product as PART_NO,                         //料号
      @Semantics.quantity.unitOfMeasure: 'DeliveryQuantityUnit'
      _OutboundDeliveryItem.ActualDeliveryQuantity as QTY,              //料号数量
      _OutboundDeliveryItem.DeliveryQuantityUnit,
      _OutboundDeliveryItem.DeliveryDocumentItemText as DESCRIPTION,    //描述  可选
      _OutboundDeliveryItem.Warehouse as WH_NO,                         //出貨仓库编码
      _OutboundDeliveryItem.Plant as FACTORY_NAME,                      //出貨厂别
      _OutboundDeliveryItem.GoodsMovementType as MoveType,              //DN单 MVT
      _OutboundDeliveryItem.PurchaseOrder as PO,                        //客戶參考
      
      _OutboundDelivery.SDDocumentCategory,
      _OutboundDelivery.OverallGoodsMovementStatus,  //物料異動狀態
      _OutboundDelivery.CreationDate,
      _OutboundDelivery.YY1_ODMES_STATUS_DLH
      
     
}
where _OutboundDelivery.YY1_ODMES_STATUS_DLH = 'X' and _OutboundDelivery.OverallGoodsMovementStatus <> 'C'
