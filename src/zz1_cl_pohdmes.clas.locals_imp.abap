*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS zz1_cl_pohdmes_lt DEFINITION INHERITING FROM  cl_abap_behavior_handler.
  PUBLIC SECTION.
    DATA:
    BEGIN OF wa_manufacturingorder,
          manufacturingorder            TYPE c LENGTH 12,
          YY1_MES_PO_ORD TYPE I_ManufacturingOrder-YY1_MES_PO_ORD,
          YY1_MES_STATUS_ORD TYPE I_ManufacturingOrder-YY1_MES_STATUS_ORD,
          YY1_PO_CHARG_ORD        TYPE I_ManufacturingOrder-YY1_PO_CHARG_ORD,
          yy1_material_delivery_ord TYPE I_ManufacturingOrder-yy1_material_delivery_ord,
        END OF wa_manufacturingorder.
    METHODS: Update_Aufnr
      IMPORTING wa_manufacturingorder LIKE wa_manufacturingorder.

*    METHODS: getEtag
*      IMPORTING manufacturingorder TYPE I_ManufacturingOrder-manufacturingorder
*      RETURNING VALUE(rv_result) TYPE string.


  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zz1_i_pohdmes RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zz1_i_pohdmes RESULT result.

    METHODS SeandValue FOR MODIFY
      IMPORTING keys FOR ACTION zz1_i_pohdmes~SeandValue CHANGING reported TYPE data.

    METHODS Seand_Value FOR MODIFY
      IMPORTING keys FOR ACTION zz1_i_pohdmes~Seand_Value CHANGING reported TYPE data.

    METHODS MaterialConfirmation FOR MODIFY
      IMPORTING keys FOR ACTION zz1_i_pohdmes~MaterialConfirmation CHANGING reported TYPE data.

    METHODS Material_Confirmation FOR MODIFY
      IMPORTING keys FOR ACTION zz1_i_pohdmes~Material_Confirmation CHANGING reported TYPE data.

    METHODS get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys REQUEST requested_features FOR zz1_i_pohdmes RESULT result.
ENDCLASS.

CLASS zz1_cl_pohdmes_lt IMPLEMENTATION.
    METHOD get_instance_authorizations.

*          LOOP AT keys INTO DATA(key).
*            APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<fs_auth>).
*            IF <fs_auth> IS ASSIGNED.
*                " 預設沒有權限
**                <fs_auth>-%action-MaterialConfirmation = if_abap_behv=>auth-unauthorized.
*
*                " 這裡用 AUTHORITY-CHECK OBJECT (Cloud 只能檢查 Released 的 PFCG object)
*                AUTHORITY-CHECK OBJECT 'ZZ1_MC_AO'
*                  ID 'ACTVT' FIELD '03'.
*
*                IF sy-subrc = 0.
*                  <fs_auth>-%action-MaterialConfirmation = if_abap_behv=>auth-allowed.
*                ENDIF.
*
*                <fs_auth>-%action-MaterialConfirmation = if_abap_behv=>auth-allowed.
*            ENDIF.
*
*
*          ENDLOOP.
    ENDMETHOD.

    METHOD get_global_authorizations.
        IF requested_authorizations-%action IS NOT INITIAL.
        ENDIF.

    ENDMETHOD.

    METHOD Seand_Value.
    ENDMETHOD.

    METHOD Material_Confirmation.
    ENDMETHOD.

    METHOD get_instance_features.
*        LOOP AT keys INTO DATA(key).
*            APPEND INITIAL LINE TO result ASSIGNING FIELD-SYMBOL(<fs_result>).
*
*            IF <fs_result> IS ASSIGNED.
**                IF cl_abap_context_info=>is_user_in_business_role( 'SAP_BR_PRODUCTION_PLANNER' ) = abap_true.
**                  <fs_result>-%features-%action-MaterialConfirmation = if_abap_behv=>fc-o-disabled.
**                ENDIF.
*                <fs_result>-ManufacturingOrder = key-ManufacturingOrder.
*                <fs_result>-%features-%action-MaterialConfirmation = if_abap_behv=>fc-o-disabled.
*                IF <fs_result>-%action-MaterialConfirmation = if_abap_behv=>auth-allowed.
*                    <fs_result>-%features-%action-MaterialConfirmation = if_abap_behv=>fc-o-enabled.
*                ENDIF.
*            ENDIF.
*
*            UNASSIGN <fs_result>.
*
*
**            <fs_result>-key = key-%key.
**
**            " 預設按鈕不可見
**            <fs_result>-MaterialConfirmation-%features-%action-enabled = if_abap_behv=>fc-o-disabled.
**
**            " 檢查是否有權限
**            IF cl_abap_context_info=>is_user_in_business_role( 'SAP_BR_PRODUCTION_PLANNER' ) = abap_true.
**              <fs_result>-MaterialConfirmation-%features-%action-enabled = if_abap_behv=>fc-o-enabled.
**            ENDIF.
*
*          ENDLOOP.

    ENDMETHOD.

    METHOD SeandValue.
        DATA: l_url TYPE string.
        DATA: l_body TYPE string.
        DATA: l_serial_no TYPE zz1_i_pohdmeslog-serial_no,
              lwa_log TYPE STRUCTURE FOR CREATE zz1_i_pohdmeslog,
              lt_log TYPE TABLE FOR CREATE zz1_i_pohdmeslog,
              lwa_pomeslog TYPE zz1_i_pohdmeslog,
              lt_pomeslog TYPE STANDARD TABLE OF zz1_i_pohdmeslog,
              l_error TYPE flag,
              l_first TYPE string,
              l_last TYPE string,
              l_len TYPE i,
              l_change TYPE flag,
              l_del TYPE flag.

        DATA: lwa_mes  TYPE STRUCTURE FOR REPORTED EARLY zz1_i_pohdmes.
        DATA: lwa_result TYPE STRUCTURE FOR READ RESULT zz1_i_pohdmes,
              lt_result TYPE TABLE FOR READ RESULT zz1_i_pohdmes,
              lwa_tmp TYPE zz1_i_pohdmes,
              lt_tmp TYPE STANDARD TABLE OF zz1_i_pohdmes.

        DATA: lr_http_destination TYPE REF TO if_http_destination.
        DATA: lr_web_http_client TYPE REF TO if_web_http_client.
        DATA: lr_request TYPE REF TO if_web_http_request.
        DATA: lr_response TYPE REF TO if_web_http_response.
        DATA: BEGIN OF lwa_body,
                manufacturingorder      TYPE zz1_i_pohdmes-manufacturingorder,
                manufacturingordertype  TYPE zz1_i_pohdmes-manufacturingordertype,
                material                TYPE zz1_i_pohdmes-material,
                mfgorderplannedtotalqty TYPE zz1_i_pohdmes-mfgorderplannedtotalqty,
                YY1_PO_CHARG_ORD        TYPE zz1_i_pohdmes-YY1_PO_CHARG_ORD,
                wo_status               TYPE zz1_i_pohdmes-wo_status,
                LeadingOrder            TYPE zz1_i_pohdmes-LeadingOrder,
                SuperiorOrder           TYPE zz1_i_pohdmes-SuperiorOrder,
                wo_option7              TYPE zz1_i_pohdmes-wo_option7,
                Data_Status             TYPE zz1_i_pohdmes-Data_Status,
              END OF lwa_body.

         DATA: BEGIN OF lwa_Componentmes,
                manufacturingorder   TYPE zz1_i_pohdmes-manufacturingorder,
                material             TYPE zz1_i_pohdmes-material,
                Data_Status          TYPE zz1_i_pohdmes-Data_Status,
                Reservation          TYPE I_MfgOrderOperationComponent-Reservation,
                ReservationItem      TYPE I_MfgOrderOperationComponent-ReservationItem,
                ITEM_PART_NO         TYPE I_MfgOrderOperationComponent-Material,
                AlternativeItemGroup TYPE I_MfgOrderOperationComponent-AlternativeItemGroup,
                ITEM_GROUP_INDEX     TYPE zz1_i_pohdmeslog-item_group_index,
                Issue_QTY            TYPE zz1_i_pohdmeslog-qty,
                warehouse_no         TYPE I_ProductSupplyPlanning-DfltStorageLocationExtProcmt,
                Plant                TYPE I_MfgOrderOperationComponent-Plant,
                MoveType             TYPE zz1_i_pohdmeslog-movetype,
                TYPE                 TYPE zz1_i_pohdmeslog-type,

                AlternativeItemPriority TYPE I_MfgOrderOperationComponent-AlternativeItemPriority,
                RequiredQuantity    TYPE I_MfgOrderOperationComponent-RequiredQuantity, "需求數廖
                WithdrawnQuantity   TYPE I_MfgOrderOperationComponent-WithdrawnQuantity, "領料數量
                MatlCompIsMarkedForDeletion TYPE I_MfgOrderOperationComponent-MatlCompIsMarkedForDeletion, "刪除項目
              END OF lwa_Componentmes,
              lwa_Componentmes2 LIKE lwa_Componentmes,
              lt_Componentmes LIKE STANDARD TABLE OF lwa_Componentmes.

         DATA: BEGIN OF lwa_req,
                WORK_ORDER       TYPE c LENGTH 25,
                PART_NO          TYPE c LENGTH 30,
                ITEM_BOM_ID      TYPE c LENGTH 20,
                wo_pick_type     TYPE c LENGTH 2,
                Reservation      TYPE c LENGTH 30,
                ReservationItem  TYPE c LENGTH 30,
                WAREHOUSE_NO     TYPE c LENGTH 25,
                ITEM_PART_NO     TYPE c LENGTH 30,
                ITEM_GROUP       TYPE c LENGTH 10,
                ITEM_GROUP_INDEX TYPE c LENGTH 2,
                ITEM_COUNT       TYPE c LENGTH 22,
                PROCESS_NAME     TYPE c LENGTH 25,
                VERSION          TYPE c LENGTH 16,
                LOCATION         TYPE c LENGTH 1000,
                Issue_QTY        TYPE c LENGTH 20,
                SATGE_Flag       TYPE c LENGTH 20,
                Virtual_key      TYPE c LENGTH 20,
                BOM_LEVEL        TYPE c LENGTH 20,
                ITEM_NO          TYPE c LENGTH 20,
                RES_NO           TYPE c LENGTH 20,
                FACTORY          TYPE c LENGTH 20,
                MoveType         TYPE c LENGTH 4,
                TYPE             TYPE c LENGTH 4,
                Data_Status      TYPE c LENGTH 1,
              END OF lwa_req.


        DATA: BEGIN OF lwa_manufacturingorder,
                manufacturingorder            TYPE c LENGTH 12,
                YY1_MES_PO_ORD TYPE I_ManufacturingOrder-YY1_MES_PO_ORD,
                YY1_MES_STATUS_ORD TYPE I_ManufacturingOrder-YY1_MES_STATUS_ORD,
                YY1_PO_CHARG_ORD        TYPE I_ManufacturingOrder-YY1_PO_CHARG_ORD,
                yy1_material_delivery_ord TYPE I_ManufacturingOrder-yy1_material_delivery_ord,
              END OF lwa_manufacturingorder.

        DATA: lwa_SuperiorOrder TYPE I_ManufacturingOrder,
              lt_SuperiorOrder TYPE STANDARD TABLE OF I_ManufacturingOrder.

        DATA: BEGIN OF lwa_mc106,
                Product TYPE I_Product-Product,
                CharcValue  TYPE ZZ1_I_ObjectCharacteristics-CharcValue,
              END OF lwa_mc106,
              lt_mc106 LIKE STANDARD TABLE OF lwa_mc106.

        DATA: lcx_root TYPE REF TO cx_root.

        DATA: l_status TYPE  if_abap_behv_message=>t_severity,
              l_text   TYPE string.

        READ ENTITIES OF zz1_i_pohdmes IN LOCAL MODE
          ENTITY zz1_i_pohdmes
          ALL FIELDS WITH CORRESPONDING #( keys )
          RESULT lt_result
          FAILED FINAL(ls_fail).

        CLEAR: lwa_tmp, lt_tmp, lwa_Componentmes, lt_Componentmes, lwa_pomeslog, lt_pomeslog.
        IF lt_result IS NOT INITIAL.
            MOVE-CORRESPONDING lt_result[] TO lt_tmp[].
            SORT lt_tmp BY manufacturingorder.

            SELECT * FROM I_ManufacturingOrder
                FOR ALL ENTRIES IN @lt_tmp
                WHERE ( LeadingOrder = @lt_tmp-manufacturingorder OR SuperiorOrder = @lt_tmp-manufacturingorder )
                INTO CORRESPONDING FIELDS OF TABLE @lt_SuperiorOrder.
            SORT lt_SuperiorOrder BY manufacturingorder.

*            SELECT a~manufacturingorder, c~DfltStorageLocationExtProcmt AS warehouse_no,
*                   b~Reservation, b~ReservationItem, b~Material AS ITEM_PART_NO,
*                   b~AlternativeItemGroup, b~RequiredQuantity, b~WithdrawnQuantity, b~Plant,
*                   b~AlternativeItemPriority, b~MatlCompIsMarkedForDeletion
*                FROM I_ManufacturingOrder AS a
*                JOIN I_MfgOrderOperationComponent AS b ON a~ManufacturingOrder = b~ManufacturingOrder
*                LEFT OUTER JOIN I_ProductSupplyPlanning AS c ON a~Material = c~Product AND a~ProductionPlant = c~Plant
*                FOR ALL ENTRIES IN @lt_tmp
*                WHERE a~manufacturingorder = @lt_tmp-manufacturingorder AND b~GoodsMovementType = '261'
*                INTO CORRESPONDING FIELDS OF TABLE @lt_Componentmes.
*            SORT lt_Componentmes BY manufacturingorder Reservation ReservationItem.

            SELECT a~manufacturingorder, c~DfltStorageLocationExtProcmt AS warehouse_no,
                   b~Reservation, b~ReservationItem, b~Material AS ITEM_PART_NO,
                   b~AlternativeItemGroup, b~RequiredQuantity, b~WithdrawnQuantity, b~Plant,
                   b~AlternativeItemPriority, b~MatlCompIsMarkedForDeletion
                FROM I_ManufacturingOrder AS a
                JOIN I_MfgOrderOperationComponent AS b ON a~ManufacturingOrder = b~ManufacturingOrder
                LEFT OUTER JOIN I_ProductSupplyPlanning AS c ON b~Material = c~Product AND a~ProductionPlant = c~Plant
                FOR ALL ENTRIES IN @lt_tmp
                WHERE a~manufacturingorder = @lt_tmp-manufacturingorder AND b~GoodsMovementType = '261'
                INTO CORRESPONDING FIELDS OF TABLE @lt_Componentmes.
            SORT lt_Componentmes BY manufacturingorder Reservation ReservationItem.
        ENDIF.

        LOOP AT lt_result INTO lwa_result WHERE YY1_MATERIAL_DELIVERY_ORD = 'X'.
            CLEAR: lwa_body, l_error, lwa_manufacturingorder, l_change.

            SELECT SINGLE aufnr, auart, matnr, charg, aufnr_status, aufnr_up, aufnr_main,
                          matnr_main,  data_status, qty, status, MAX( serial_no ) AS serial_no
              FROM ZZ1_I_POHDMESLOG
              WHERE api_type = 'HEADER' AND objectid = @lwa_result-manufacturingorder
              GROUP BY aufnr, auart, matnr, charg, aufnr_status, aufnr_up, aufnr_main,
                       matnr_main,  data_status, qty, status
              INTO CORRESPONDING FIELDS OF @lwa_pomeslog.

            IF ( lwa_pomeslog-aufnr <> lwa_result-manufacturingorder or lwa_pomeslog-auart <> lwa_result-manufacturingordertype
                or lwa_pomeslog-matnr <> lwa_result-material or lwa_pomeslog-charg <> lwa_result-YY1_PO_CHARG_ORD
                or lwa_pomeslog-aufnr_status <> lwa_result-wo_status or lwa_pomeslog-aufnr_up <> lwa_result-LeadingOrder
                or lwa_pomeslog-aufnr_main <> lwa_result-SuperiorOrder or lwa_pomeslog-matnr_main <> lwa_result-wo_option7
                or lwa_pomeslog-qty <> lwa_result-mfgorderplannedtotalqty or lwa_pomeslog-status = 'Error' ).

                MOVE-CORRESPONDING lwa_result TO lwa_body.
                lwa_body-manufacturingorder = lwa_result-manufacturingorder.
                lwa_manufacturingorder = lwa_result-manufacturingorder.

                CLEAR l_body.
                l_body = `{"WO":[{"WORK_ORDER": "` && lwa_result-manufacturingorder && `",`.
                l_body = l_body && `"WO_TYPE":"` && lwa_result-manufacturingordertype && `", `.
                l_body = l_body && `"PART_NO": "` && lwa_result-material && `", "VERSION": "", `.
                l_body = l_body && `"TARGET_QTY": "` && lwa_result-mfgorderplannedtotalqty && `", "WO_CREATE_DATE": "", "WO_SCHEDULE_DATE": "", "WORK_FLAG": "",`.
                l_body = l_body && `"WO_STATUS": "` && lwa_result-wo_status && `", "DEFAULT_PDLINE_name": "", "START_PROCESS_name": "", "END_PROCESS_name": "", "REMARK": "",`.
                l_body = l_body && `"SO_NO": "", "customer_part": "", "FACTORY_NO": "",`.
                l_body = l_body && `"MASTER_WO":"` && lwa_result-LeadingOrder && `", `.
                l_body = l_body && `"WO_OPTION6":"` && lwa_result-SuperiorOrder && `", `.
                l_body = l_body && `"WO_OPTION7":"` && lwa_result-wo_option7 && `", `.
                l_body = l_body && `"SAP_LOTNO":"` && lwa_result-YY1_PO_CHARG_ORD && `", `.
                l_body = l_body && `"Data_Status":"` && lwa_result-data_status && `", `.
                l_body = l_body && `"Para1": "", "Para2": "", "Para3": "", "Para4": "", "Para5": "", "Para6": "", "Para7": "", "Para8": "", "Para9": "", "Para10": ""`.
                l_body = l_body &&  `} ] }`.

                CLEAR: l_status, l_text, lwa_log, lt_log.
                "lwa_log-%cid = '1'.
                lwa_log-api_type = 'HEADER'.
                lwa_log-objectid = lwa_result-manufacturingorder.
                SELECT SINGLE MAX( serial_no ) FROM ZZ1_I_POHDMESLOG
                  WHERE api_type = @lwa_log-api_type AND objectid = @lwa_log-objectid
                  INTO @lwa_log-serial_no.
                lwa_log-serial_no = lwa_log-serial_no + 1.
                lwa_log-aufnr = lwa_result-manufacturingorder.
                lwa_log-auart = lwa_result-manufacturingordertype.
                lwa_log-matnr = lwa_result-material.
                lwa_log-charg = lwa_result-YY1_PO_CHARG_ORD.
                lwa_log-aufnr_status = lwa_result-wo_status.
                lwa_log-aufnr_up = lwa_result-LeadingOrder.
                lwa_log-aufnr_main = lwa_result-SuperiorOrder.
                lwa_log-matnr_main  = lwa_result-wo_option7.
                lwa_log-data_status = lwa_result-Data_Status.
                lwa_log-qty = lwa_result-mfgorderplannedtotalqty.

                FREE: lr_http_destination, lr_web_http_client, lr_request, lr_response.
                TRY.
                    lr_http_destination = cl_http_destination_provider=>create_by_url( i_url = '123' ).
                    lr_web_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lr_http_destination ).
                    lr_request = lr_web_http_client->get_http_request( ).
                    lr_request->set_authorization_basic( i_username = '123' i_password = '123'  ).
*                  lr_request->set_header_fields( i_fields = VALUE #( ( name  = '' value = '' ) ) ).

                    lr_request->set_text( /ui2/cl_json=>serialize( EXPORTING data = lwa_body pretty_name = /ui2/cl_json=>pretty_mode-none ) ).
                    lr_response = lr_web_http_client->execute( i_method = if_web_http_client=>post ).
*                  /ui2/cl_json=>deserialize( EXPORTING json = lr_response->get_text( ) pretty_name = /ui2/cl_json=>pretty_mode-none CHANGING data = lwa_res ).
                    IF lr_response->get_status( )-code <> 200.
                      lwa_log-status = 'Error'.
                      l_error = 'X'.
                      l_status = if_abap_behv_message=>severity-error.
                      l_text = lwa_result-manufacturingorder && ':' && lr_response->get_text( ).
                    ELSE.
                      lwa_log-status = 'Success'.
                      l_status = if_abap_behv_message=>severity-success.
                      l_text = lwa_result-manufacturingorder && ':上傳成功'.
                    ENDIF.
                  CATCH cx_http_dest_provider_error INTO lcx_root.
                    lwa_log-status = 'Error'.
                    l_error = 'X'.
                    l_status = if_abap_behv_message=>severity-error.
                    l_text = lwa_result-manufacturingorder && ':' && lcx_root->get_text( ).
                  CATCH cx_web_http_client_error INTO lcx_root.
                    lwa_log-status = 'Error'.
                    l_error = 'X'.
                    l_status = if_abap_behv_message=>severity-error.
                    l_text = lwa_result-manufacturingorder && ':' && lcx_root->get_text( ).
                ENDTRY.
*                lwa_mes-manufacturingorder = lwa_result-manufacturingorder.
*                lwa_mes-%msg = new_message_with_text( severity = l_status text = l_text ).
*                APPEND lwa_mes TO reported-zz1_i_pohdmes.


                lwa_log-message = l_text.
                lwa_log-ernam = sy-uname.
                lwa_log-erdat = sy-datum.
                lwa_log-erfzeit = sy-uzeit.
                APPEND lwa_log TO lt_log.
                MODIFY ENTITIES OF zz1_i_pohdmeslog
                    ENTITY zz1_i_pohdmeslog
                    CREATE AUTO FILL CID SET FIELDS WITH lt_log
                    REPORTED DATA(ls_reported)
                    MAPPED DATA(ls_mapped)
                    FAILED DATA(ls_failed).

                l_change = 'X'.

            ENDIF.

            IF lwa_result-manufacturingorder IS NOT INITIAL AND l_error IS INITIAL.
                CLEAR: lwa_mc106, lt_mc106[].
                SELECT a~Product, b~CharcValue
                  FROM I_Product AS a
                  JOIN ZZ1_I_ObjectCharacteristics AS b ON  a~Product = b~material
                                                        AND b~Class          = 'Z_MATERIAL_CL01'
                                                        AND b~Characteristic = 'Z_MY_MC_106'
                  WHERE b~CharcValue = '3'
                INTO CORRESPONDING FIELDS OF TABLE @lt_mc106.
                SORT lt_mc106 BY Product.


                LOOP AT lt_Componentmes INTO lwa_Componentmes WHERE manufacturingorder = lwa_result-manufacturingorder.
                    CLEAR: l_status, l_text, lwa_log, lt_log.
                    "lwa_log-%cid = '1'.
                    lwa_log-api_type = 'COMPONENT'.
                    lwa_log-objectid = lwa_Componentmes-manufacturingorder && lwa_Componentmes-reservation && lwa_Componentmes-reservationitem.
                    SELECT SINGLE MAX( serial_no ) FROM ZZ1_I_POHDMESLOG
                      WHERE api_type = @lwa_log-api_type AND objectid = @lwa_log-objectid
                      INTO @lwa_log-serial_no.

                    CLEAR: lwa_pomeslog.
                    IF lwa_log-serial_no <> 0.
                        SELECT SINGLE aufnr, matnr, reservation, Reservation_Item, ITEM_PART_NO, item_group,
                                      item_group_index, warehouse_no, qty, factory, delfalg, status,
                                      serial_no
                          FROM ZZ1_I_POHDMESLOG
                          WHERE api_type = @lwa_log-api_type AND aufnr = @lwa_log-objectid
                            AND serial_no = @lwa_log-serial_no
                          INTO CORRESPONDING FIELDS OF @lwa_pomeslog.
                    ENDIF.

                    IF lwa_Componentmes-MatlCompIsMarkedForDeletion IS NOT INITIAL.
                        lwa_Componentmes-data_status = '3'.
                        lwa_log-delfalg = 'X'.
                    ELSEIF lwa_pomeslog IS NOT INITIAL.
                        lwa_Componentmes-data_status = '2'.
                    ELSE.
                        lwa_Componentmes-data_status ='1'.
                    ENDIF.

                    IF ( lwa_pomeslog-aufnr <> lwa_Componentmes-manufacturingorder OR lwa_pomeslog-matnr <> lwa_Componentmes-material
                       OR lwa_pomeslog-reservation <> lwa_Componentmes-reservation OR lwa_pomeslog-Reservation_Item <> lwa_Componentmes-ReservationItem
                       OR lwa_pomeslog-ITEM_PART_NO <> lwa_Componentmes-ITEM_PART_NO OR lwa_pomeslog-item_group <> lwa_Componentmes-AlternativeItemGroup
                       OR lwa_pomeslog-item_group_index <> lwa_Componentmes-item_group_index OR lwa_pomeslog-warehouse_no <> lwa_Componentmes-warehouse_no
                       OR lwa_pomeslog-qty <> lwa_Componentmes-Issue_QTY OR lwa_pomeslog-factory <> lwa_Componentmes-Plant
                       OR lwa_pomeslog-delfalg <> lwa_Componentmes-MatlCompIsMarkedForDeletion OR lwa_pomeslog-status = 'Error' ).

                        CLEAR l_del.
                        LOOP AT lt_SuperiorOrder INTO lwa_SuperiorOrder WHERE ( LeadingOrder = lwa_Componentmes-manufacturingorder OR SuperiorOrder = lwa_Componentmes-manufacturingorder ).
                            IF lwa_Componentmes-ITEM_PART_NO = lwa_SuperiorOrder-Material.
                                l_del = 'X'.
                                EXIT.
                            ENDIF.
                        ENDLOOP.

                        IF l_del = 'X'.
                            DELETE lt_Componentmes.
                            CONTINUE.
                        ENDIF.

                        CLEAR lwa_mc106.
                        READ TABLE lt_mc106 INTO lwa_mc106 BINARY SEARCH WITH KEY Product = lwa_Componentmes-item_part_no.
                        IF sy-subrc = 0.
                            DELETE lt_Componentmes.
                            CONTINUE.
                        ENDIF.

                        IF lwa_Componentmes-AlternativeItemGroup IS NOT INITIAL.
                            LOOP AT lt_Componentmes INTO lwa_Componentmes2 WHERE manufacturingorder = lwa_Componentmes-manufacturingorder
                                                                            AND AlternativeItemGroup = lwa_Componentmes-AlternativeItemGroup
                                                                            AND AlternativeItemPriority < lwa_Componentmes-alternativeitempriority.
                            ENDLOOP.
                            IF sy-subrc <> 0.
                                lwa_Componentmes-ITEM_GROUP_INDEX = 'Y'.
                            ELSE.
                                lwa_Componentmes-ITEM_GROUP_INDEX = 'N'.
                            ENDIF.
                        ENDIF.

                        CLEAR: l_first, l_last, l_len.
                        l_first = lwa_Componentmes-ITEM_PART_NO+0(1).
                        l_len = strlen( lwa_Componentmes-ITEM_PART_NO ).
                        l_len = l_len - 1.
                        l_last = lwa_Componentmes-ITEM_PART_NO+l_len(1).
                        IF ( l_first = '9' AND l_last = 'N').
                            CLEAR: l_first.
                            l_first = lwa_Componentmes-ITEM_PART_NO+0(l_len).
                            lwa_Componentmes-ITEM_PART_NO = l_first.
                        ENDIF.

                        lwa_Componentmes-material = lwa_result-Material.
                        lwa_Componentmes-issue_qty = lwa_Componentmes-requiredquantity - lwa_Componentmes-withdrawnquantity.
                        lwa_Componentmes-movetype = '261'.
                        lwa_Componentmes-type = 'WO'.

                        MODIFY lt_Componentmes FROM lwa_Componentmes.

                        lwa_log-serial_no = lwa_log-serial_no + 1.
                        lwa_log-aufnr = lwa_Componentmes-manufacturingorder.
                        lwa_log-matnr = lwa_Componentmes-material.
                        lwa_log-data_status = lwa_Componentmes-Data_Status.
                        lwa_log-wo_pick_type = '10'.
                        lwa_log-reservation = lwa_Componentmes-reservation.
                        lwa_log-Reservation_Item = lwa_Componentmes-ReservationItem.
                        lwa_log-ITEM_PART_NO = lwa_Componentmes-ITEM_PART_NO.
                        lwa_log-item_group = lwa_Componentmes-AlternativeItemGroup.
                        lwa_log-item_group_index = lwa_Componentmes-item_group_index.
                        lwa_log-warehouse_no = lwa_Componentmes-warehouse_no.
                        lwa_log-qty = lwa_Componentmes-Issue_QTY.
                        lwa_log-factory = lwa_Componentmes-Plant.
                        lwa_log-MoveType = lwa_Componentmes-MoveType.
                        lwa_log-TYPE = lwa_Componentmes-TYPE.

                        CLEAR lwa_req.
                        lwa_req-WORK_ORDER = lwa_Componentmes-manufacturingorder.
                        lwa_req-PART_NO     = lwa_Componentmes-material.
                        lwa_req-wo_pick_type = '10'.
                        lwa_req-Reservation  = lwa_Componentmes-reservation.
                        lwa_req-ReservationItem = lwa_Componentmes-ReservationItem.
                        lwa_req-WAREHOUSE_NO     = lwa_Componentmes-warehouse_no.
                        lwa_req-ITEM_PART_NO      = lwa_Componentmes-ITEM_PART_NO.
                        lwa_req-ITEM_GROUP        = lwa_Componentmes-AlternativeItemGroup.
                        lwa_req-ITEM_GROUP_INDEX = lwa_Componentmes-item_group_index.
                        lwa_req-ITEM_COUNT        = lwa_Componentmes-Issue_QTY.
                        lwa_req-FACTORY           = lwa_Componentmes-Plant.
                        lwa_req-MoveType         = lwa_Componentmes-MoveType.
                        lwa_req-TYPE             = lwa_Componentmes-TYPE.
                        lwa_req-Data_Status     = lwa_Componentmes-Data_Status.


                        CALL METHOD /ui2/cl_json=>serialize "將回傳之格式 轉譯成Json
                          EXPORTING
                              data             = lwa_req"l_result_str "l_final
*                            jsonx            =
                              pretty_name      = /ui2/cl_json=>pretty_mode-none
*                            assoc_arrays     = abap_true
*                            assoc_arrays_opt = C_BOOL-FALSE
                          RECEIVING
                               R_JSON             = l_body.
                        REPLACE ALL OCCURRENCES OF:
                            'RESERVATION' IN l_body WITH 'Reservation',
                            'RESERVATIONITEM' IN l_body WITH 'ReservationItem',
                            'ISSUE_QTY' IN l_body WITH 'Issue_QTY',
                            'SATGE_FLAG' IN l_body WITH 'SATGE_Flag',
                            'VIRTUAL_KEY' IN l_body WITH 'Virtual_key',
                            'MOVETYPE' IN l_body WITH 'MoveType',
                            'DATA_STATUS' IN l_body WITH 'Data_Status'.

                        FREE: lr_http_destination, lr_web_http_client, lr_request, lr_response.
                        TRY.
                            lr_http_destination = cl_http_destination_provider=>create_by_url( i_url = '123' ).
                            lr_web_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lr_http_destination ).
                            lr_request = lr_web_http_client->get_http_request( ).
                            lr_request->set_authorization_basic( i_username = '123' i_password = '123'  ).
*                          lr_request->set_header_fields( i_fields = VALUE #( ( name  = '' value = '' ) ) ).

                            lr_request->set_text( /ui2/cl_json=>serialize( EXPORTING data = lwa_body pretty_name = /ui2/cl_json=>pretty_mode-none ) ).
                            lr_response = lr_web_http_client->execute( i_method = if_web_http_client=>post ).
*                          /ui2/cl_json=>deserialize( EXPORTING json = lr_response->get_text( ) pretty_name = /ui2/cl_json=>pretty_mode-none CHANGING data = lwa_res ).
                            IF lr_response->get_status( )-code <> 200.
                              lwa_log-status = 'Error'.
                              l_error = 'X'.
                              l_status = if_abap_behv_message=>severity-error.
                              l_text = lwa_result-manufacturingorder && ':' && lr_response->get_text( ).
                            ELSE.
                              lwa_log-status = 'Success'.
                              l_status = if_abap_behv_message=>severity-success.
                              l_text = lwa_result-manufacturingorder && ':上傳成功'.
                            ENDIF.
                          CATCH cx_http_dest_provider_error INTO lcx_root.
                            lwa_log-status = 'Error'.
                            l_error = 'X'.
                            l_status = if_abap_behv_message=>severity-error.
                            l_text = lwa_result-manufacturingorder && ':' && lcx_root->get_text( ).
                          CATCH cx_web_http_client_error INTO lcx_root.
                            lwa_log-status = 'Error'.
                            l_error = 'X'.
                            l_status = if_abap_behv_message=>severity-error.
                            l_text = lwa_result-manufacturingorder && ':' && lcx_root->get_text( ).
                        ENDTRY.
*                        lwa_mes-manufacturingorder = lwa_result-manufacturingorder.
*                        lwa_mes-%msg = new_message_with_text( severity = l_status text = l_text ).
*                        APPEND lwa_mes TO reported-zz1_i_pohdmes.


                        lwa_log-message = l_text.
                        lwa_log-ernam = sy-uname.
                        lwa_log-erdat = sy-datum.
                        lwa_log-erfzeit = sy-uzeit.
                        APPEND lwa_log TO lt_log.

                        CLEAR: ls_reported, ls_mapped, ls_failed.
                        MODIFY ENTITIES OF zz1_i_pohdmeslog
                            ENTITY zz1_i_pohdmeslog
                            CREATE AUTO FILL CID SET FIELDS WITH lt_log
                            REPORTED ls_reported
                            MAPPED ls_mapped
                            FAILED ls_failed.

                        l_change = 'X'.
                    ENDIF.
                ENDLOOP.

                IF l_error IS NOT INITIAL AND l_change = 'X'..
                    IF lwa_manufacturingorder-YY1_MES_PO_ORD IS INITIAL.
                        lwa_manufacturingorder-YY1_MES_PO_ORD = 'X'.
                    ENDIF.
                    lwa_manufacturingorder-YY1_MES_STATUS_ORD = 'N'.
                    lwa_manufacturingorder-yy1_material_delivery_ord = lwa_result-yy1_material_delivery_ord.
                    lwa_manufacturingorder-yy1_po_charg_ord = lwa_result-yy1_po_charg_ord.
                    lwa_manufacturingorder-manufacturingorder = lwa_result-ManufacturingOrder.
                    Update_Aufnr( wa_manufacturingorder = lwa_manufacturingorder ).
                ENDIF.
            ELSEIF l_error IS NOT INITIAL AND l_change = 'X'..
                lwa_manufacturingorder-YY1_MES_STATUS_ORD = 'N'.
                lwa_manufacturingorder-yy1_material_delivery_ord = lwa_result-yy1_material_delivery_ord.
                lwa_manufacturingorder-yy1_po_charg_ord = lwa_result-yy1_po_charg_ord.
                lwa_manufacturingorder-manufacturingorder = lwa_result-ManufacturingOrder.
                Update_Aufnr( wa_manufacturingorder = lwa_manufacturingorder ).
            ENDIF.

            IF l_error IS INITIAL AND l_change = 'X'.
                IF lwa_manufacturingorder-YY1_MES_PO_ORD IS INITIAL.
                    lwa_manufacturingorder-YY1_MES_PO_ORD = 'X'.
                ENDIF.
                lwa_manufacturingorder-YY1_MES_STATUS_ORD = 'Y'.
                lwa_manufacturingorder-yy1_material_delivery_ord = lwa_result-yy1_material_delivery_ord.
                lwa_manufacturingorder-yy1_po_charg_ord = lwa_result-yy1_po_charg_ord.
                lwa_manufacturingorder-manufacturingorder = lwa_result-ManufacturingOrder.
                Update_Aufnr( wa_manufacturingorder = lwa_manufacturingorder ).
            ENDIF.

        ENDLOOP.

    ENDMETHOD.

    METHOD MaterialConfirmation.
        DATA: l_url TYPE string.
        DATA: l_body TYPE string.
        DATA: l_order TYPE string.
        DATA: lwa_header TYPE if_web_http_request=>name_value_pair,
              lt_header  TYPE if_web_http_request=>name_value_pairs.
        DATA: l_status TYPE if_web_http_response=>http_status .
        DATA: l_text TYPE string.
        DATA: lr_http_destination TYPE REF TO if_http_destination.
        DATA: lr_web_http_client TYPE REF TO if_web_http_client.
        DATA: lr_request TYPE REF TO if_web_http_request.
        DATA: lr_response TYPE REF TO if_web_http_response.

        DATA: lwa_result TYPE STRUCTURE FOR READ RESULT zz1_i_pohdmes,
              lt_result TYPE TABLE FOR READ RESULT zz1_i_pohdmes.

        READ ENTITIES OF zz1_i_pohdmes IN LOCAL MODE
          ENTITY zz1_i_pohdmes
          ALL FIELDS WITH CORRESPONDING #( keys )
          RESULT lt_result
          FAILED FINAL(ls_fail).

        LOOP AT lt_result INTO lwa_result.
            IF lwa_result-YY1_MATERIAL_DELIVERY_ORD IS NOT INITIAL.
                MODIFY ENTITY I_ProductionOrderTP
                    UPDATE FIELDS (
                                    yy1_mes_po_ord
                                    yy1_mes_status_ord
                                    yy1_material_delivery_ord
                                  )
                    WITH VALUE #(
                                  (
                                    %key-productionorder = lwa_result-manufacturingorder
                                    %data-yy1_mes_po_ord = lwa_result-yy1_mes_po_ord
                                    %data-yy1_mes_status_ord = lwa_result-yy1_mes_status_ord
                                    %data-yy1_material_delivery_ord = ''
                                  )
                                 )
                    FAILED DATA(failed1)
                    REPORTED DATA(reported1)
                    MAPPED DATA(mapped1).
            ELSE.
                MODIFY ENTITY I_ProductionOrderTP
                    UPDATE FIELDS (
                                    yy1_mes_po_ord
                                    yy1_mes_status_ord
                                    yy1_material_delivery_ord
                                  )
                    WITH VALUE #(
                                  (
                                    %key-productionorder = lwa_result-manufacturingorder
                                    %data-yy1_mes_po_ord = lwa_result-yy1_mes_po_ord
                                    %data-yy1_mes_status_ord = lwa_result-yy1_mes_status_ord
                                    %data-yy1_material_delivery_ord = 'X'
                                  )
                                 )
                    FAILED DATA(failed2)
                    REPORTED DATA(reported2)
                    MAPPED DATA(mapped2).
            ENDIF.

*            DATA(l_etag) = getEtag( manufacturingorder = lwa_result-manufacturingorder ).
*            CLEAR lt_header.
*            IF l_etag IS INITIAL.
*                lt_header = "Headers參數
*                    VALUE #(
*                     ( name = 'Accept' value = 'application/json'  )
*                     ( name = 'Content-Type' value = 'application/json'  ) "Content-Type：內容格式(Body的格式)，application/json：JSON格式
*                     ( name = 'If-Match' value = '*'  ) ).
*            ELSE.
*                lt_header = "Headers參數
*                    VALUE #(
*                     ( name = 'Accept' value = 'application/json'  )
*                     ( name = 'Content-Type' value = 'application/json'  ) "Content-Type：內容格式(Body的格式)，application/json：JSON格式
*                     ( name = 'If-Match' value = l_etag  ) ).
*            ENDIF.
*
*            CLEAR: l_body, l_url.
*            IF lwa_result-YY1_MATERIAL_DELIVERY_ORD IS NOT INITIAL.
*                l_body = `{"d":{"YY1_MATERIAL_DELIVERY_ORD":""}}`. "Body參數 "YYYYYYYYY"
*            ELSE.
*                l_body = `{"d":{"YY1_MATERIAL_DELIVERY_ORD":"X"}}`. "Body參數 "YYYYYYYYY"
*            ENDIF.
*
*            l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_PRODUCTION_ORDER_2_SRV/A_ProductionOrder_2('` &&  lwa_result-manufacturingorder && `')`.
*
*            CLEAR: l_status, l_text.
*            FREE: lr_http_destination, lr_web_http_client, lr_request, lr_response.
*            TRY.
*                lr_http_destination = cl_http_destination_provider=>create_by_url( i_url = l_url ). "直接在程式碼中指定 URL 來呼叫 HTTP 或 SOAP 服務
*            CATCH cx_http_dest_provider_error INTO DATA(lr_data).
*            ENDTRY.
*            IF lr_data IS INITIAL.
*                TRY.
*                    lr_web_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lr_http_destination ).
*
*                    lr_request = lr_web_http_client->get_http_request( ).
*                    lr_request->set_authorization_basic( i_username = 'InnatechMIYABI2025TEST' i_password = 'Innatech@MIYABI2025TEST' ).
*                    lr_request->set_header_fields( i_fields = lt_header ).
*                    lr_request->set_text( i_text = l_body ).
*                    lr_web_http_client->set_csrf_token( ). "獲得TOKEN
*                    lr_response = lr_web_http_client->execute( i_method
*                    = if_web_http_client=>PATCH ).
*                    IF lr_response IS BOUND.
*                        l_status = lr_response->get_status( ). "獲得執行結果狀態
*                        l_text = lr_response->get_text( ). "獲得執行結果訊息
*                    ENDIF.
**                    DATA(lr_web_http_response) = lr_web_http_client->execute( i_method = if_web_http_client=>PATCH ).
**                    DATA(l_response) = lr_web_http_response->get_text( ).
*                    lr_web_http_client->close( ).
*                CATCH cx_web_http_client_error INTO DATA(lr_data2).
*                ENDTRY.
*                IF ( l_status-code = 204 OR l_status-code = 200 ).
*
*                ENDIF.
*           ENDIF.
        ENDLOOP.
    ENDMETHOD.

    METHOD Update_Aufnr.

        MODIFY ENTITY I_ProductionOrderTP
            UPDATE FIELDS (
                            yy1_mes_po_ord
                            yy1_mes_status_ord
                            yy1_material_delivery_ord
                          )
            WITH VALUE #(
                          (
                            %key-productionorder = wa_manufacturingorder-manufacturingorder
                            %data-yy1_mes_po_ord = wa_manufacturingorder-yy1_mes_po_ord
                            %data-yy1_mes_status_ord = wa_manufacturingorder-yy1_mes_status_ord
                            %data-yy1_material_delivery_ord = wa_manufacturingorder-yy1_material_delivery_ord
                          )
                         )
            FAILED DATA(failed1)
            REPORTED DATA(reported1)
            MAPPED DATA(mapped1).
*        IF failed1 IS INITIAL.
*            COMMIT ENTITIES
*                RESPONSES
*                FAILED   DATA(failed_commit)
*                REPORTED DATA(reported_commit).
*        ELSE.
*            ROLLBACK ENTITIES.
*        ENDIF.




*          IF failed IS INITIAL.
*            COMMIT ENTITIES
*              RESPONSES
*                FAILED   DATA(failed_commit)
*                REPORTED DATA(reported_commit).
*          ELSE.
*            ROLLBACK ENTITIES.
*          ENDIF.
*        DATA: l_url TYPE string.
*        DATA: l_body TYPE string.
*        DATA: lwa_header TYPE if_web_http_request=>name_value_pair,
*              lt_header  TYPE if_web_http_request=>name_value_pairs.
*        DATA: l_status TYPE if_web_http_response=>http_status .
*        DATA: l_text TYPE string.
*        DATA: lr_http_destination TYPE REF TO if_http_destination.
*        DATA: lr_web_http_client TYPE REF TO if_web_http_client.
*        DATA: lr_request TYPE REF TO if_web_http_request.
*        DATA: lr_response TYPE REF TO if_web_http_response.
*
*        DATA(l_etag) = getEtag( manufacturingorder = wa_manufacturingorder-manufacturingorder ).
*
*        CLEAR: lt_header, l_body, l_url.
*        IF l_etag IS INITIAL.
*            lt_header = "Headers參數
*                VALUE #(
*                 ( name = 'Accept' value = 'application/json'  )
*                 ( name = 'Content-Type' value = 'application/json'  ) "Content-Type：內容格式(Body的格式)，application/json：JSON格式
*                 ( name = 'If-Match' value = '*'  ) ).
*        ELSE.
*            lt_header = "Headers參數
*                VALUE #(
*                 ( name = 'Accept' value = 'application/json'  )
*                 ( name = 'Content-Type' value = 'application/json'  ) "Content-Type：內容格式(Body的格式)，application/json：JSON格式
*                 ( name = 'If-Match' value = l_etag  ) ).
*        ENDIF.
*
*        IF wa_manufacturingorder-YY1_MES_PO_ORD IS NOT INITIAL.
*            l_body = `{"d":{"YY1_MES_PO_ORD":"` && wa_manufacturingorder-YY1_MES_PO_ORD && `", "YY1_MES_STATUS_ORD":"` && wa_manufacturingorder-YY1_MES_STATUS_ORD && `"}}`. "Body參數 "YYYYYYYYY"
*        ELSE.
*            l_body = `{"d":{"YY1_MES_STATUS_ORD":"` && wa_manufacturingorder-YY1_MES_STATUS_ORD && `"}}`. "Body參數 "YYYYYYYYY"
*        ENDIF.
*
*        l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_PRODUCTION_ORDER_2_SRV/A_ProductionOrder_2('` &&  wa_manufacturingorder-manufacturingorder && `')`.
*
*        CLEAR: l_status, l_text.
*        FREE: lr_http_destination, lr_web_http_client, lr_request, lr_response.
*        TRY.
*            lr_http_destination = cl_http_destination_provider=>create_by_url( i_url = l_url ). "直接在程式碼中指定 URL 來呼叫 HTTP 或 SOAP 服務
*        CATCH cx_http_dest_provider_error INTO DATA(lr_data).
*        ENDTRY.
*        IF lr_data IS INITIAL.
*            TRY.
*                lr_web_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lr_http_destination ).
*
*                lr_request = lr_web_http_client->get_http_request( ).
*                lr_request->set_authorization_basic( i_username = 'InnatechMIYABI2025TEST' i_password = 'Innatech@MIYABI2025TEST' ).
*                lr_request->set_header_fields( i_fields = lt_header ).
*                lr_request->set_text( i_text = l_body ).
*                lr_web_http_client->set_csrf_token( ). "獲得TOKEN
*                lr_response = lr_web_http_client->execute( i_method
*                = if_web_http_client=>PATCH ).
*                IF lr_response IS BOUND.
*                    l_status = lr_response->get_status( ). "獲得執行結果狀態
*                    l_text = lr_response->get_text( ). "獲得執行結果訊息
*                ENDIF.
*                DATA(lr_web_http_response) = lr_web_http_client->execute( if_web_http_client=>PATCH ).
*                DATA(l_response) = lr_web_http_response->get_text( ).
*                lr_web_http_client->close( ).
*            CATCH cx_web_http_client_error INTO DATA(lr_data2).
*            ENDTRY.
*            IF ( l_status-code = 204 OR l_status-code = 200 ).
*
*            ENDIF.
*       ENDIF.
    ENDMETHOD.

*    METHOD getEtag.
*        DATA: l_url TYPE string.
*        DATA: l_etag  TYPE string.
*        DATA: lwa_header TYPE if_web_http_request=>name_value_pair,
*              lt_header  TYPE if_web_http_request=>name_value_pairs.
*        DATA: l_status TYPE if_web_http_response=>http_status .
*        DATA: l_text TYPE string.
*        DATA: lr_http_destination TYPE REF TO if_http_destination.
*        DATA: lr_web_http_client TYPE REF TO if_web_http_client.
*        DATA: lr_request TYPE REF TO if_web_http_request.
*        DATA: lr_response TYPE REF TO if_web_http_response.
*
*        CLEAR: lt_header, l_url.
*        lt_header = "Headers參數
*            VALUE #(
*             ( name = 'Accept' value = 'application/json'  )
*             ( name = 'Content-Type' value = 'application/json'  ) "Content-Type：內容格式(Body的格式)，application/json：JSON格式
*             ( name = 'If-Match' value = '*'  ) ).
*
*        l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_PRODUCTION_ORDER_2_SRV/A_ProductionOrder_2('` &&  manufacturingorder && `')`.
*
*        CLEAR: l_status, l_text.
*        FREE: lr_http_destination, lr_web_http_client, lr_request, lr_response.
*        TRY.
*            lr_http_destination = cl_http_destination_provider=>create_by_url( i_url = l_url ). "直接在程式碼中指定 URL 來呼叫 HTTP 或 SOAP 服務
*        CATCH cx_http_dest_provider_error INTO DATA(lr_data).
*        ENDTRY.
*        IF lr_data IS INITIAL.
*            TRY.
*                lr_web_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lr_http_destination ).
*
*                lr_request = lr_web_http_client->get_http_request( ).
*                lr_request->set_authorization_basic( i_username = 'InnatechMIYABI2025TEST' i_password = 'Innatech@MIYABI2025TEST' ).
*                lr_request->set_header_fields( i_fields = lt_header ).
*                lr_web_http_client->set_csrf_token( ). "獲得TOKEN
*                lr_response = lr_web_http_client->execute( i_method
*                = if_web_http_client=>GET ).
*                IF lr_response IS BOUND.
*                    l_status = lr_response->get_status( ). "獲得執行結果狀態
*                    l_text = lr_response->get_text( ). "獲得執行結果訊息
*                ENDIF.
*                DATA(lr_web_http_response) = lr_web_http_client->execute( if_web_http_client=>GET ).
*                DATA(l_response) = lr_web_http_response->get_text( ).
*
*                rv_result = lr_response->get_header_field( 'ETag' ).  " ← 拿到 ETag
*                lr_web_http_client->close( ).
*            CATCH cx_web_http_client_error INTO DATA(lr_data2).
*            ENDTRY.
*            IF ( l_status-code = 204 OR l_status-code = 200 ).
*
*            ENDIF.
*       ENDIF.
*
*    ENDMETHOD.
ENDCLASS.
