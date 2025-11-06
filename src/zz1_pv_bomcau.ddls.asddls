@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'BOM上傳與更新 Projection View'
@Metadata.ignorePropagatedAnnotations: true
@UI: {
     headerInfo: {
                typeName: 'BOM上傳與更新',
                typeNamePlural: 'BOM上傳與更新'
     }
}
define root view entity ZZ1_PV_BOMCAU as projection on ZZ1_I_BOMCAU
{
    
  key bomcau_uuid,
      
      @UI: {
             lineItem: [{ position:10    }]      
      }
      @EndUserText.label: '工廠'     
      plant,
      
      @UI: {
             lineItem: [{ position:20   }]      
      }
      @EndUserText.label: 'BOM表頭料號'     
      material,
      
      @UI: {
             lineItem: [{ position:30  }]      
      }
      @EndUserText.label: 'BOM用途'     
      billofmaterialvariantusage,
      
      @UI.hidden: true
      @EndUserText.label: 'BOM狀態'     
      billofmaterialstatus,
      
      @UI: {
             lineItem: [{ position:40   }]      
      }
      @EndUserText.label: '替代BOM'     
      billofmaterialvariant,
      
      @UI: {
             lineItem: [{ position:50   }]      
      }
      @EndUserText.label: '生效日期'     
      validitystartdate,
      
      @UI.hidden: true
      @EndUserText.label: '基礎數量'   
      bomheaderquantityinbaseunit,

      @UI.hidden: true
      @EndUserText.label: '項目'   
      billofmaterialitemnumber,
      
      @UI.hidden: true
      @EndUserText.label: '項目種類'   
      billofmaterialitemcategory,
      
      @UI.hidden: true
      @EndUserText.label: '元件編號'   
      billofmaterialcomponent,
      
      @UI.hidden: true
      @EndUserText.label: '元件內文'   
      bomitemdescription,
      
      @UI.hidden: true
      @EndUserText.label: '元件數量'   
      billofmaterialitemquantity,
      
      @UI.hidden: true
      @EndUserText.label: '發料單位'   
      billofmaterialitemunit,
      
      @UI.hidden: true
      @EndUserText.label: '元件儲存位置'   
      prodorderissuelocation,
      
      @UI.hidden: true
      @EndUserText.label: '替代項目：群組'   
      alternativeitemgroup,
      
      @UI.hidden: true
      @EndUserText.label: '替代項目：等級順序'   
      alternativeitempriority,
      
      @UI.hidden: true
      @EndUserText.label: '替代項目：策略'   
      alternativeitemstrategy,
      
      @UI.hidden: true
      @EndUserText.label: '使用機率'   
      usageprobabilitypercent,
      
      @UI.hidden: true
      @EndUserText.label: '固定數量'   
      fixedquantity,
      
      @UI.hidden: true
      @EndUserText.label: '子項目順序'   
      bomsubitemnumbervalue,
      
      @UI.hidden: true
      @EndUserText.label: '安裝點'   
      bomsubiteminstallationpoint,
      
      @UI.hidden: true
      @EndUserText.label: '子項目數量'   
      billofmaterialsubitemquantity,
      
      @UI.hidden: true
      @EndUserText.label: '子項目內文'   
      billofmaterialsubitemtext,
      
      @UI: {
             lineItem: [{ position:60   }]      
      }
      @EndUserText.label: '上傳人員'    
      insert_user,
      
      @UI: {
             lineItem: [{ position:70   }]      
      }
      @EndUserText.label: '上傳日期'    
      insert_date,  
         
      @UI: {
             lineItem: [{ position:80   }]      
      }
      @EndUserText.label: '上傳時間'          
      insert_time,
      
      @UI: {
             lineItem: [{ position:90   }]      
      }
      @EndUserText.label: '上傳狀態'    
      status,
      
      @UI: {
             lineItem: [{ position:100   }]      
      }
      @EndUserText.label: '訊息'     
      msg
      

      

}
