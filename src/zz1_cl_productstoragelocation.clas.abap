CLASS zz1_cl_productstoragelocation DEFINITION
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



CLASS ZZ1_CL_PRODUCTSTORAGELOCATION IMPLEMENTATION.


    METHOD if_apj_dt_exec_object~get_parameters.

        " Return the supported selection parameters here
        et_parameter_def = VALUE #(
            ( selname = 'P_CLNT' kind = if_apj_dt_exec_object=>parameter datatype = 'C' length = 3 param_text =
            '環境' changeable_ind = abap_true )
        ).
    ENDMETHOD.


    METHOD if_apj_rt_exec_object~execute.
        "Execution logic when the job is started
        DATA: p_clnt TYPE c LENGTH 3,
              a(2).
        DATA: lwa_data TYPE ZZ1_I_PRODUCTSTORAGELOCATION,
              lt_data  LIKE STANDARD TABLE OF lwa_data.
        DATA: l_url TYPE string.
        DATA: l_password TYPE string,
              l_name TYPE string.
        DATA: l_auth(500).
        DATA: l_body TYPE string.
        DATA: lwa_header TYPE if_web_http_request=>name_value_pair,
              lt_header  TYPE if_web_http_request=>name_value_pairs.
        DATA: l_status TYPE if_web_http_response=>http_status .
        DATA: l_text TYPE string.
        DATA: lr_http_destination TYPE REF TO if_http_destination.
        DATA: lr_web_http_client TYPE REF TO if_web_http_client.
        DATA: lr_request TYPE REF TO if_web_http_request.
        DATA: lr_response TYPE REF TO if_web_http_response.

        DATA:l_text2(200).
        " Getting the actual parameter values(Just for show. Not needed for the logic below)
        LOOP AT it_parameters INTO DATA(ls_parameter).
            CASE ls_parameter-selname.
                WHEN 'P_CLNT'.
                    p_clnt = ls_parameter-low.
            ENDCASE.
        ENDLOOP.
        TRY.
            DATA(l_log) = cl_bali_log=>create_with_header( cl_bali_header_setter=>create( object =
                           'ZZ1_PROSLOCATION_LOG' subobject = 'ZZ1_PROSLOCATION' ) ).
        CATCH cx_bali_runtime.
            "handle exception
            a = 2.
        ENDTRY.


        SELECT *
          FROM ZZ1_I_PRODUCTSTORAGELOCATION
          INTO CORRESPONDING FIELDS OF TABLE @lt_data.

        IF lt_data IS INITIAL."沒資料
            DATA(l_success_text2) = cl_bali_free_text_setter=>create( severity =
                            if_bali_constants=>C_SEVERITY_STATUS "c_severity_error
                            text = '無可執行之資料' ).
            TRY.
              l_log->add_item( item = l_success_text2 ).
            CATCH cx_bali_runtime.
              a = 2.
            ENDTRY.
        ELSE. "call api
            LOOP AT lt_data INTO lwa_data.
                CLEAR: lt_header, l_body, l_url.
                l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_PRODUCT_SRV/A_ProductStorageLocation`.
                lt_header = "Headers參數
                    VALUE #(
                     ( name = 'Accept' value = 'application/json'  )
                     ( name = 'Content-Type' value = 'application/json'  )
                     ).


                l_body = `{"Product": "` && lwa_data-Product && `","Plant": "` && lwa_data-Plant && `","StorageLocation": "` && lwa_data-StorageLocation && `"}`.

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
                        = if_web_http_client=>POST ).
                        IF lr_response IS BOUND.
                            l_status = lr_response->get_status( ). "獲得執行結果狀態
                            l_text = lr_response->get_text( ). "獲得執行結果訊息
                        ENDIF.
*                        DATA(lr_web_http_response) = lr_web_http_client->execute( i_method = if_web_http_client=>PATCH ).
*                        DATA(l_response) = lr_web_http_response->get_text( ).
                        lr_web_http_client->close( ).
                    CATCH cx_web_http_client_error INTO DATA(lr_data2).
                    ENDTRY.

                    IF ( l_status-code = 201 OR l_status-code = 204 OR l_status-code = 200 ).
                        CONCATENATE '物料' lwa_data-Product '工廠' lwa_data-Plant '更新成功:' lwa_data-StorageLocation INTO l_text2.
                        l_success_text2 = cl_bali_free_text_setter=>create( severity =
                                if_bali_constants=>C_SEVERITY_STATUS "c_severity_error
                                text = l_text2 ).
                        IF l_log IS NOT INITIAL.
                            TRY.
                                l_log->add_item( item = l_success_text2 ).
                            CATCH cx_bali_runtime.
                                a = 2.
                            ENDTRY.
                        ENDIF.
                    ELSE.
                        CONCATENATE '物料' lwa_data-Product '工廠' lwa_data-Plant '更新失敗:' lwa_data-StorageLocation INTO l_text2.
                        l_success_text2 = cl_bali_free_text_setter=>create( severity =
                                if_bali_constants=>C_SEVERITY_ERROR "c_severity_error
                                text = l_text2 ).
                        IF l_log IS NOT INITIAL.
                            TRY.
                                l_log->add_item( item = l_success_text2 ).
                            CATCH cx_bali_runtime.
                                a = 2.
                            ENDTRY.
                        ENDIF.
                    ENDIF.
               ENDIF.

            ENDLOOP.
        ENDIF.

        IF l_log IS NOT INITIAL.
            TRY.
                cl_bali_log_db=>get_instance( )->save_log( log = l_log assign_to_current_appl_job = abap_true ).
            CATCH cx_bali_runtime.
                a = 2.
                "handle exception
            ENDTRY.
        ENDIF.

        COMMIT WORK.
    ENDMETHOD.


    METHOD if_oo_adt_classrun~main.
        "Execution logic when the job is started
        DATA: a(2).
        DATA: lwa_data TYPE ZZ1_I_PRODUCTSTORAGELOCATION,
              lt_data  LIKE STANDARD TABLE OF lwa_data.
        DATA: l_url TYPE string.
        DATA: l_password TYPE string,
              l_name TYPE string.
        DATA: l_auth(500).
        DATA: l_body TYPE string.
        DATA: lwa_header TYPE if_web_http_request=>name_value_pair,
              lt_header  TYPE if_web_http_request=>name_value_pairs.
        DATA: l_status TYPE if_web_http_response=>http_status .
        DATA: l_text TYPE string.
        DATA: lr_http_destination TYPE REF TO if_http_destination.
        DATA: lr_web_http_client TYPE REF TO if_web_http_client.
        DATA: lr_request TYPE REF TO if_web_http_request.
        DATA: lr_response TYPE REF TO if_web_http_response.

        DATA:l_text2(200).


        SELECT *
          FROM ZZ1_I_PRODUCTSTORAGELOCATION
          INTO CORRESPONDING FIELDS OF TABLE @lt_data.

        IF lt_data IS NOT INITIAL.
            LOOP AT lt_data INTO lwa_data.
                CLEAR: lt_header, l_body, l_url.
                l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_PRODUCT_SRV/A_ProductStorageLocation`.
                lt_header = "Headers參數
                    VALUE #(
                     ( name = 'Accept' value = 'application/json'  )
                     ( name = 'Content-Type' value = 'application/json'  )
                     ).


                l_body = `{"Product": "` && lwa_data-Product && `","Plant": "` && lwa_data-Plant && `","StorageLocation": "` && lwa_data-StorageLocation && `"}`.

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
                        = if_web_http_client=>POST ).
                        IF lr_response IS BOUND.
                            l_status = lr_response->get_status( ). "獲得執行結果狀態
                            l_text = lr_response->get_text( ). "獲得執行結果訊息
                        ENDIF.
*                        DATA(lr_web_http_response) = lr_web_http_client->execute( i_method = if_web_http_client=>PATCH ).
*                        DATA(l_response) = lr_web_http_response->get_text( ).
                        lr_web_http_client->close( ).
                    CATCH cx_web_http_client_error INTO DATA(lr_data2).
                    ENDTRY.

                    IF ( l_status-code = 201 OR l_status-code = 204 OR l_status-code = 200 ).
                        CONCATENATE '物料' lwa_data-Product '工廠' lwa_data-Plant '更新成功:' lwa_data-StorageLocation INTO l_text2.
                    ELSE.
                        CONCATENATE '物料' lwa_data-Product '工廠' lwa_data-Plant '更新失敗:' lwa_data-StorageLocation INTO l_text2.
                    ENDIF.
               ENDIF.

            ENDLOOP.
        ENDIF.

        COMMIT WORK.
    ENDMETHOD.
ENDCLASS.
