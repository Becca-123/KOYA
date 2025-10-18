@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: '拆解工單類型維護 Projection View'
@Search.searchable: true
@Metadata.ignorePropagatedAnnotations: true
@UI: {
     headerInfo: {
                typeName: '拆解工單類型維護',
                typeNamePlural: '拆解工單類型維護'
     }
}
define root view entity ZZ1_PV_WOTYPE as projection on ZZ1_I_WOTYPE
{
    
          @UI.facet: [
                     { id:            'ALL',
                       purpose:         #STANDARD,
                       type:            #COLLECTION,
                       label:           '資料',
                       position:        10
                     },
                     { type: #FIELDGROUP_REFERENCE ,
                       label : '資料',
                       targetQualifier: 'Date' ,
                       parentId: 'ALL',
                       id: 'Date' ,
                       position: 10
                      }
                  ]
                    
      @UI: {
               lineItem: [{ position: 10, importance: #HIGH }],
               fieldGroup: [{ qualifier: 'Date', position: 10 }],
               selectionField: [{ position: 10 }]
             }
      @EndUserText.label: '工單類型'
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [ { entity: { name: 'I_OrderTypeVH', element: 'OrderType' } } ]
  key aufart,
      @UI: {
        lineItem: [{ position: 20, importance: #HIGH }],
        fieldGroup: [{ qualifier: 'Date', position: 20 }],
        selectionField: [{ position: 20 }]
      }
      @EndUserText.label: '建立者'
      @Semantics.user.createdBy: true
      ernam,
      @UI: {
        lineItem: [{ position: 30, importance: #HIGH }],
        fieldGroup: [{ qualifier: 'Date', position: 30 }],
        selectionField: [{ position: 30 }]
      }
      @EndUserText.label: '建立日期'
      @Semantics.systemDateTime.createdAt: true
      ertmp
}
