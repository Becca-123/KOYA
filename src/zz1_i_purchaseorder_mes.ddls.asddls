@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '採購單拋轉MES'
@ObjectModel.supportedCapabilities: [ #ANALYTICAL_DIMENSION, #CDS_MODELING_ASSOCIATION_TARGET, #SQL_DATA_SOURCE, #CDS_MODELING_DATA_SOURCE ]
define root view entity ZZ1_I_PURCHASEORDER_MES 
    as select from I_PurchaseOrderAPI01 as _PurchaseOrderAPI01
    join  I_PurchaseOrderItemAPI01 as _PurchaseOrderItemAPI01 on _PurchaseOrderItemAPI01.PurchaseOrder = _PurchaseOrderAPI01.PurchaseOrder
    left outer join I_POSubcontractingCompAPI01 as _POSubcontractingCompAPI01 on  _POSubcontractingCompAPI01.PurchaseOrder = _PurchaseOrderAPI01.PurchaseOrder 
                                                                              and _POSubcontractingCompAPI01.PurchaseOrderItem = _PurchaseOrderItemAPI01.PurchaseOrderItem
                                                                              
    left outer join I_User as _User on  _PurchaseOrderAPI01.CreatedByUser = _User.UserID
    association [1..1] to I_PurchasingGroup  as _PurchasingGroup on  _PurchaseOrderAPI01.PurchasingGroup     = _PurchasingGroup.PurchasingGroup
    association [1..1] to ZZ1_I_AddressEmailAddress_2 as _Address on _Address.AddressPersonID = _User.AddressPersonID and _Address.AddressID = _User.AddressID 
                                                                 and _Address.CommMediumSequenceNumber = '001'
{
    
    key _PurchaseOrderAPI01.PurchaseOrder as PO,
    key _PurchaseOrderItemAPI01.PurchaseOrderItem as Item,
    key _POSubcontractingCompAPI01.PurchaseOrderScheduleLine,
    key _POSubcontractingCompAPI01.ReservationItem,
    key _POSubcontractingCompAPI01.RecordType,
    //head
    _PurchaseOrderAPI01.PurchasingGroup as Purchase_group_Code,
    _PurchasingGroup.PurchasingGroupName as Purchase_group_Name,
    _PurchaseOrderAPI01.Supplier as VENDOR_CODE,
    _PurchaseOrderAPI01.PurchaseOrderType as POType,
    _PurchaseOrderAPI01.PurchaseOrderDate as PO_DATE,
    cast( '1' as abap.char( 1 )) as status,
    _Address.EmailAddress as UPDATE_USERID,
    //item
    _PurchaseOrderItemAPI01.Material as PartNO,
    _PurchaseOrderItemAPI01.PurchaseRequisition as PR,
    _PurchaseOrderItemAPI01.PurchaseRequisitionItem as PR_ITEM,
    @Semantics.quantity.unitOfMeasure: 'UNIT'   
    _PurchaseOrderItemAPI01.OrderQuantity as PO_QTY,
    _PurchaseOrderItemAPI01.PurchaseOrderQuantityUnit as UNIT,
    _PurchaseOrderItemAPI01.Plant as FACTORY_NAME,
    _PurchaseOrderItemAPI01.StorageLocation as WAREHOUSE_NO,
    _PurchaseOrderItemAPI01.PurchasingDocumentDeletionCode as del_falg,
    _PurchaseOrderItemAPI01.AccountAssignmentCategory as Account_category,
    _PurchaseOrderItemAPI01.IsReturnsItem,
    _PurchaseOrderItemAPI01.PurchaseOrderItemCategory,
    _POSubcontractingCompAPI01.BillOfMaterialItemNumber,
    _POSubcontractingCompAPI01.Material,
    @Semantics.quantity.unitOfMeasure: 'BaseUnit'
    _POSubcontractingCompAPI01.RequiredQuantity,
    _POSubcontractingCompAPI01.BaseUnit,
    _POSubcontractingCompAPI01.StorageLocation,
    
    _PurchaseOrderAPI01.YY1_CONTRACT_NUMBER_PDH,
    _PurchaseOrderAPI01.YY1_Appoval_PDH

} where _PurchaseOrderAPI01.YY1_PURORDERMES_STATUS_PDH = 'X'
