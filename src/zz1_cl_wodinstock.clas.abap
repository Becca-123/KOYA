CLASS zz1_cl_wodinstock DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
    INTERFACES if_apj_dt_exec_object.
    INTERFACES if_apj_rt_exec_object.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZZ1_CL_WODINSTOCK IMPLEMENTATION.


    METHOD if_apj_dt_exec_object~get_parameters.

        " Return the supported selection parameters here
        et_parameter_def = VALUE #(

          ( selname = 'P_CLNT' kind = if_apj_dt_exec_object=>parameter datatype = 'C' length = 3 param_text =
            '環境' changeable_ind = abap_true )"DEV QAS PRD
        ).
        et_parameter_def = VALUE #(
            ( selname = 'S_DATE' kind = if_apj_dt_exec_object=>select_option datatype = 'D' length = 8 param_text =
            '日期' changeable_ind = abap_true )
            ( selname = 'P_ENFORCE' kind = if_apj_dt_exec_object=>parameter datatype = 'C' length = 1 param_text =
            '強制執行' changeable_ind = abap_true )
        ).

        " Return the default parameters values here
        et_parameter_val = VALUE #(
          ( selname = 'S_DATE' kind = if_apj_dt_exec_object=>select_option sign = 'I' option = 'BT' low = cl_abap_context_info=>get_system_date( )  high = cl_abap_context_info=>get_system_date( ) )
         ).

    ENDMETHOD.


    METHOD if_apj_rt_exec_object~execute.
        "Execution logic when the job is started
        DATA: p_clnt TYPE c LENGTH 3,
              p_enforce TYPE c LENGTH 1.
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
        DATA: lwa_data TYPE ZZ1_I_WODINSTOCK,
              lt_data  TYPE STANDARD TABLE OF ZZ1_I_WODINSTOCK,
              lwa_item TYPE ZZ1_I_WODINSTOCK,
              lt_item  TYPE STANDARD TABLE OF ZZ1_I_WODINSTOCK,
              lwa_data2 TYPE ZZ1_I_WODINSTOCK,
              lwa_log TYPE zz1_wodins_log,
              lt_log TYPE STANDARD TABLE OF zz1_wodins_log,
              lwa_meslog TYPE zz1_wodins_log,
              lt_meslog TYPE STANDARD TABLE OF zz1_wodins_log,
              l_user TYPE zz1_wodins_log-ernam,
              l_serialno TYPE zz1_wodins_log-serial_no ,
              l_date TYPE zz1_wodins_log-erdat,
              l_time TYPE zz1_wodins_log-erfzeit,
              l_check(1).

        DATA: BEGIN OF lwa_wo,
                ITEM             TYPE c LENGTH 30,
                WAREHOUSE_NO     TYPE c LENGTH 25,
                ITEM_PART_NO     TYPE c LENGTH 30,
                QTY              TYPE C LENGTH 22,
                UNIT             TYPE C LENGTH 10,
                FACTORY_NAME     TYPE c LENGTH 20,
                MoveType         TYPE c LENGTH 4,
                Data_Status      TYPE c LENGTH 1,
              END OF lwa_wo,
              WODetails LIKE STANDARD TABLE OF lwa_wo.

        DATA: BEGIN OF lwa_req,
                WORK_ORDER       TYPE c LENGTH 25,
                PART_NO          TYPE c LENGTH 30,
                WOType           TYPE c LENGTH 10,
                FACTORY_NAME     TYPE c LENGTH 20,
                status           TYPE c LENGTH 10,
                REMARK           TYPE c LENGTH 100,
                WODetails        LIKE WODetails,
              END OF lwa_req.

        DATA: BEGIN OF lwa_mc106,
            Product TYPE I_Product-Product,
            CharcValue  TYPE ZZ1_I_ObjectCharacteristics-CharcValue,
        END OF lwa_mc106,
        lt_mc106 LIKE STANDARD TABLE OF lwa_mc106.

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
                WHEN 'P_ENFORCE'.
                    p_enforce = ls_parameter-low.
            ENDCASE.
        ENDLOOP.
        try.
            data(l_log) = cl_bali_log=>create_with_header( cl_bali_header_setter=>create( object =
                           'zz1_wodins_log' subobject = 'ZZ1_WODINSTOCK' ) ).
        catch cx_bali_runtime.
            "handle exception
            a = 2.
        ENDTRY.

        "若是有強制傳輸參數，則不需比對log檔，傳過的資料則不在傳輸
        IF p_enforce = 'X'.
            SELECT * FROM  ZZ1_I_WODINSTOCK
                WHERE PostingDate IN @s_date
                INTO CORRESPONDING FIELDS OF TABLE @lt_item.
        ELSE.
            "若是最新的log資料是Error，則資料還是需要傳輸
            SELECT *
                FROM  ZZ1_I_WODINSTOCK AS m
                WHERE PostingDate IN @s_date
                 AND NOT EXISTS (
                        SELECT 1
                        FROM zz1_wodins_log as a
                        WHERE m~work_order = a~work_order AND m~Reservation = a~reservation
                          AND m~ReservationItem = a~reservation_item AND m~MaterialDocumentYear = a~materialdocumentyear
                          AND m~MaterialDocument = a~materialdocument AND m~MaterialDocumentItem = a~materialdocumentitem
                          AND a~status = 'Success' AND a~PostingDate IN @s_date
                          AND a~serial_no = (
                                 SELECT MAX( b~serial_no )
                                   FROM zz1_wodins_log AS b
                                  WHERE b~work_order           = a~work_order
                                    AND b~reservation          = a~reservation
                                    AND b~reservation_item     = a~reservation_item
                                    AND b~materialdocumentyear = a~materialdocumentyear
                                    AND b~materialdocument     = a~materialdocument
                                    AND b~materialdocumentitem = a~materialdocumentitem
                                    AND b~PostingDate IN @s_date
                             )
                     )
                INTO CORRESPONDING FIELDS OF TABLE @lt_item.
        ENDIF.

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

            CLEAR: lwa_mc106, lt_mc106[].
            SELECT a~Product, b~CharcValue
              FROM I_Product AS a
              JOIN ZZ1_I_ObjectCharacteristics AS b ON  a~Product = b~material
                                                    AND b~Class          = 'Z_MATERIAL_CL01'
                                                    AND b~Characteristic = 'Z_MY_MC_106'
              WHERE b~CharcValue = '3'
            INTO CORRESPONDING FIELDS OF TABLE @lt_mc106.
            SORT lt_mc106 BY Product.

            MOVE-CORRESPONDING lt_item[] TO lt_data[].
            SORT lt_data BY work_order.
            DELETE ADJACENT DUPLICATES FROM lt_data COMPARING work_order.

            LOOP AT lt_data INTO lwa_data.
                clear : lwa_req.
                lwa_req-work_order = lwa_data-work_order.
                lwa_req-part_no = lwa_data-part_no.
                lwa_req-wotype = lwa_data-WOType.
                lwa_req-factory_name = lwa_data-factory_name.

                CLEAR WODetails[].
                LOOP AT lt_item INTO lwa_item WHERE work_order = lwa_data-work_order.
                    CLEAR lwa_mc106.
                    READ TABLE lt_mc106 INTO lwa_mc106 BINARY SEARCH WITH KEY Product = lwa_item-item_part_no.
                    IF sy-subrc = 0.
                        DELETE lt_item.
                        CONTINUE.
                    ENDIF.

                    CLEAR lwa_wo.
                    lwa_wo-item = lwa_item-Item.
                    lwa_wo-warehouse_no = lwa_data-warehouse_no.
                    lwa_wo-item_part_no = lwa_data-item_part_no.
                    lwa_wo-qty = lwa_data-qty.
                    lwa_wo-unit = lwa_data-unit.
                    lwa_wo-factory_name = lwa_data-factory_name_it.
                    lwa_wo-movetype = lwa_data-MoveType.
                    lwa_wo-data_status = '1'.
                    APPEND lwa_wo TO WODetails.
                ENDLOOP.
                IF WODetails[] IS NOT INITIAL.
                    lwa_req-wodetails = WODetails.
                ENDIF.

                "將資料轉成JSON
                l_body = /ui2/cl_json=>serialize( data = lwa_req pretty_name = /ui2/cl_json=>pretty_mode-low_case ).
                REPLACE ALL OCCURRENCES OF:
                'WOTYPE' IN l_body WITH 'WOType',
                'STATUS' IN l_body WITH 'status',
                'ITEM' IN l_body WITH 'Item',
                'MOVETYPE' IN l_body WITH 'MoveType',
                'DATA_STATUS' IN l_body WITH 'Data_Status'.

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

                    CLEAR: l_user, l_date, l_time, lwa_log.
                    lwa_log-work_order = lwa_req-work_order.
                    lwa_log-part_no = lwa_req-part_no.
                    lwa_log-wotype = lwa_req-wotype.
                    lwa_log-factory_name = lwa_req-factory_name.

                    l_user = sy-uname.
                    l_date = sy-datum.
                    l_time = sy-uzeit.
                    lwa_log-ernam  = l_user.
                    lwa_log-erdat  = l_date.
                    lwa_log-erfzeit = l_time.
                    IF ( l_status-code = 204 OR l_status-code = 200 ).
                        lwa_log-status = 'SUCCESS'.
                        CONCATENATE '已傳送拆解工單入庫資料:' lwa_data-work_order INTO l_text2.
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
                        lwa_log-message = l_text.
                        CONCATENATE '拆解工單入庫資料傳送失敗:' lwa_data-work_order INTO l_text2.
                        l_success_text2 = cl_bali_free_text_setter=>create( severity =
                                if_bali_constants=>C_SEVERITY_ERROR "c_severity_error
                                text = l_text2 ).
                        TRY.
                            l_log->add_item( item = l_success_text2 ).
                        CATCH cx_bali_runtime.
                            a = 2.
                        ENDTRY.
                    ENDIF.



                    LOOP AT lt_item INTO lwa_item WHERE work_order = lwa_data-work_order.
                        CLEAR: l_serialno.
                        lwa_log-objectid = lwa_data-work_order && lwa_data-reservation && lwa_data-reservationitem && lwa_data-materialdocumentyear
                                            && lwa_data-MaterialDocument && lwa_data-MaterialDocumentItem.
                        SELECT SINGLE MAX( serial_no ) FROM zz1_wodins_log
                          WHERE objectid = @lwa_log-objectid
                          INTO @lwa_log-serial_no.
                        lwa_log-serial_no = l_serialno + 1 .
                        lwa_log-item = lwa_item-Item.
                        lwa_log-warehouse_no = lwa_item-warehouse_no.
                        lwa_log-item_part_no = lwa_item-item_part_no.
                        lwa_log-qty = lwa_item-qty.
                        lwa_log-unit = lwa_item-unit.
                        lwa_log-factory_name_it = lwa_item-factory_name_it.
                        lwa_log-MoveType = lwa_item-movetype.
                        lwa_log-Reservation = lwa_item-reservation.
                        lwa_log-reservation_item = lwa_item-reservationitem.
                        lwa_log-materialdocumentyear = lwa_item-MaterialDocumentYear.
                        lwa_log-materialdocument = lwa_item-MaterialDocument.
                        lwa_log-materialdocumentitem = lwa_item-MaterialDocumentItem.
                        lwa_log-postingdate = lwa_item-PostingDate.
                        lwa_log-data_status = lwa_item-data_status.
                        APPEND lwa_log TO lt_log.
                    ENDLOOP.

               ENDIF.
            ENDLOOP.
            IF lt_log[] IS NOT INITIAL.
                MODIFY zz1_wodins_log FROM TABLE @lt_log.
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
ENDCLASS.
