@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '拆解工單入庫拋轉MES LOG Projection View'
@Search.searchable: true
@Metadata.ignorePropagatedAnnotations: true
@UI: {
     headerInfo: {
                typeName: 'MES拆解入庫拋轉LOG',
                typeNamePlural: 'MES拆解入庫拋轉LOG'
     }
}
define root view entity ZZ1_PV_WODINSTOCKLOG as projection on ZZ1_I_WODINSTOCKLOG
{
    
      @UI.facet: [
                     { id:            'ALL',
                       purpose:         #STANDARD,
                       type:            #COLLECTION,
                       label:           '資料',
                       position:        10
                     }
                  ]
                    
      @UI: {
               lineItem: [{ position: 10, importance: #HIGH }]
           }
      @EndUserText.label: '物件值'
  key objectid,
  
      @UI: {
               lineItem: [{ position: 20, importance: #HIGH }]
            }
      @EndUserText.label: '序號'
  key serial_no,  
    
      @UI: {
               lineItem: [{ position: 30, importance: #HIGH }],
               selectionField: [{ position: 30 }]
             }
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_ProductionOrderStdVH', element: 'ProductionOrder' } } ]
      @EndUserText.label: '工單號碼'
      @Search.defaultSearchElement: true
      work_order,
  
      @UI: {
        lineItem: [{ position: 40, importance: #HIGH }],
        selectionField: [{ position: 40 }]
      }
      @EndUserText.label: '成品料號'
      part_no,
      
      @UI: {
        lineItem: [{ position: 50, importance: #HIGH }],
        selectionField: [{ position: 50 }]
      }
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_OrderTypeVH', element: 'OrderType' } } ]
      @EndUserText.label: '工單類型'
      wotype,
      
      @UI: {
        lineItem: [{ position: 60, importance: #HIGH }],
        selectionField: [{ position: 60 }]
      }
      @EndUserText.label: '工廠別'
      factory_name,
      
      @UI: {
        lineItem: [{ position: 70, importance: #HIGH }]
      }
      @EndUserText.label: '工單項次'
      item,
      
      @UI: {
        lineItem: [{ position: 80, importance: #HIGH }],
        selectionField: [{ position: 80 }]
      }
      @EndUserText.label: '倉庫號碼'
      warehouse_no,
      
      @UI: {
        lineItem: [{ position: 90, importance: #HIGH }],
        selectionField: [{ position: 90 }]
      }
      @EndUserText.label: '料件號碼'
      item_part_no,
      
      @UI: {
        lineItem: [{ position: 100, importance: #HIGH }]
      }
      @EndUserText.label: '入庫數量'
      qty,
      
      @UI: {
        lineItem: [{ position: 110, importance: #HIGH }],
        selectionField: [{ position: 110 }]
      }
      @EndUserText.label: '單位'
      unit,
      
      @UI: {
        lineItem: [{ position: 120, importance: #HIGH }]
      }
      @EndUserText.label: '工廠(項次)'
      factory_name_it,
      
      @UI: {
        lineItem: [{ position: 130, importance: #HIGH }]
      }
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_GoodsMovementTypeT', element: 'GoodsMovementType' } } ]    
      @EndUserText.label: '異動類型'
      movetype,
      
      @UI: {
        lineItem: [{ position: 140, importance: #HIGH }],
        selectionField: [{ position: 140 }]
      }
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_User', element: 'UserID' } } ]    
      @EndUserText.label: '建立者'
      ernam,
      
      @UI: {
        lineItem: [{ position: 150, importance: #HIGH }],
        selectionField: [{ position: 150 }]
      }
      @EndUserText.label: '建立日期'
      erdat,
      
      @UI: {
        lineItem: [{ position: 160, importance: #HIGH }]
      }
      @EndUserText.label: '建立時間'
      erfzeit,
      
      @UI: {
        lineItem: [{ position: 170, importance: #HIGH }],
        selectionField: [{ position: 170 }]
      }
      @EndUserText.label: '拋轉狀態'
      status,
      
      @UI: {
        lineItem: [{ position: 180, importance: #HIGH }],
        selectionField: [{ position: 180 }]
      }
      @EndUserText.label: '訊息'
      message
}
