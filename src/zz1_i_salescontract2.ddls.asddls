@EndUserText.label: '存貨進銷存表'
@ObjectModel.query.implementedBy: 'ABAP:ZZ1_CL_SALESCONTRACT'

@UI: { headerInfo: { typeName: '銷售契約未結明細表',
                                typeNamePlural: '銷售契約未結明細表' } }
//define root view entity ZZ1_I_salescontract2 as select from I_ReservationDocumentHeader 
define custom entity ZZ1_I_salescontract2
//    with parameters
////        @Consumption.valueHelpDefinition: [ { entity: { name: 'I_FiscalYearPeriod', element: 'FiscalPeriod' } } ]
//        @EndUserText.label: '契約編號-起'
//        s_cotra_low : vbeln,
////        @Consumption.valueHelpDefinition: [ { entity: { name: 'I_FiscalYearPeriod', element: 'FiscalPeriod' } } ]
//        @EndUserText.label: '契約編號-迄'
//        s_contra_high : vbeln    
{
    @UI : { lineItem : [{ position: 10}],
        selectionField : [{ position: 10 }] }
    @EndUserText.label : '契約號碼'
    key SalesContract : abap.char(10);
    @UI : { lineItem : [{ position: 70}],
    selectionField : [{ position: 70 }] }
    @Consumption.valueHelpDefinition: [ { entity: { name: 'I_ProductStdVH', element: 'Product' } } ]
    @EndUserText.label : '產品編號'      
    key Product : abap.char(40);
    @UI : { lineItem : [{ position: 60}] }
    @EndUserText.label : '契約項目'    
    key SalesContractItem:abap.char(6) ;
    @UI : { lineItem : [{ position: 110}],
    selectionField : [{ position: 110 }] }
    @EndUserText.label : '預留單'      
    key Reservation : abap.char(10);
    @UI : { lineItem : [{ position: 120}] }
    @EndUserText.label : '預留單項次'      
    key ReservationItem : abap.char(6);   
    @UI : { lineItem : [{ position: 150}],
    selectionField : [{ position: 150 }] }
    @EndUserText.label : '請購單'      
    key PurchaseRequisition : abap.char(10);
    @UI : { lineItem : [{ position: 160}] }
    @EndUserText.label : '請購項次'      
    key PurchaseRequisitionItem : abap.char(6);     
    @UI : { lineItem : [{ position: 20}],
    selectionField : [{ position: 20 }] }
    @EndUserText.label : '客戶參考'      
    PurchaseOrderByCustomer :abap.char(40);
    @UI : { lineItem : [{ position: 30}],
    selectionField : [{ position: 30 }] }
    @Semantics.businessDate.at: true
    @EndUserText.label : '文件日期'      
    SalesContractDate : abap.dats(8);
    @UI : { lineItem : [{ position: 40}],
    selectionField : [{ position: 40 }]}
    @Consumption.valueHelpDefinition: [ { entity: { name: 'I_CUSTOMER_VH', element: 'CUSTOMER' } }] 
    @EndUserText.label : '客戶編號'      
    SoldToParty : abap.char(10);
    @UI : { lineItem : [{ position: 50}],
    selectionField : [{ position: 50 }] }
    @EndUserText.label : '客戶簡稱'      
    name : abap.char(20);

    @UI : { lineItem : [{ position: 80}],
    selectionField : [{ position: 80 }] }
    @EndUserText.label : '品名'      
    SalesContractItemText : abap.char(40);
    
    @UI : { lineItem : [{ position: 81}],
    selectionField : [{ position: 81 }] }
    //@Consumption.valueHelpDefinition: [ { entity: { name: 'I_PLANTStdVH', element: 'PLANT' } }] 
    @EndUserText.label : '備料工廠'      
    YY1_STAGING_PLANT1_SDI : abap.char(20);
    
    @UI : { lineItem : [{ position: 90}],
    selectionField : [{ position: 90 }] }
    @Consumption.valueHelpDefinition: [ { entity: { name: 'I_PLANTStdVH', element: 'PLANT' } }] 
    @EndUserText.label : '工廠'      
    Plant : abap.char(4);     
    OrderQuantityUnit : abap.unit(3);
    @UI : { lineItem : [{ position: 100}] }
    @EndUserText.label : '契約數量'      
    @Semantics.quantity.unitOfMeasure: 'OrderQuantityUnit'
    OrderQuantity : abap.quan(13,0);
    @UI : { lineItem : [{ position: 130}],
    selectionField : [{ position: 130 }] }
    @EndUserText.label : '異動類型'      
    GoodsMovementType : abap.char(5);
    @UI : { lineItem : [{ position: 140}]}
    @EndUserText.label : '預留單數量'      
    @Semantics.quantity.unitOfMeasure: 'OrderQuantityUnit'
    ResvnItmRequiredQtyInEntryUnit : abap.quan(13,0);
    @UI : { lineItem : [{ position: 170}] }
    @EndUserText.label : '請購數量'      
    @Semantics.quantity.unitOfMeasure: 'OrderQuantityUnit'
    OrderedQuantity : abap.quan(13,0);
    @UI : { lineItem : [{ position: 180}] }
    @EndUserText.label : '未出數量'      
    @Semantics.quantity.unitOfMeasure: 'OrderQuantityUnit'
    UnreleasedQuantity : abap.quan(13,0);
    @UI : { lineItem : [{ position: 190}] }
    @EndUserText.label : '已出數量'      
    @Semantics.quantity.unitOfMeasure: 'OrderQuantityUnit'
    releasedQuantity : abap.quan(13,0);
    @UI : { lineItem : [{ position: 200}],
    selectionField : [{ position: 200 }] }
    @Consumption.valueHelpDefinition: [ { entity: { name: 'I_USER', element: 'UserID' } }] 
    @EndUserText.label : '契約建立者'      
    CreatedByUser : abap.char(10);
    @UI : { lineItem : [{ position: 210}],
    selectionField : [{ position: 210 }] }
    @Semantics.businessDate.at: true
    @EndUserText.label : '契約建立日期'      
    CreationDate : abap.dats(8);
}


