CLASS zz1_cl_odmes DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.

    DATA:
    BEGIN OF wa_DeliveryDocument,
          DeliveryDocument     TYPE I_DeliveryDocument-DeliveryDocument,
          YY1_ODMES_STATUS_DLH TYPE I_DeliveryDocument-YY1_ODMES_STATUS_DLH,
        END OF wa_DeliveryDocument.

    METHODS: updateODField
      IMPORTING DeliveryDocument LIKE wa_DeliveryDocument.

    METHODS: updateCRDField
      IMPORTING DeliveryDocument LIKE wa_DeliveryDocument.

    METHODS: getEtag
      IMPORTING DeliveryDocument TYPE I_DeliveryDocument-DeliveryDocument
                updateField TYPE string
      RETURNING VALUE(rv_result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZZ1_CL_ODMES IMPLEMENTATION.


    METHOD if_apj_dt_exec_object~get_parameters.

        " Return the supported selection parameters here
        et_parameter_def = VALUE #(

          ( selname = 'P_CLNT' kind = if_apj_dt_exec_object=>parameter datatype = 'C' length = 3 param_text =
            '環境' changeable_ind = abap_true )"DEV QAS PRD
        ).
        et_parameter_def = VALUE #(
            ( selname = 'S_DATE' kind = if_apj_dt_exec_object=>select_option datatype = 'D' length = 8 param_text =
            '日期' changeable_ind = abap_true )
        ).
        " Return the default parameters values here
        et_parameter_val = VALUE #(
          ( selname = 'S_DATE' kind = if_apj_dt_exec_object=>select_option sign = 'I' option = 'BT' low = cl_abap_context_info=>get_system_date( )  high = cl_abap_context_info=>get_system_date( ) )
         ).

    ENDMETHOD.


    METHOD if_apj_rt_exec_object~execute.
        "Execution logic when the job is started
        DATA p_clnt TYPE c LENGTH 3.
        DATA: s_date TYPE RANGE OF d,
            a(2).
        DATA: l_headurl TYPE string .
        DATA: l_patchurl TYPE string .

        DATA: l_password TYPE string ,
              l_name TYPE string.
        DATA: l_url TYPE string.
        DATA: l_body TYPE string.
        DATA: lwa_header TYPE if_web_http_request=>name_value_pair,
               lt_header  TYPE if_web_http_request=>name_value_pairs.
        DATA: l_status TYPE if_web_http_response=>http_status .
        DATA: l_text TYPE string.

        DATA: lr_http_destination TYPE REF TO if_http_destination.
        DATA: lr_web_http_client TYPE REF TO if_web_http_client.
        DATA: lr_request TYPE REF TO if_web_http_request.
        DATA: lr_response TYPE REF TO if_web_http_response.
        DATA: lwa_head TYPE zz1_i_odmes,
              lt_head  TYPE STANDARD TABLE OF zz1_i_odmes,
              lwa_item TYPE zz1_i_odmes,
              lt_item  TYPE STANDARD TABLE OF zz1_i_odmes,
              lwa_tmp TYPE zz1_i_odmes,
              lt_tmp  TYPE STANDARD TABLE OF zz1_i_odmes,
              lt_log TYPE STANDARD TABLE OF zz1_odmes_log,
              l_serialno TYPE zz1_odmes_log-serial_no ,
              lwa_log TYPE zz1_odmes_log,
              l_user TYPE zz1_odmes_log-ernam,
              l_date TYPE zz1_odmes_log-erdat,
              l_time TYPE zz1_odmes_log-erfzeit,
              l_check(1).

        DATA: lwa_DeliveryDocument LIKE wa_DeliveryDocument.

        DATA: l_err type string..
        DATA: cx_root TYPE REF TO cx_root.
        DATA:l_text2(200).
        " Getting the actual parameter values(Just for show. Not needed for the logic below)
        LOOP AT it_parameters INTO DATA(ls_parameter).
            CASE ls_parameter-selname.
                WHEN 'P_CLNT'.
                    p_clnt = ls_parameter-low.
                WHEN 'S_DATE'.
                    APPEND VALUE #( sign = ls_parameter-sign
                                    option = ls_parameter-option
                                    low = ls_parameter-low
                                    high = ls_parameter-high ) TO s_date.
            ENDCASE.
        ENDLOOP.
        try.
            data(l_log) = cl_bali_log=>create_with_header( cl_bali_header_setter=>create( object =
                           'ZZ1_ODMES_LOG' subobject = 'ZZ1_ODMES' ) ).
        catch cx_bali_runtime.
            "handle exception
            a = 2.
        ENDTRY.

        DATA:BEGIN OF lwa_DNDetails,
              DN_ITEM(25),
              SO_NO(25),
              SO_ITEM(25),
              PART_NO(22),
              QTY(22),
              DESCRIPTION(160),
              WH_NO(25),
              FACTORY_NAME(20),
              PO(25),
              PO_Item(25),
              MoveType(4),
              RMA_Flag(4),
              Declare_at_customs(50),
              Data_Status(1),
          END OF lwa_DNDetails,
          DNDetails LIKE STANDARD TABLE OF lwa_DNDetails,

          BEGIN OF  lwa_data,
              DN_NO(25),
              WORK_FLAG(10),
              ENABLED(10),
              CUSTOMER_ID(22),
              HUB_ID(22),
              SITE_ID(25),
              SHIP_TO(40),
              CONTAINER(25),
              VHICLE_NO(25),
              REMARK(250),
              ERP_ID(22),
              DELIVERY_Date(50),
              WH_NO(25),
              invoiceNo(25),
              PGI_Date(1),
              Country(50),
              incoterms(50),
              Ship_Via_ShippingType(50),
              TW_DN(25),
              TW_SO(25),
              Declare_at_customs(50),
              FACTORY_NAME(20),
              Compnay_Code(4),
              Delivery_Type(4),
              PO(25),
              DNDetails LIKE DNDetails,
          END OF lwa_data,
          lt_data LIKE STANDARD TABLE OF lwa_data.

        DATA: BEGIN OF lwa_plant,
                plant TYPE i_plant-Plant,
                country TYPE ZZ1_I_ADDRESS_2-Country,
              END OF lwa_plant,
              lt_plant LIKE STANDARD TABLE OF lwa_plant.

        SELECT * FROM  zz1_i_odmes WHERE CreationDate IN @s_date
          INTO CORRESPONDING FIELDS OF TABLE @lt_item.
        lt_head = lt_item.
        SORT lt_head BY DN_NO.
        DELETE ADJACENT DUPLICATES FROM lt_head COMPARING DN_NO.
        MOVE-CORRESPONDING lt_item[] TO lt_tmp[].
        SORT lt_tmp BY FACTORY_NAME.
        DELETE ADJACENT DUPLICATES FROM lt_tmp COMPARING FACTORY_NAME.
        SORT lt_tmp BY FACTORY_NAME.

        SELECT a~Plant, b~country
           FROM i_plant AS a
           JOIN ZZ1_I_ADDRESS_2 AS b ON a~AddressID = b~AddressID
           FOR ALL ENTRIES IN @lt_tmp
           WHERE a~Plant = @lt_tmp-factory_name
           INTO CORRESPONDING FIELDS OF TABLE @lt_plant.

        SORT lt_plant BY Plant.

        CLEAR lt_tmp[].
        MOVE-CORRESPONDING lt_item[] TO lt_tmp[].
        SORT lt_tmp BY DN_NO DN_ITEM.

        IF lt_item IS INITIAL."沒資料
            DATA(l_success_text2) = cl_bali_free_text_setter=>create( severity =
                            if_bali_constants=>C_SEVERITY_STATUS "c_severity_error
                            text = '無可執行之資料' ).
            TRY.
              l_log->add_item( item = l_success_text2 ).
            CATCH cx_bali_runtime.
              a = 2.
            ENDTRY.
        ELSE. "call api
            LOOP AT lt_head INTO lwa_head.
                clear : lwa_data.
                lwa_data-dn_no = lwa_head-dn_no.
                lwa_data-customer_id = lwa_head-customer_id .
                lwa_data-ship_to = lwa_head-ship_to.
                lwa_data-delivery_date = lwa_head-DeliveryDate.
                lwa_data-incoterms      = lwa_head-incoterms.

                CLEAR lwa_tmp.
                READ TABLE lt_tmp INTO lwa_tmp BINARY SEARCH WITH KEY dn_no = lwa_head-dn_no.
                IF sy-subrc = 0.
                    lwa_data-factory_name = lwa_tmp-factory_name.
                    lwa_data-po = lwa_tmp-po.
                    CLEAR lwa_plant.
                    READ TABLE lt_plant INTO lwa_plant BINARY SEARCH WITH KEY Plant = lwa_tmp-factory_name.
                    IF sy-subrc = 0.
                        lwa_data-country  = lwa_plant-country.
                    ENDIF.
                ENDIF.

                lwa_data-compnay_code = lwa_head-Compnay_Code.
                lwa_data-po           = lwa_head-po.

                CLEAR DNDetails[].
                LOOP AT lt_item INTO lwa_item WHERE dn_no = lwa_head-dn_no.
                    CLEAR lwa_DNDetails.
                    lwa_DNDetails-dn_item = lwa_item-dn_item.
                    lwa_DNDetails-part_no = lwa_item-part_no.
                    lwa_DNDetails-qty = lwa_item-qty.
                    lwa_DNDetails-description = lwa_item-description.
                    lwa_DNDetails-wh_no = lwa_item-wh_no.
                    lwa_DNDetails-factory_name = lwa_item-factory_name.
                    lwa_DNDetails-movetype = lwa_item-MoveType.
                    APPEND lwa_DNDetails TO DNDetails.
                ENDLOOP.
                IF DNDetails[] IS NOT INITIAL.
                    MOVE-CORRESPONDING DNDetails TO lwa_data-dndetails.
                ENDIF.

                "將資料轉成JSON
                l_body = /ui2/cl_json=>serialize( data = lwa_data pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
                FREE: lr_http_destination, lr_web_http_client, lr_request, lr_response.
                TRY.
                    lr_http_destination = cl_http_destination_provider=>create_by_url( i_url = l_url ).
                CATCH cx_http_dest_provider_error INTO DATA(lr_data).
                    a = 2.
                ENDTRY.

                IF lr_data IS INITIAL.
                    TRY.
                        lr_web_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lr_http_destination ).
                    CATCH cx_web_http_client_error INTO DATA(lr_data2).
                        a = 2.
                    ENDTRY.
                    lr_request = lr_web_http_client->get_http_request( ).
                    CLEAR: lwa_header , lt_header.
                    lt_header = "Headers參數
                        VALUE #(
                         ( name = 'Accept' value = 'application/json'  )
                         ( name = 'Content-Type' value = 'application/json'  ) "Content-Type：內容格式(Body的格式)，application/json：JSON格式
                         ( name = 'If-Match' value = '*'  ) ).
                    lr_request->set_authorization_basic( i_username = 'InnatechMIYABI2025TEST' i_password = 'Innatech@MIYABI2025TEST' ).
                    lr_request->set_header_fields( i_fields = lt_header ).
                    lr_request->set_text( i_text = l_body ).
                    lr_web_http_client->set_csrf_token( ). "獲得TOKEN
                    TRY.
                        lr_response = lr_web_http_client->execute( i_method = if_web_http_client=>post ).
                    CATCH cx_web_http_client_error INTO lr_data2.
                        a = 2.
                    ENDTRY.
                    IF lr_response IS BOUND.
                        l_status = lr_response->get_status( ).
                        l_text = lr_response->get_text( ).
                        TRY.
                            lr_web_http_client->close( ).
                        CATCH cx_web_http_client_error INTO lr_data2.
                            a = 2.
                        ENDTRY.
                    ENDIF.
                    CLEAR: lwa_log , l_user, l_date, l_time.
                    lwa_log-dn_no = lwa_item-dn_no.
                    lwa_log-customer_id = lwa_head-customer_id .
                    lwa_log-ship_to     = lwa_head-ship_to.
                    lwa_log-delivery_date = lwa_head-DeliveryDate.
                    lwa_log-country        = lwa_data-country.
                    lwa_log-incoterms      = lwa_head-incoterms.
                    lwa_log-factory_name   = lwa_data-factory_name.
                    lwa_log-compnay_code = lwa_head-Compnay_Code.
                    lwa_log-po           = lwa_head-po.

                    l_user = sy-uname.
                    l_date = sy-datum.
                    l_time = sy-uzeit.
                    lwa_log-ernam  = l_user.
                    lwa_log-erdat  = l_date.
                    lwa_log-erfzeit = l_time.

                    CLEAR lwa_DeliveryDocument.
                    lwa_DeliveryDocument-deliverydocument = lwa_head-dn_no.

                    IF ( l_status-code = 204 OR l_status-code = 200 ).
                        lwa_log-status = 'SUCCESS'.
                        lwa_DeliveryDocument-yy1_odmes_status_dlh = 'S'.
                        CONCATENATE '已傳送出貨通知單:' lwa_item-dn_no INTO l_text2.
                        l_success_text2 = cl_bali_free_text_setter=>create( severity =
                                if_bali_constants=>C_SEVERITY_STATUS "c_severity_error
                                text = l_text2 ).
                        TRY.
                            l_log->add_item( item = l_success_text2 ).
                        CATCH cx_bali_runtime.
                            a = 2.
                        ENDTRY.
                    ELSE.
                        lwa_log-status = 'ERROR'.
                        lwa_DeliveryDocument-yy1_odmes_status_dlh = 'E'.
                        lwa_log-message = l_text.
                        CONCATENATE '出貨通知單資料傳送失敗:' lwa_item-dn_no INTO l_text2.
                        l_success_text2 = cl_bali_free_text_setter=>create( severity =
                                if_bali_constants=>C_SEVERITY_ERROR "c_severity_error
                                text = l_text2 ).
                        TRY.
                            l_log->add_item( item = l_success_text2 ).
                        CATCH cx_bali_runtime.
                            a = 2.
                        ENDTRY.
                    ENDIF.

                    LOOP AT lt_item INTO lwa_item WHERE dn_no = lwa_head-dn_no.
                        CLEAR: l_serialno.
                        lwa_log-dn_item = lwa_item-dn_item.
                        SELECT SINGLE MAX( serial_no ) FROM zz1_odmes_log
                            WHERE dn_no = @lwa_item-dn_no AND dn_item = @lwa_item-dn_item
                            INTO @l_serialno.
                        lwa_log-serial_no = l_serialno + 1 .
                        lwa_log-part_no = lwa_item-part_no.
                        lwa_log-qty = lwa_item-qty.
                        lwa_log-description = lwa_item-description.
                        lwa_log-wh_no = lwa_item-wh_no.
                        lwa_log-factory_name_it = lwa_item-factory_name.
                        lwa_log-movetype = lwa_item-MoveType.
                        APPEND lwa_log TO lt_log.
                    ENDLOOP.


                    IF lwa_head-SDDocumentCategory = 'T'.
                        updateCRDField( DeliveryDocument = lwa_DeliveryDocument ).
                    ELSE.
                        updateODField( DeliveryDocument = lwa_DeliveryDocument ).
                    ENDIF.
               ENDIF.
            ENDLOOP.
            IF lt_log[] IS NOT INITIAL.
                MODIFY zz1_odmes_log FROM TABLE @lt_log.
            ENDIF.
        ENDIF.
        TRY.
            cl_bali_log_db=>get_instance( )->save_log( log = l_log assign_to_current_appl_job = abap_true ).
        CATCH cx_bali_runtime.
            a = 2.
            "handle exception
        ENDTRY.
        COMMIT WORK.
    ENDMETHOD.


    METHOD if_oo_adt_classrun~main.
    ENDMETHOD.


    METHOD updateODField.
        DATA: l_url TYPE string.
        DATA: l_body TYPE string.
        DATA: lwa_header TYPE if_web_http_request=>name_value_pair,
              lt_header  TYPE if_web_http_request=>name_value_pairs.
        DATA: l_status TYPE if_web_http_response=>http_status .
        DATA: l_text TYPE string.
        DATA: lr_http_destination TYPE REF TO if_http_destination.
        DATA: lr_web_http_client TYPE REF TO if_web_http_client.
        DATA: lr_request TYPE REF TO if_web_http_request.
        DATA: lr_response TYPE REF TO if_web_http_response.

        CLEAR: lt_header, l_body, l_url.

        DATA(l_etag) = getEtag( DeliveryDocument = DeliveryDocument-deliverydocument updateField = 'OD').
        IF l_etag IS INITIAL.
            lt_header = "Headers參數
                VALUE #(
                 ( name = 'Accept' value = 'application/json'  )
                 ( name = 'Content-Type' value = 'application/json'  ) "Content-Type：內容格式(Body的格式)，application/json：JSON格式
                 ( name = 'If-Match' value = '*'  ) ).
        ELSE.
            lt_header = "Headers參數
                VALUE #(
                 ( name = 'Accept' value = 'application/json'  )
                 ( name = 'Content-Type' value = 'application/json'  ) "Content-Type：內容格式(Body的格式)，application/json：JSON格式
                 ( name = 'If-Match' value = l_etag  ) ).
        ENDIF.

        l_body = `{"d":{"YY1_ODMES_STATUS_DLH":"` && DeliveryDocument-yy1_odmes_status_dlh && `"}}`. "Body參數 "YYYYYYYYY"

        l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=0002/A_OutbDeliveryHeader('` &&  DeliveryDocument-deliverydocument && `')`.

        CLEAR: l_status, l_text.
        FREE: lr_http_destination, lr_web_http_client, lr_request, lr_response.
        TRY.
            lr_http_destination = cl_http_destination_provider=>create_by_url( i_url = l_url ). "直接在程式碼中指定 URL 來呼叫 HTTP 或 SOAP 服務
        CATCH cx_http_dest_provider_error INTO DATA(lr_data).
        ENDTRY.
        IF lr_data IS INITIAL.
            TRY.
                lr_web_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lr_http_destination ).

                lr_request = lr_web_http_client->get_http_request( ).
                lr_request->set_authorization_basic( i_username = 'InnatechMIYABI2025TEST' i_password = 'Innatech@MIYABI2025TEST' ).
                lr_request->set_header_fields( i_fields = lt_header ).
                lr_request->set_text( i_text = l_body ).
                lr_web_http_client->set_csrf_token( ). "獲得TOKEN
                lr_response = lr_web_http_client->execute( i_method
                = if_web_http_client=>PATCH ).
                IF lr_response IS BOUND.
                    l_status = lr_response->get_status( ). "獲得執行結果狀態
                    l_text = lr_response->get_text( ). "獲得執行結果訊息
                ENDIF.
                DATA(lr_web_http_response) = lr_web_http_client->execute( if_web_http_client=>PATCH ).
                DATA(l_response) = lr_web_http_response->get_text( ).
                lr_web_http_client->close( ).
            CATCH cx_web_http_client_error INTO DATA(lr_data2).
            ENDTRY.
            IF ( l_status-code = 204 OR l_status-code = 200 ).

            ENDIF.
       ENDIF.
    ENDMETHOD.


    METHOD updateCRDField.
        DATA: l_url TYPE string.
        DATA: l_body TYPE string.
        DATA: lwa_header TYPE if_web_http_request=>name_value_pair,
              lt_header  TYPE if_web_http_request=>name_value_pairs.
        DATA: l_status TYPE if_web_http_response=>http_status .
        DATA: l_text TYPE string.
        DATA: lr_http_destination TYPE REF TO if_http_destination.
        DATA: lr_web_http_client TYPE REF TO if_web_http_client.
        DATA: lr_request TYPE REF TO if_web_http_request.
        DATA: lr_response TYPE REF TO if_web_http_response.


        CLEAR: lt_header, l_body, l_url.
        DATA(l_etag) = getEtag( DeliveryDocument = DeliveryDocument-deliverydocument updateField = 'CRD').
        IF l_etag IS INITIAL.
            lt_header = "Headers參數
                VALUE #(
                 ( name = 'Accept' value = 'application/json'  )
                 ( name = 'Content-Type' value = 'application/json'  ) "Content-Type：內容格式(Body的格式)，application/json：JSON格式
                 ( name = 'If-Match' value = '*'  ) ).
        ELSE.
            lt_header = "Headers參數
                VALUE #(
                 ( name = 'Accept' value = 'application/json'  )
                 ( name = 'Content-Type' value = 'application/json'  ) "Content-Type：內容格式(Body的格式)，application/json：JSON格式
                 ( name = 'If-Match' value = l_etag  ) ).
        ENDIF.

        l_body = `{"d":{"YY1_ODMES_STATUS_DLH":"` && DeliveryDocument-yy1_odmes_status_dlh && `"}}`. "Body參數 "YYYYYYYYY"

        l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_CUSTOMER_RETURNS_DELIVERY_SRV;v=0002/A_ReturnsDeliveryHeader('` && DeliveryDocument-deliverydocument && `')`.

        CLEAR: l_status, l_text.
        FREE: lr_http_destination, lr_web_http_client, lr_request, lr_response.
        TRY.
            lr_http_destination = cl_http_destination_provider=>create_by_url( i_url = l_url ). "直接在程式碼中指定 URL 來呼叫 HTTP 或 SOAP 服務
        CATCH cx_http_dest_provider_error INTO DATA(lr_data).
        ENDTRY.
        IF lr_data IS INITIAL.
            TRY.
                lr_web_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lr_http_destination ).

                lr_request = lr_web_http_client->get_http_request( ).
                lr_request->set_authorization_basic( i_username = 'InnatechMIYABI2025TEST' i_password = 'Innatech@MIYABI2025TEST' ).
                lr_request->set_header_fields( i_fields = lt_header ).
                lr_request->set_text( i_text = l_body ).
                lr_web_http_client->set_csrf_token( ). "獲得TOKEN
                lr_response = lr_web_http_client->execute( i_method
                = if_web_http_client=>PATCH ).
                IF lr_response IS BOUND.
                    l_status = lr_response->get_status( ). "獲得執行結果狀態
                    l_text = lr_response->get_text( ). "獲得執行結果訊息
                ENDIF.
                DATA(lr_web_http_response) = lr_web_http_client->execute( if_web_http_client=>PATCH ).
                DATA(l_response) = lr_web_http_response->get_text( ).
                lr_web_http_client->close( ).
            CATCH cx_web_http_client_error INTO DATA(lr_data2).
            ENDTRY.
            IF ( l_status-code = 204 OR l_status-code = 200 ).

            ENDIF.
       ENDIF.
    ENDMETHOD.

    METHOD getEtag.
        DATA: l_url TYPE string.
        DATA: l_etag  TYPE string.
        DATA: lwa_header TYPE if_web_http_request=>name_value_pair,
              lt_header  TYPE if_web_http_request=>name_value_pairs.
        DATA: l_status TYPE if_web_http_response=>http_status .
        DATA: l_text TYPE string.
        DATA: lr_http_destination TYPE REF TO if_http_destination.
        DATA: lr_web_http_client TYPE REF TO if_web_http_client.
        DATA: lr_request TYPE REF TO if_web_http_request.
        DATA: lr_response TYPE REF TO if_web_http_response.

        CLEAR: lt_header, l_url.
        lt_header = "Headers參數
            VALUE #(
             ( name = 'Accept' value = 'application/json'  )
             ( name = 'Content-Type' value = 'application/json'  ) "Content-Type：內容格式(Body的格式)，application/json：JSON格式
             ( name = 'If-Match' value = '*'  ) ).

        IF updateField = 'OD'.
            l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_OUTBOUND_DELIVERY_SRV;v=0002/A_OutbDeliveryHeader('` &&  DeliveryDocument && `')`.
        ELSEIF updateField = 'CRD'.
            l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_CUSTOMER_RETURNS_DELIVERY_SRV;v=0002/A_ReturnsDeliveryHeader('` && DeliveryDocument && `')`.
        ENDIF.

        CLEAR: l_status, l_text.
        FREE: lr_http_destination, lr_web_http_client, lr_request, lr_response.
        TRY.
            lr_http_destination = cl_http_destination_provider=>create_by_url( i_url = l_url ). "直接在程式碼中指定 URL 來呼叫 HTTP 或 SOAP 服務
        CATCH cx_http_dest_provider_error INTO DATA(lr_data).
        ENDTRY.
        IF lr_data IS INITIAL.
            TRY.
                lr_web_http_client = cl_web_http_client_manager=>create_by_http_destination( i_destination = lr_http_destination ).

                lr_request = lr_web_http_client->get_http_request( ).
                lr_request->set_authorization_basic( i_username = 'InnatechMIYABI2025TEST' i_password = 'Innatech@MIYABI2025TEST' ).
                lr_request->set_header_fields( i_fields = lt_header ).
                lr_web_http_client->set_csrf_token( ). "獲得TOKEN
                lr_response = lr_web_http_client->execute( i_method
                = if_web_http_client=>GET ).
                IF lr_response IS BOUND.
                    l_status = lr_response->get_status( ). "獲得執行結果狀態
                    l_text = lr_response->get_text( ). "獲得執行結果訊息
                ENDIF.
                DATA(lr_web_http_response) = lr_web_http_client->execute( if_web_http_client=>GET ).
                DATA(l_response) = lr_web_http_response->get_text( ).

                rv_result = lr_response->get_header_field( 'ETag' ).  " ← 拿到 ETag
                lr_web_http_client->close( ).
            CATCH cx_web_http_client_error INTO DATA(lr_data2).
            ENDTRY.
            IF ( l_status-code = 204 OR l_status-code = 200 ).

            ENDIF.
       ENDIF.

    ENDMETHOD.
ENDCLASS.
