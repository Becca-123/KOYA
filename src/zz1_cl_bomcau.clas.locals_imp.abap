*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
CLASS lhc_zz1_i_bomcau DEFINITION INHERITING FROM cl_abap_behavior_handler.
    PUBLIC SECTION.
        DATA t_del TYPE TABLE FOR UPDATE zz1_i_bomcau.
        DATA wa_del LIKE LINE OF t_del.
        DATA t_del2 TYPE STANDARD TABLE OF zz1_i_bomcau.
        DATA:w_check(1).
*        DATA: l_pass TYPE string VALUE 'Innatech@MIYABI2025TEST',
*              w_clientd(3) VALUE 'N8M',
*              w_clientt(3) VALUE 'N8X',
*              w_clientp(3) VALUE 'PHK'.

        DATA: w_etag TYPE string.
        DATA: BEGIN OF wa_BillOfMaterial,
                BillOfMaterial TYPE I_BillOfMaterialHeaderDEX_2-BillOfMaterial,
                BillOfMaterialCategory TYPE I_BillOfMaterialHeaderDEX_2-BillOfMaterialCategory,
                BillOfMaterialVariant TYPE I_BillOfMaterialHeaderDEX_2-BillOfMaterialVariant,
                Material TYPE I_MaterialBOMLink-Material,
                Plant TYPE I_BillOfMaterialHeaderDEX_2-BOMOrBOMAltvCrtedInPlnt,
              END OF wa_BillOfMaterial.
        DATA: BEGIN OF wa_bomcau.
                INCLUDE TYPE zz1_i_bomcau.
        DATA:   jsondate TYPE string,
                BillOfMaterialItemNodeNumber TYPE I_BillOfMaterialItemBasic-BillOfMaterialItemNodeNumber,
              END OF wa_bomcau,
              t_bomcau LIKE STANDARD TABLE OF wa_bomcau.

        METHODS: getEtag
          IMPORTING BillOfMaterial LIKE wa_BillOfMaterial
          RETURNING VALUE(rv_result) TYPE string.

        METHODS: CreateBom
          IMPORTING bomcau LIKE wa_bomcau
                    t_bomcau LIKE t_bomcau
          EXPORTING message TYPE string
          RETURNING VALUE(rv_result) TYPE string.

        METHODS: DeleteBom
          IMPORTING t_bomcau LIKE t_bomcau
                    billofmaterial TYPE zz1_i_bomcau-billofmaterial
                    billofmaterialvariant TYPE zz1_i_bomcau-billofmaterialvariant
                    material TYPE zz1_i_bomcau-material
                    plant TYPE zz1_i_bomcau-plant
                    billofmaterialvariantusage TYPE zz1_i_bomcau-billofmaterialvariantusage
          EXPORTING message TYPE string
          RETURNING VALUE(rv_result) TYPE string.

        CLASS-METHODS date_to_sap_json
          IMPORTING
            iv_date_time TYPE string " e.g. '2025-10-08 09:00:00'
          RETURNING
            VALUE(rv_sap_date) TYPE string.

        CLASS-METHODS XmlToJson
          IMPORTING
            iv_xml TYPE string
          RETURNING
            VALUE(rv_json) TYPE string.

    PRIVATE SECTION.
        METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
          IMPORTING REQUEST requested_authorizations FOR zz1_i_bomcau RESULT result.

        METHODS update FOR DETERMINE ON SAVE
          IMPORTING keys FOR zz1_i_bomcau~update
          CHANGING reported TYPE data.

        METHODS bomcau_validation FOR VALIDATE ON SAVE
          IMPORTING keys FOR zz1_i_bomcau~bomcau_validation.
ENDCLASS.

CLASS lhc_zz1_i_bomcau IMPLEMENTATION.
    METHOD get_global_authorizations.
    ENDMETHOD.

    METHOD update .
        DATA: l_password TYPE string ,
              l_name TYPE string.
        DATA: l_auth(500).
        DATA: l_body TYPE string.
        DATA: lr_http_destination TYPE REF TO if_http_destination.
        DATA: lr_web_http_client TYPE REF TO if_web_http_client.
        DATA: lr_request TYPE REF TO if_web_http_request.
        DATA: lr_response TYPE REF TO if_web_http_response.

*        DATA: BEGIN OF lwa_message,
*                Lang(100),
*                value(200),
*              END OF lwa_message.
*        DATA: BEGIN OF lwa_code,
*                code(70),
*                message LIKE lwa_message,
*              END OF lwa_code.
*        DATA: BEGIN OF lwa_res, "RESPONSE DATA
*                  BEGIN OF error,
*                    code(70),
*                    message LIKE lwa_message,
*                  END OF error,
*              END OF lwa_res.
        DATA: l_url TYPE string.
        DATA: lwa_header TYPE if_web_http_request=>name_value_pair,
              lt_header  TYPE if_web_http_request=>name_value_pairs.
        DATA: l_status TYPE if_web_http_response=>http_status .
        DATA: l_text TYPE string.
        DATA :BEGIN OF lwa_data,
                  billofmaterial(8),
                  material(40),
                  plant(4),
                  billofmaterialvariantusage(1),
                  billofmaterialstatus(2),
                  billofmaterialvariant(2),
                  validitystartdate(8),
                  bomheaderquantityinbaseunit(13),
                  bomheaderbaseunit(3),
                  billofmaterialitemnumber(4),
                  billofmaterialitemcategory(1),
                  billofmaterialcomponent(40),
                  bomitemdescription(40),
                  billofmaterialitemquantity(13),
                  billofmaterialitemunit(3),
                  prodorderissuelocation(4),
                  alternativeitemgroup(2),
                  alternativeitempriority(2),
                  alternativeitemstrategy(1),
                  usageprobabilitypercent(3),
                  fixedquantity(4),
              END OF lwa_data,
              BEGIN OF wa_data4,
                  value TYPE c LENGTH 500,
              END OF wa_Data4,
              BEGIN OF wa_data3,
                  code TYPE c LENGTH 500,
                  message LIKE wa_data4,
              END OF wa_data3,
              BEGIN OF lwa_res_err,
                  error Like wa_data3,
              END OF lwa_res_err.
        DATA : l_flag1(1),
               l_flag2(2).
        DATA lt_bomcau TYPE TABLE FOR UPDATE zz1_i_bomcau.
        DATA lt_bomcau2 LIKE STANDARD TABLE OF lt_bomcau.
        DATA lwa_bomcau TYPE STRUCTURE FOR UPDATE zz1_i_bomcau.
        DATA lwa_bomcau2 LIKE  lwa_bomcau.

        DATA:lwa_bomcauH LIKE wa_bomcau,
             lwa_bomcauI LIKE wa_bomcau,
             lt_bomcauI LIKE STANDARD TABLE OF lwa_bomcauI,
             lwa_bomcauS LIKE wa_bomcau,
             lt_bomcauS LIKE STANDARD TABLE OF lwa_bomcauS.

        DATA: lwa_mes  TYPE STRUCTURE FOR REPORTED LATE zz1_i_bomcau.
        DATA: lwa_mast TYPE I_MaterialBOMLink,
              lt_mast LIKE STANDARD TABLE OF lwa_mast.
        DATA: lt_del TYPE STANDARD TABLE OF zz1_i_bomcau,
              lwa_del TYPE zz1_i_bomcau,
              lt_result2 TYPE TABLE OF zz1_i_bomcau,
              lwa_result2 TYPE  zz1_i_bomcau,
              l_kpein TYPE P LENGTH 5 DECIMALS 0 VALUE 1,
              a(1).
        DATA: lwa_BillOfMaterial LIKE wa_BillOfMaterial,
              lwa_Product TYPE I_Product,
              lt_Product TYPE STANDARD TABLE OF I_Product,
              lt_bomheader TYPE STANDARD TABLE OF zz1_i_bomcau,
              BEGIN OF lwa_tmp,
                material TYPE I_MaterialBOMLink-material,
                plant TYPE I_MaterialBOMLink-plant,
                billofmaterialvariantusage  TYPE I_MaterialBOMLink-billofmaterialvariantusage,
                billofmaterialvariant TYPE I_MaterialBOMLink-billofmaterialvariant,
              END OF lwa_tmp,
              lt_tmp LIKE STANDARD TABLE OF lwa_tmp.

        DATA: l_validitystartdate TYPE string,
              l_return TYPE string,
              l_returnS TYPE string,
              l_message TYPE string,
              l_tmp TYPE  string,
              l_item(4),
              l_subitem(4).

        DATA: l_uuid TYPE sysuuid_x16.



        SELECT * FROM zz1_i_bomcau
            WHERE billofmaterial IS NOT INITIAL
            INTO CORRESPONDING FIELDS OF TABLE @lt_del.

        MODIFY ENTITIES OF zz1_i_bomcau IN LOCAL MODE
            ENTITY zz1_i_bomcau
            DELETE FROM VALUE #( ( bomcau_uuid = space  ) ).

        LOOP AT lt_del INTO lwa_del.
            CLEAR l_uuid.
            DO 5 TIMES.
                " 產生一個新的 UUID (16-byte RAW)
                TRY.
                    CALL METHOD cl_system_uuid=>create_uuid_x16_static
                      RECEIVING
                        uuid = l_uuid.

                  CATCH cx_uuid_error INTO DATA(lx_uuid).
                ENDTRY.
                IF l_uuid IS NOT INITIAL.
                    EXIT.
                ENDIF.
            ENDDO.


            IF l_uuid IS NOT INITIAL.
                MODIFY ENTITIES OF zz1_i_bomcau IN LOCAL MODE
                  ENTITY zz1_i_bomcau
                  DELETE FROM VALUE #( ( bomcau_uuid = l_uuid ) ).
            ENDIF.
        ENDLOOP.


        "讀取EXCEL資料
        READ ENTITIES OF zz1_i_bomcau IN LOCAL MODE
            ENTITY zz1_i_bomcau
            ALL FIELDS WITH CORRESPONDING #( keys )
            RESULT DATA(lt_result)
            FAILED DATA(lt_failed)
            REPORTED DATA(lt_reported).

        MOVE-CORRESPONDING lt_result[] TO lt_bomheader[].
        SORT lt_bomheader BY material plant billofmaterialvariantusage billofmaterialvariant.
        DELETE ADJACENT DUPLICATES FROM lt_bomheader COMPARING material plant billofmaterialvariantusage billofmaterialvariant.

        MOVE-CORRESPONDING lt_bomheader[] TO lt_tmp[].
        SORT lt_tmp BY material plant billofmaterialvariantusage billofmaterialvariant.

        IF lt_tmp[] IS NOT INITIAL.
            SELECT Product, BaseUnit
              FROM I_Product WITH PRIVILEGED ACCESS
              FOR ALL ENTRIES IN @lt_tmp
              WHERE ( Product = @lt_tmp-material )
                INTO CORRESPONDING FIELDS OF TABLE @lt_Product.
            SORT lt_Product BY Product.

            SELECT *
                FROM I_MaterialBOMLink WITH PRIVILEGED ACCESS
                FOR ALL ENTRIES IN @lt_tmp
                WHERE ( material = @lt_tmp-material AND plant = @lt_tmp-plant
                  AND billofmaterialvariantusage = @lt_tmp-billofmaterialvariantusage
                  AND billofmaterialvariant = @lt_tmp-billofmaterialvariant )
                INTO CORRESPONDING FIELDS OF TABLE @lt_mast.
            SORT lt_mast BY material plant billofmaterialvariantusage billofmaterialvariant.
        ENDIF.

        CLEAR : reported.
        LOOP AT lt_bomheader INTO DATA(lwa_bomheader).
            CLEAR: lwa_bomcauH, lwa_bomcauI, lt_bomcauI, lwa_bomcauS, lt_bomcauS, l_flag1, l_flag2.
            lwa_bomcauH = CORRESPONDING #( lwa_bomheader ).

            IF lwa_bomheader-plant IS INITIAL.
                l_flag1 = 'X'.
            ENDIF.
            CLEAR: l_validitystartdate.
            IF lwa_bomheader-validitystartdate IS NOT INITIAL.
                CONCATENATE lwa_bomheader-validitystartdate(4) lwa_bomheader-validitystartdate+4(2) lwa_bomheader-validitystartdate+6(2) '000000' INTO l_validitystartdate.
            ELSE.
                l_flag1 = 'X'.
            ENDIF.

            IF l_validitystartdate IS NOT INITIAL.
                lwa_bomcauH-jsondate = date_to_sap_json( IV_DATE_TIME = l_validitystartdate ).
            ENDIF.

            IF l_flag1 IS INITIAL.
                LOOP AT lt_result INTO DATA(lwa_result) WHERE material = lwa_bomheader-material AND
                                                              plant  = lwa_bomheader-plant AND
                                                              billofmaterialvariantusage = lwa_bomheader-billofmaterialvariantusage AND
                                                              billofmaterialvariant = lwa_bomheader-billofmaterialvariant.
                    CLEAR : lwa_data, lwa_bomcau, l_item, l_subitem.
                    lwa_bomcauI = CORRESPONDING #( lwa_result ).
                    lwa_bomcauI-insert_date = syst-datlo.
                    lwa_bomcauI-insert_time = syst-timlo.
                    lwa_bomcauI-insert_user = sy-uname.
                    l_item = lwa_bomcauI-billofmaterialitemnumber.
                    l_item = |{ l_item ALPHA = IN }|.
                    lwa_bomcauI-billofmaterialitemnumber = l_item.
                    IF lwa_bomcauI-bomsubitemnumbervalue IS NOT INITIAL.
                        l_subitem = lwa_bomcauI-bomsubitemnumbervalue.
                        l_subitem = |{ l_subitem ALPHA = IN }|.
                        lwa_bomcauI-bomsubitemnumbervalue = l_subitem.
                    ENDIF.


                    APPEND lwa_bomcauI TO lt_bomcauI[].


*        *        IF  sy-sysid = w_clientd.
*        *            l_headurl = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002/MaterialBOM`.
*        *            l_patchurl = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002/MaterialBOM`.
*        *        ELSEIF sy-sysid = w_clientt.
*        *
*        *        ELSEIF sy-sysid = w_clientp.
*        *
*        *        ENDIF.

                ENDLOOP.


                "CALL API
                CLEAR: lwa_mast, lwa_BillOfMaterial, w_etag, l_return.
                lwa_BillOfMaterial-billofmaterialcategory = 'M'.
                lwa_BillOfMaterial-material = lwa_result-material.
                lwa_BillOfMaterial-plant = lwa_result-plant.
                lwa_BillOfMaterial-billofmaterialvariant = lwa_result-billofmaterialvariant.
                READ TABLE lt_mast INTO lwa_mast BINARY SEARCH WITH KEY material = lwa_result-material
                                                                        plant = lwa_result-plant
                                                                        billofmaterialvariantusage = lwa_result-billofmaterialvariantusage
                                                                        billofmaterialvariant = lwa_result-billofmaterialvariant.
                IF sy-subrc <> 0.
                    w_etag = getEtag( BillOfMaterial = lwa_BillOfMaterial ).
                    CLEAR lwa_Product.
                    READ TABLE lt_Product INTO lwa_Product BINARY SEARCH WITH KEY Product = lwa_result-material.
                    IF sy-subrc = 0.
                        lwa_bomcauH-bomheaderbaseunit = lwa_Product-BaseUnit.
                    ENDIF.

                    l_return = CreateBOM( EXPORTING bomcau = lwa_bomcauH
                                                    t_bomcau = lt_bomcauI
                                          IMPORTING message = l_message ).
                ELSE.
                    lwa_BillOfMaterial-billofmaterial = lwa_mast-BillOfMaterial.
                    w_etag = getEtag( BillOfMaterial = lwa_BillOfMaterial ).
                    l_return = DeleteBOM( EXPORTING t_bomcau = lt_bomcauI
                                                    billofmaterial = lwa_mast-BillOfMaterial
                                                    billofmaterialvariant = lwa_result-billofmaterialvariant
                                                    material = lwa_result-material
                                                    plant = lwa_result-plant
                                                    billofmaterialvariantusage = lwa_result-billofmaterialvariantusage
                                          IMPORTING message = l_message ).
                ENDIF.


                LOOP AT lt_bomcauI INTO lwa_bomcauI.
                    CLEAR : lwa_data, lwa_bomcau.
                    lwa_bomcau = CORRESPONDING #( lwa_bomcauI ).
                    lwa_bomcau-insert_date = syst-datlo.
                    lwa_bomcau-insert_time = syst-timlo.
                    lwa_bomcau-insert_user = sy-uname.
                    lwa_bomcau-status = l_return.

                    CLEAR :  lwa_res_err , lwa_bomcau2-msg, l_text.
                    l_text = l_message.
                    IF l_return = 'ERROR'.
                        lwa_bomcau-status = l_return.
                        CLEAR :  lwa_res_err , lwa_bomcau2-msg.
                        /ui2/cl_json=>deserialize( "將資料按照Json格式解譯放入ITAB
                            EXPORTING
                              json        =  l_text
                              pretty_name = /ui2/cl_json=>pretty_mode-low_case
                            CHANGING
                              data        = lwa_res_err ).
                        lwa_bomcau2-msg = lwa_res_err-error-message-value.
                        lwa_mes-%msg = new_message_with_text( severity =  if_abap_behv_message=>severity-error text = lwa_bomcau2-msg ).
                        lwa_bomcau-msg = lwa_res_err-error-message-value.
                        APPEND lwa_mes TO reported-zz1_i_bomcau.
                        APPEND lwa_bomcau TO lt_bomcau.
                    ELSEIF l_return = 'SUCCESS'.
                        CLEAR : l_text.
                        CONCATENATE '物料:' lwa_bomcauI-material '工廠:' lwa_bomcauI-plant 'BOM使用:' lwa_bomcauI-billofmaterialvariantusage '替代BOM:' lwa_bomcauI-billofmaterialvariant '已建立BOM' INTO l_text.
                        lwa_mes-%msg = new_message_with_text( severity =  if_abap_behv_message=>severity-success text = l_text ).
                        lwa_bomcau-msg = '已成功建立'.
                        APPEND lwa_mes TO reported-zz1_i_bomcau.
                        APPEND lwa_bomcau TO lt_bomcau.
                    ENDIF.
                ENDLOOP.

            ELSE.
                LOOP AT lt_result INTO DATA(lwa_result3) WHERE material = lwa_bomheader-material AND
                                                               plant  = lwa_bomheader-plant AND
                                                               billofmaterialvariantusage = lwa_bomheader-billofmaterialvariantusage AND
                                                               billofmaterialvariant = lwa_bomheader-billofmaterialvariant.
                        CLEAR : lwa_data, lwa_bomcau.
                        lwa_bomcau = CORRESPONDING #( lwa_result3 ).
                        lwa_bomcau-insert_date = syst-datlo.
                        lwa_bomcau-insert_time = syst-timlo.
                        lwa_bomcau-insert_user = sy-uname.

                        CLEAR :  lwa_res_err , lwa_bomcau2-msg.
                        l_text = '工廠及有效日期不可空白'.
                        /ui2/cl_json=>deserialize( "將資料按照Json格式解譯放入ITAB
                            EXPORTING
                              json        =  l_text
                              pretty_name = /ui2/cl_json=>pretty_mode-low_case
                            CHANGING
                              data        = lwa_res_err ).
                              lwa_bomcau2-msg = lwa_res_err-error-message-value.
                        lwa_mes-%msg = new_message_with_text( severity =  if_abap_behv_message=>severity-error text = lwa_bomcau2-msg ).
                        lwa_bomcau-msg = lwa_res_err-error-message-value.
                        APPEND lwa_mes TO reported-zz1_i_bomcau.
                        APPEND lwa_bomcau TO lt_bomcau.
                ENDLOOP.
            ENDIF.
        ENDLOOP.

        MODIFY ENTITIES OF zz1_i_bomcau IN LOCAL MODE
        ENTITY zz1_i_bomcau UPDATE SET FIELDS WITH lt_bomcau
        MAPPED DATA(lt_mapp_mod)
        REPORTED DATA(report_mod)
        FAILED DATA(failed_mod).
    ENDMETHOD.

    METHOD bomcau_validation.
    ENDMETHOD.

    METHOD getEtag.
        DATA: l_url TYPE string.
        DATA: w_etag  TYPE string.
        DATA: lwa_header TYPE if_web_http_request=>name_value_pair,
              lt_header  TYPE if_web_http_request=>name_value_pairs.
        DATA: l_status TYPE if_web_http_response=>http_status .
        DATA: l_text TYPE string.
        DATA: lr_http_destination TYPE REF TO if_http_destination.
        DATA: lr_web_http_client TYPE REF TO if_web_http_client.
        DATA: lr_request TYPE REF TO if_web_http_request.
        DATA: lr_response TYPE REF TO if_web_http_response.
        DATA: l_flag(1).

        CLEAR: lt_header, l_url, l_flag.
        lt_header = "Headers參數
            VALUE #(
             ( name = 'Accept' value = 'application/json'  )
             ( name = 'Content-Type' value = 'application/json'  ) "Content-Type：內容格式(Body的格式)，application/json：JSON格式
             ( name = 'If-Match' value = '*'  ) ).

        IF BillOfMaterial-billofmaterial IS NOT INITIAL.
            l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002/MaterialBOM(BillOfMaterial='` && BillOfMaterial-billofmaterial && `',`.
            l_url = l_url && `BillOfMaterialCategory='M',`.
            l_url = l_url && `BillOfMaterialVariant='` &&  BillOfMaterial-billofmaterialvariant && `',`.
            l_url = l_url && `BillOfMaterialVersion='',`.
            l_url = l_url && `EngineeringChangeDocument='',`.
            l_url = l_url && `Material='` &&  BillOfMaterial-material && `',Plant='` &&  BillOfMaterial-plant && `')`.
        ELSE.
            l_flag = 'X'.
            l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002/MaterialBOM`.
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

                IF l_flag IS INITIAL.
                    rv_result = lr_response->get_header_field( 'ETag' ).  " ← 拿到 ETag
                ENDIF.
                lr_web_http_client->close( ).
            CATCH cx_web_http_client_error INTO DATA(lr_data2).
            ENDTRY.
            IF ( l_status-code = 204 OR l_status-code = 200 ).
                IF l_flag IS NOT INITIAL.
                    FIND REGEX '"etag"\s*:\s*"((?:\\.|[^"])*)"'  IN l_text SUBMATCHES rv_result.
                ENDIF.
            ENDIF.
        ENDIF.

    ENDMETHOD.

    METHOD CreateBom.
        DATA: l_url TYPE string.
        DATA: l_password TYPE string ,
              l_name TYPE string,
              l_lines TYPE i,
              l_index TYPE i,
              l_first(1),
              l_error(1).
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
        DATA: lwa_bomcau LIKE wa_bomcau,
              lwa_bomcauI LIKE wa_bomcau,
              lt_bomcauI LIKE STANDARD TABLE OF lwa_bomcauI,
              lwa_bomcauS LIKE wa_bomcau,
              lt_bomcauS LIKE STANDARD TABLE OF lwa_bomcauS,
              lwa_BillOfMaterial LIKE wa_BillOfMaterial.
        DATA: BEGIN OF lwa_mast,
                BillOfMaterial TYPE I_BillOfMaterialItemBasic-BillOfMaterial,
                Material TYPE I_MaterialBOMLink-Material,
                Plant TYPE I_MaterialBOMLink-Plant,
                BillOfMaterialVariantUsage TYPE I_MaterialBOMLink-BillOfMaterialVariantUsage,
                BillOfMaterialVariant TYPE I_MaterialBOMLink-BillOfMaterialVariant,
                BillOfMaterialItemNodeNumber TYPE I_BillOfMaterialItemBasic-BillOfMaterialItemNodeNumber,
                BillOfMaterialItemNumber TYPE I_BillOfMaterialItemBasic-BillOfMaterialItemNumber,
                BillOfMaterialItemUnit TYPE I_BillOfMaterialItemBasic-BillOfMaterialItemUnit,
              END OF lwa_mast,
              lt_mast LIKE STANDARD TABLE OF lwa_mast.

        CLEAR: lt_header, l_body, l_url, rv_result, message, l_lines, l_index, lt_bomcauS, lwa_bomcauS, lt_bomcauI, lwa_bomcauI, l_error.
        MOVE-CORRESPONDING t_bomcau[] TO lt_bomcauS[].
        DELETE lt_bomcauS WHERE ( bomsubitemnumbervalue IS INITIAL AND bomsubiteminstallationpoint IS INITIAL AND billofmaterialsubitemquantity IS INITIAL
                            AND billofmaterialsubitemtext IS INITIAL ).
        SORT lt_bomcauS BY billofmaterial material plant billofmaterialvariantusage billofmaterialstatus billofmaterialvariant billofmaterialitemnumber bomsubitemnumbervalue.
        MOVE-CORRESPONDING t_bomcau[] TO lt_bomcauI[].
        SORT lt_bomcauI BY billofmaterial material plant billofmaterialvariantusage billofmaterialstatus billofmaterialvariant billofmaterialitemnumber.
        DELETE ADJACENT DUPLICATES FROM lt_bomcauI COMPARING billofmaterial material plant billofmaterialvariantusage billofmaterialstatus billofmaterialvariant billofmaterialitemnumber.
        l_lines = lines( lt_bomcauI ).

        l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002/MaterialBOM`.

        IF w_etag IS INITIAL.
            lt_header = "Headers參數
                VALUE #(
                 ( name = 'Accept' value = 'application/json'  )
                 ( name = 'Content-Type' value = 'application/json'  )
                 ( name = 'If-Match' value = '*'  ) ).
        ELSE.
            lt_header = "Headers參數
                VALUE #(
                 ( name = 'Accept' value = 'application/json'  )
                 ( name = 'Content-Type' value = 'application/json'  )
                 ( name = 'If-Match' value = w_etag  ) ).
        ENDIF.

        l_body = `{"d":{`.
        l_body = l_body && `"BillOfMaterialVariantUsage":"` && bomcau-billofmaterialvariantusage && `", "BillOfMaterialCategory":"M",`.
        l_body = l_body && `"BillOfMaterialVariant": "` && bomcau-billofmaterialvariant && `", "BillOfMaterialStatus": "` && bomcau-billofmaterialstatus && `",`.
        l_body = l_body && `"Material": "` && bomcau-material && `", "Plant": "` &&  bomcau-plant && `", `.
        IF bomcau-jsondate IS NOT INITIAL.
            l_body = l_body && `"HeaderValidityStartDate": "` && bomcau-jsondate && `",`.
        ENDIF.
        l_body = l_body && `"BOMHeaderBaseUnit": "` && bomcau-bomheaderbaseunit && `", "BOMHeaderQuantityInBaseUnit": "` &&  bomcau-bomheaderquantityinbaseunit && `",`.

        l_body = l_body && `"to_BillOfMaterialItem": { "results": [ `.
        LOOP AT lt_bomcauI INTO lwa_bomcau.
            CLEAR l_first.
            l_index = l_index + 1.
            l_body = l_body && `{`.
            l_body = l_body && `"BillOfMaterialComponent": "` && lwa_bomcau-billofmaterialcomponent && `","BillOfMaterialItemCategory": "` && lwa_bomcau-billofmaterialitemcategory && `",`.
            l_body = l_body && `"BillOfMaterialItemNumber": "` && lwa_bomcau-billofmaterialitemnumber && `","BillOfMaterialItemUnit": "` && lwa_bomcau-billofmaterialitemunit && `",`.
            l_body = l_body && `"BillOfMaterialItemQuantity": "` && lwa_bomcau-billofmaterialitemquantity && `",`.
            IF lwa_bomcau-fixedquantity = 'X'.
                l_body = l_body && `"FixedQuantity": true,`.
            ELSE.
                l_body = l_body && `"FixedQuantity": false,`.
            ENDIF.
            l_body = l_body && `"BOMItemDescription": "` && lwa_bomcau-bomitemdescription && `","IsProductionRelevant": true,`.
            l_body = l_body && `"ProdOrderIssueLocation": "` && lwa_bomcau-prodorderissuelocation && `","AlternativeItemGroup": "` && lwa_bomcau-alternativeitemgroup && `",`.
            l_body = l_body && `"AlternativeItemPriority": "` && lwa_bomcau-alternativeitempriority && `","AlternativeItemStrategy": "` && lwa_bomcau-alternativeitemstrategy && `"`.

            IF lwa_bomcau-usageprobabilitypercent IS NOT INITIAL.
                l_body = l_body && `,"UsageProbabilityPercent": "` && lwa_bomcau-usageprobabilitypercent && `"`.
            ENDIF.

            IF l_index < l_lines.
                l_body = l_body && `},`.
            ELSE.
                l_body = l_body && `}`.
            ENDIF.
        ENDLOOP.

        l_body = l_body && `] } }}`.

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
*                DATA(lr_web_http_response) = lr_web_http_client->execute( i_method = if_web_http_client=>PATCH ).
*                DATA(l_response) = lr_web_http_response->get_text( ).
                lr_web_http_client->close( ).
            CATCH cx_web_http_client_error INTO DATA(lr_data2).
            ENDTRY.

            IF ( l_status-code = 201 OR l_status-code = 204 OR l_status-code = 200 ).
                IF lt_bomcauS[] IS INITIAL.
                    rv_result = 'SUCCESS'.
                ENDIF.
            ELSE.
                    l_error = 'X'.
                    rv_result = 'ERROR'.
                    message = l_text.
            ENDIF.
       ENDIF.

       IF l_error IS INITIAL AND lt_bomcauS[] IS NOT INITIAL.
            CLEAR: lt_header, l_body, l_url, rv_result, message, l_lines, l_index.
            l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002/MaterialBOMSubItem`.

            SELECT a~BillOfMaterial, b~BillOfMaterialVariant, a~BillOfMaterialItemNodeNumber, b~Material, b~Plant,
                   b~BillOfMaterialVariantUsage, a~BillOfMaterialItemNumber, a~BillOfMaterialItemUnit
              FROM I_BillOfMaterialItemDEX_3 WITH PRIVILEGED ACCESS AS a
              JOIN I_MaterialBOMLink WITH PRIVILEGED ACCESS AS b ON a~BillOfMaterial = b~BillOfMaterial AND a~BillOfMaterialCategory = b~BillOfMaterialCategory
                                                                 AND a~BillOfMaterialVariant = b~BillOfMaterialVariant
              WHERE a~BillOfMaterialCategory = 'M' AND b~BillOfMaterialVariant = @bomcau-billofmaterialvariant
                AND b~Material = @bomcau-material AND b~Plant = @bomcau-plant
                AND b~BillOfMaterialVariantUsage = @bomcau-billofmaterialvariantusage
              INTO CORRESPONDING FIELDS OF TABLE @lt_mast.
            SORT lt_mast BY material plant billofmaterialvariantusage billofmaterialvariant.

            CLEAR: lwa_BillOfMaterial, w_etag.
            lwa_BillOfMaterial-billofmaterialcategory = 'M'.
            lwa_BillOfMaterial-material = bomcau-material.
            lwa_BillOfMaterial-plant = bomcau-plant.
            lwa_BillOfMaterial-billofmaterialvariant = bomcau-billofmaterialvariant.
            w_etag = getEtag( BillOfMaterial = lwa_BillOfMaterial ).
            IF w_etag IS INITIAL.
                lt_header = "Headers參數
                    VALUE #(
                     ( name = 'Accept' value = 'application/json'  )
                     ( name = 'Content-Type' value = 'application/json'  )
                     ( name = 'If-Match' value = '*'  ) ).
            ELSE.
                lt_header = "Headers參數
                    VALUE #(
                     ( name = 'Accept' value = 'application/json'  )
                     ( name = 'Content-Type' value = 'application/json'  )
                     ( name = 'If-Match' value = w_etag  ) ).
            ENDIF.

            CLEAR l_first.
            LOOP AT lt_mast INTO lwa_mast.
                LOOP AT lt_bomcauS INTO lwa_bomcauS WHERE Material = lwa_mast-material AND Plant = lwa_mast-plant
                                                      AND BillOfMaterialVariantUsage = lwa_mast-billofmaterialvariantusage
                                                      AND billofmaterialvariant = lwa_mast-billofmaterialvariant
                                                      AND BillOfMaterialItemNumber = lwa_mast-billofmaterialitemnumber.

                    IF l_first IS INITIAL.
                        l_first = 'X'.
                    ELSE.
                        l_body = l_body && `,`.
                    ENDIF.
                    l_body = l_body && `{`.
                    l_body = l_body && `"BillOfMaterial": "` && lwa_mast-billofmaterial && `","BillOfMaterialCategory": "M",`.
                    l_body = l_body && `"BillOfMaterialVariant": "` && lwa_mast-billofmaterialvariant && `","BillOfMaterialItemNodeNumber": "` && lwa_mast-billofmaterialitemnodenumber && `",`.
                    l_body = l_body && `"Material": "` && lwa_mast-material && `",`.
                    l_body = l_body && `"Plant": "` && lwa_mast-plant && `","BOMSubItemNumberValue":` && lwa_bomcauS-bomsubitemnumbervalue && `",`.
                    l_body = l_body && `"BillOfMaterialItemUnit": "` && lwa_mast-billofmaterialitemunit &&  `",`.
                    l_body = l_body && `"BillOfMaterialSubItemQuantity":` && lwa_bomcauS-billofmaterialsubitemquantity && `",`.
                    l_body = l_body && `"BOMSubItemInstallationPoint":` && lwa_bomcauS-bomsubiteminstallationpoint && `",`.
                    l_body = l_body && `"BillOfMaterialSubItemQuantity":` && lwa_bomcauS-billofmaterialsubitemtext && `" }`.
                ENDLOOP.
            ENDLOOP.

            CLEAR: l_status, l_text.
            FREE: lr_http_destination, lr_web_http_client, lr_request, lr_response.
            TRY.
                lr_http_destination = cl_http_destination_provider=>create_by_url( i_url = l_url ). "直接在程式碼中指定 URL 來呼叫 HTTP 或 SOAP 服務
            CATCH cx_http_dest_provider_error INTO DATA(lr_dataS).
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
*                    DATA(lr_web_http_response) = lr_web_http_client->execute( i_method = if_web_http_client=>PATCH ).
*                    DATA(l_response) = lr_web_http_response->get_text( ).
                    lr_web_http_client->close( ).
                CATCH cx_web_http_client_error INTO DATA(lr_dataS2).
                ENDTRY.

                IF ( l_status-code = 201 OR l_status-code = 204 OR l_status-code = 200 ).
                        rv_result = 'SUCCESS'.
                ELSE.
                        rv_result = 'ERROR'.
                        message = l_text.
                ENDIF.
           ENDIF.
       ENDIF.



    ENDMETHOD.

*        CLEAR: lt_header, l_body, l_url, rv_result, message.
*        l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002/MaterialBOM(BillOfMaterial='` && BOMCAU-billofmaterial && `',`.
*        l_url = l_url && `BillOfMaterialCategory='M',`.
*        l_url = l_url && `BillOfMaterialVariant='` &&  BOMCAU-billofmaterialvariant && `',`.
*        l_url = l_url && `BillOfMaterialVersion='',`.
*        l_url = l_url && `EngineeringChangeDocument='',`.
*        l_url = l_url && `Material='` && BOMCAU-material && `', Plant='` &&  BOMCAU-plant && `')/to_BillOfMaterialItem`.

    METHOD DeleteBom.
        DATA: l_url TYPE string,
              l_body TYPE string.
        DATA: lwa_header TYPE if_web_http_request=>name_value_pair,
              lt_header  TYPE if_web_http_request=>name_value_pairs.
        DATA: l_status TYPE if_web_http_response=>http_status .
        DATA: l_text TYPE string.
        DATA: lr_http_destination TYPE REF TO if_http_destination.
        DATA: lr_web_http_client TYPE REF TO if_web_http_client.
        DATA: lr_request TYPE REF TO if_web_http_request.
        DATA: lr_response TYPE REF TO if_web_http_response.

        DATA: lwa_bomcau LIKE wa_bomcau,
              lwa_bomcauI LIKE wa_bomcau,
              lt_bomcauI LIKE STANDARD TABLE OF lwa_bomcauI,
              lwa_bomcauS LIKE wa_bomcau,
              lt_bomcauS LIKE STANDARD TABLE OF lwa_bomcauS,
              lwa_BillOfMaterial LIKE wa_BillOfMaterial.
        DATA: l_json TYPE string,
              l_code TYPE string,
              l_message  TYPE string,
              l_mes TYPE string,
              l_first(1),
              l_id TYPE i,
              l_error(1).

        DATA: BEGIN OF lwa_BillOfMaterialItemBasic,
                billofmaterial TYPE I_BillOfMaterialItemBasic-billofmaterial,
                billofmaterialvariant TYPE I_MaterialBOMLink-billofmaterialvariant,
                billofmaterialitemnodenumber TYPE I_BillOfMaterialItemBasic-BillOfMaterialItemNodeNumber,
                Material TYPE I_MaterialBOMLink-Material,
              END OF lwa_BillOfMaterialItemBasic,
              lt_BillOfMaterialItemBasic LIKE STANDARD TABLE OF lwa_BillOfMaterialItemBasic.

       DATA: BEGIN OF lwa_mast,
                BillOfMaterial TYPE I_BillOfMaterialItemBasic-BillOfMaterial,
                Material TYPE I_MaterialBOMLink-Material,
                Plant TYPE I_MaterialBOMLink-Plant,
                BillOfMaterialVariantUsage TYPE I_MaterialBOMLink-BillOfMaterialVariantUsage,
                BillOfMaterialVariant TYPE I_MaterialBOMLink-BillOfMaterialVariant,
                BillOfMaterialItemNodeNumber TYPE I_BillOfMaterialItemBasic-BillOfMaterialItemNodeNumber,
                BillOfMaterialItemNumber TYPE I_BillOfMaterialItemBasic-BillOfMaterialItemNumber,
                BillOfMaterialItemUnit TYPE I_BillOfMaterialItemBasic-BillOfMaterialItemUnit,
              END OF lwa_mast,
              lt_mast LIKE STANDARD TABLE OF lwa_mast.

        CLEAR: lt_header, l_body, l_url, rv_result, message, lt_BillOfMaterialItemBasic, lt_bomcauS, lwa_bomcauS, lt_bomcauI, lwa_bomcauI, l_error.
        MOVE-CORRESPONDING t_bomcau[] TO lt_bomcauS[].
        DELETE lt_bomcauS WHERE ( bomsubitemnumbervalue IS INITIAL AND bomsubiteminstallationpoint IS INITIAL AND billofmaterialsubitemquantity IS INITIAL
                            AND billofmaterialsubitemtext IS INITIAL ).
        SORT lt_bomcauS BY billofmaterial material plant billofmaterialvariantusage billofmaterialstatus billofmaterialvariant billofmaterialitemnumber bomsubitemnumbervalue.
        MOVE-CORRESPONDING t_bomcau[] TO lt_bomcauI[].
        SORT lt_bomcauI BY billofmaterial material plant billofmaterialvariantusage billofmaterialstatus billofmaterialvariant billofmaterialitemnumber.
        DELETE ADJACENT DUPLICATES FROM lt_bomcauI COMPARING billofmaterial material plant billofmaterialvariantusage billofmaterialstatus billofmaterialvariant billofmaterialitemnumber.

        SELECT a~billofmaterial, b~billofmaterialvariant, a~BillOfMaterialItemNodeNumber, b~Material
            FROM I_BillOfMaterialItemDEX_3 WITH PRIVILEGED ACCESS AS a
            JOIN I_MaterialBOMLink WITH PRIVILEGED ACCESS AS b ON a~BillOfMaterial = b~BillOfMaterial AND a~BillOfMaterialCategory = b~BillOfMaterialCategory
                                                               AND a~BillOfMaterialVariant = b~BillOfMaterialVariant
            WHERE a~BillOfMaterialCategory = 'M' AND b~BillOfMaterialVariant = @billofmaterialvariant
              AND b~Material = @material AND b~Plant = @plant
              AND b~BillOfMaterialVariantUsage = @billofmaterialvariantusage
              AND b~billofmaterial = @billofmaterial
            INTO CORRESPONDING FIELDS OF TABLE @lt_BillOfMaterialItemBasic.

        l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002//$batch`.

        IF w_etag IS INITIAL.
            lt_header = "Headers參數
                VALUE #(
                 ( name = 'Accept' value = 'application/json'  )
                 ( name = 'Content-Type' value = 'multipart/mixed;boundary=batch_12345'  )
                 ( name = 'If-Match' value = '*'  ) ).
        ELSE.
            lt_header = "Headers參數
                VALUE #(
                 ( name = 'Accept' value = 'application/json'  )
                 ( name = 'Content-Type' value = 'multipart/mixed;boundary=batch_12345'  )
                 ( name = 'If-Match' value = w_etag  ) ).
        ENDIF.

        DATA(l_crlf) = cl_abap_char_utilities=>cr_lf.

        l_body = l_crlf && `--batch_12345` && l_crlf.
        l_body = l_body && `Content-Type: multipart/mixed;boundary=changeset_456` && l_crlf && l_crlf && l_crlf.

        LOOP AT lt_BillOfMaterialItemBasic INTO lwa_BillOfMaterialItemBasic.
            l_body = l_body && `--changeset_456` && l_crlf.
            l_body = l_body && `Content-Type: application/http` && l_crlf.
            l_body = l_body && `Content-Transfer-Encoding: binary` && l_crlf && l_crlf && l_crlf.
            l_body = l_body && `DELETE MaterialBOMItem(BillOfMaterial='` && billofmaterial && `',`.
            l_body = l_body && `BillOfMaterialCategory='M',BillOfMaterialVariant='` && billofmaterialvariant && `',`.
            l_body = l_body && `BillOfMaterialVersion='',BillOfMaterialItemNodeNumber='` && lwa_BillOfMaterialItemBasic-billofmaterialitemnodenumber && `',`.
            l_body = l_body && `HeaderChangeDocument='',Material='` && material && `',Plant='` && plant && `') HTTP/1.1` && l_crlf.
            l_body = l_body && `Accept: application/json` && l_crlf.
            l_body = l_body && `If-Match: *` && l_crlf && l_crlf && l_crlf.
        ENDLOOP.

        CLEAR l_id.
        LOOP AT lt_bomcauI INTO lwa_bomcau.
            l_body = l_body && `--changeset_456` && l_crlf.
            l_body = l_body && `Content-Type: application/http` && l_crlf.
            l_body = l_body && `Content-Transfer-Encoding: binary` && l_crlf && l_crlf.
            l_body = l_body && `POST MaterialBOMItem HTTP/1.1` && l_crlf.
            l_body = l_body && `Content-Type: application/json` && l_crlf && l_crlf.
            l_body = l_body && `{  "d":{`.
            l_body = l_body && `"BillOfMaterial": "` && billofmaterial && `","BillOfMaterialCategory": "M",`.
            l_body = l_body && `"BillOfMaterialVariant": "` && billofmaterialvariant && `","Material": "` && material && `",`.
            l_body = l_body && `"Plant": "` && plant && `","BillOfMaterialItemNumber": "` && lwa_bomcau-billofmaterialitemnumber && `",`.
            l_body = l_body && `"BillOfMaterialItemCategory": "` && lwa_bomcau-billofmaterialitemcategory && `","BillOfMaterialComponent": "` && lwa_bomcau-billofmaterialcomponent && `",`.
            l_body = l_body && `"BillOfMaterialItemUnit": "` && lwa_bomcau-billofmaterialitemunit && `","BillOfMaterialItemQuantity": "` && lwa_bomcau-billofmaterialitemquantity && `",`.
            IF lwa_bomcau-fixedquantity = 'X'.
                l_body = l_body && `"FixedQuantity": true,`.
            ELSE.
                l_body = l_body && `"FixedQuantity": false,`.
            ENDIF.
            l_body = l_body && `"BOMItemDescription": "` && lwa_bomcau-bomitemdescription && `","IsProductionRelevant": true,`.
            l_body = l_body && `"ProdOrderIssueLocation": "` && lwa_bomcau-prodorderissuelocation && `","AlternativeItemGroup": "` && lwa_bomcau-alternativeitemgroup && `",`.
            l_body = l_body && `"AlternativeItemPriority": "` && lwa_bomcau-alternativeitempriority && `","AlternativeItemStrategy": "` && lwa_bomcau-alternativeitemstrategy && `"`.
            IF lwa_bomcau-usageprobabilitypercent IS NOT INITIAL.
                l_body = l_body && `,"UsageProbabilityPercent": "` && lwa_bomcau-usageprobabilitypercent && `"`.
            ENDIF.

            l_body = l_body && `}}` && l_crlf && l_crlf && l_crlf.
        ENDLOOP.

        l_body = l_body && l_crlf.
        l_body = l_body && `--changeset_456--` && l_crlf.
        l_body = l_body && `--batch_12345--`.

*        l_body = `\n--batch_12345\n`.
*        l_body = l_body && `Content-Type: multipart/mixed;boundary=changeset_456\n\n\n`.
*
*        LOOP AT lt_BillOfMaterialItemBasic INTO lwa_BillOfMaterialItemBasic.
*            l_body = l_body && `--changeset_456\n`.
*            l_body = l_body && `Content-Type: application/http\n`.
*            l_body = l_body && `Content-Transfer-Encoding: binary\n\n\n`.
*            l_body = l_body && `DELETE MaterialBOMItem(BillOfMaterial=''` && billofmaterial && `'',`.
*            l_body = l_body && `BillOfMaterialCategory=''M'',BillOfMaterialVariant=''` && billofmaterialvariant && `'',`.
*            l_body = l_body && `BillOfMaterialVersion='''',BillOfMaterialItemNodeNumber=''` && lwa_BillOfMaterialItemBasic-billofmaterialitemnodenumber && `'',`.
*            l_body = l_body && `HeaderChangeDocument='''',Material=''` && material && `'',Plant=''` && plant && `'') HTTP/1.1\n`.
*            l_body = l_body && `Accept: application/json\n`.
*            l_body = l_body && `If-Match: *\n\n\n`.
*        ENDLOOP.
*
**        LOOP AT t_bomcau INTO lwa_bomcau.
**            l_body = l_body && `--changeset_456\n`.
**            l_body = l_body && `Content-Type: application/http\n`.
**            l_body = l_body && `Content-Transfer-Encoding: binary\n\n`.
**            l_body = l_body && `POST MaterialBOMItem HTTP/1.1\n`.
**            l_body = l_body && `Content-Type: application/json\n\n`.
**            l_body = l_body && `{  "d":{`.
**            l_body = l_body && `"BillOfMaterial": "` && billofmaterial && `","BillOfMaterialCategory": "M",`.
**            l_body = l_body && `"BillOfMaterialVariant": "` && billofmaterialvariant && `","Material": "` && material && `",`.
**            l_body = l_body && `"Plant": "` && plant && `","BillOfMaterialItemNumber": "` && lwa_bomcau-billofmaterialitemnumber && `",`.
**            l_body = l_body && `"BillOfMaterialItemCategory": "` && lwa_bomcau-billofmaterialitemcategory && `","BillOfMaterialComponent": "` && lwa_bomcau-billofmaterialcomponent && `",`.
**            l_body = l_body && `"BillOfMaterialItemUnit": "` && lwa_bomcau-billofmaterialitemunit && `","BillOfMaterialItemQuantity": "` && lwa_bomcau-billofmaterialitemquantity && `",`.
**            IF lwa_bomcau-fixedquantity = 'X'.
**                l_body = l_body && `"FixedQuantity": true,`.
**            ELSE.
**                l_body = l_body && `"FixedQuantity": false,`.
**            ENDIF.
**            l_body = l_body && `"BOMItemDescription": "` && lwa_bomcau-bomitemdescription && `","IsProductionRelevant": true,`.
**            l_body = l_body && `"UsageProbabilityPercent": "` && lwa_bomcau-usageprobabilitypercent && `"}}\n\n\n`.
**        ENDLOOP.
*
*        l_body = l_body && `\n`.
*        l_body = l_body && `--changeset_456--\n`.
*        l_body = l_body && `--batch_12345--`.


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
*                DATA(lr_web_http_response) = lr_web_http_client->execute( i_method = if_web_http_client=>PATCH ).
*                DATA(l_response) = lr_web_http_response->get_text( ).
                lr_web_http_client->close( ).
            CATCH cx_web_http_client_error INTO DATA(lr_data2).
            ENDTRY.

            CLEAR: l_json, l_code, l_message, l_mes.

            "錯誤訊息
            " 抓 <code> 內容
            FIND REGEX '<code>([^<]+)</code>' IN l_text SUBMATCHES l_code.

            " 抓 <message> 內容
            FIND REGEX '<message[^>]*>(.*)</message>' IN l_text SUBMATCHES l_json.

            " 移除換行空白
            REPLACE ALL OCCURRENCES OF REGEX '\r|\n' IN l_json WITH ''.
            CONDENSE l_json.

            " 組成 JSON
            DATA(lv_json) = XmlToJson( iv_xml = l_text ).
*            DATA(lv_json) = '"error": { "code": "' && l_code && '", "message": { "lang": "zf", "value": "' && l_json && '" }   }'.

*            " 抓 <message> 內容
*            FIND REGEX '<message[^>]*>(.*)</message>' IN l_text SUBMATCHES l_json.
*            " 移除換行空白
*            REPLACE ALL OCCURRENCES OF REGEX '\r|\n' IN l_json WITH ''.
*            CONDENSE l_json." 抓 <message> 內容

            "成功訊息
            FIND REGEX 'sap-message:\s*(\{.*\})' IN l_text SUBMATCHES l_message.
            FIND REGEX '"message"\s*:\s*"([^"]*)"' IN l_message SUBMATCHES l_mes.

            IF l_message IS NOT INITIAL.
                IF lt_bomcauS[] IS INITIAL.
                    rv_result = 'SUCCESS'.
                ENDIF.
            ELSE.
                l_error = 'X'.
                rv_result = 'ERROR'.
                message = lv_json.
            ENDIF.
       ENDIF.

       IF l_error IS INITIAL AND lt_bomcauS[] IS NOT INITIAL .
            CLEAR: lt_header, l_body, l_url, rv_result, message, w_etag .
            l_url = `https://my427098-api.s4hana.cloud.sap/sap/opu/odata/sap/API_BILL_OF_MATERIAL_SRV;v=0002/MaterialBOMSubItem`.

            SELECT a~BillOfMaterial, b~BillOfMaterialVariant, a~BillOfMaterialItemNodeNumber, b~Material, b~Plant,
                   b~BillOfMaterialVariantUsage, a~BillOfMaterialItemNumber, a~BillOfMaterialItemUnit
              FROM I_BillOfMaterialItemDEX_3 WITH PRIVILEGED ACCESS AS a
              JOIN I_MaterialBOMLink WITH PRIVILEGED ACCESS AS b ON a~BillOfMaterial = b~BillOfMaterial AND a~BillOfMaterialCategory = b~BillOfMaterialCategory
                                                                 AND a~BillOfMaterialVariant = b~BillOfMaterialVariant
              WHERE a~BillOfMaterialCategory = 'M' AND b~BillOfMaterialVariant = @billofmaterialvariant
                AND b~Material = @material AND b~Plant = @plant
                AND b~BillOfMaterialVariantUsage = @billofmaterialvariantusage
                AND b~billofmaterial = @billofmaterial
              INTO CORRESPONDING FIELDS OF TABLE @lt_mast.
            SORT lt_mast BY material plant billofmaterialvariantusage billofmaterialvariant.

            CLEAR: lwa_BillOfMaterial, w_etag.
            lwa_BillOfMaterial-billofmaterialcategory = 'M'.
            lwa_BillOfMaterial-material = material.
            lwa_BillOfMaterial-plant = plant.
            lwa_BillOfMaterial-billofmaterialvariant = billofmaterialvariant.
            w_etag = getEtag( BillOfMaterial = lwa_BillOfMaterial ).
            IF w_etag IS INITIAL.
                lt_header = "Headers參數
                    VALUE #(
                     ( name = 'Accept' value = 'application/json'  )
                     ( name = 'Content-Type' value = 'application/json'  )
                     ( name = 'If-Match' value = '*'  ) ).
            ELSE.
                lt_header = "Headers參數
                    VALUE #(
                     ( name = 'Accept' value = 'application/json'  )
                     ( name = 'Content-Type' value = 'application/json'  )
                     ( name = 'If-Match' value = w_etag  ) ).
            ENDIF.

            CLEAR l_first.
            LOOP AT lt_mast INTO lwa_mast.
                LOOP AT lt_bomcauS INTO lwa_bomcauS WHERE Material = lwa_mast-material AND Plant = lwa_mast-plant
                                                      AND BillOfMaterialVariantUsage = lwa_mast-billofmaterialvariantusage
                                                      AND billofmaterialvariant = lwa_mast-billofmaterialvariant
                                                      AND BillOfMaterialItemNumber = lwa_mast-billofmaterialitemnumber.
                    IF l_first IS INITIAL.
                        l_first = 'X'.
                    ELSE.
                        l_body = l_body && `,`.
                    ENDIF.
                    l_body = l_body && `{`.
                    l_body = l_body && `"BillOfMaterial": "` && lwa_mast-billofmaterial && `","BillOfMaterialCategory": "M",`.
                    l_body = l_body && `"BillOfMaterialVariant": "` && lwa_mast-billofmaterialvariant && `","BillOfMaterialItemNodeNumber": "` && lwa_mast-billofmaterialitemnodenumber && `",`.
                    l_body = l_body && `"Material": "` && lwa_mast-material && `",`.
                    l_body = l_body && `"Plant": "` && lwa_mast-plant && `","BOMSubItemNumberValue": "` && lwa_bomcauS-bomsubitemnumbervalue && `",`.
                    l_body = l_body && `"BillOfMaterialItemUnit": "` && lwa_mast-billofmaterialitemunit &&  `",`.
                    l_body = l_body && `"BillOfMaterialSubItemQuantity": "` && lwa_bomcauS-billofmaterialsubitemquantity && `",`.
                    l_body = l_body && `"BOMSubItemInstallationPoint": "` && lwa_bomcauS-bomsubiteminstallationpoint && `",`.
                    l_body = l_body && `"BillOfMaterialSubItemText": "` && lwa_bomcauS-billofmaterialsubitemtext && `" }`.
                ENDLOOP.
            ENDLOOP.

            CLEAR: l_status, l_text.
            FREE: lr_http_destination, lr_web_http_client, lr_request, lr_response.
            TRY.
                lr_http_destination = cl_http_destination_provider=>create_by_url( i_url = l_url ). "直接在程式碼中指定 URL 來呼叫 HTTP 或 SOAP 服務
            CATCH cx_http_dest_provider_error INTO DATA(lr_dataS).
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
*                    DATA(lr_web_http_response) = lr_web_http_client->execute( i_method = if_web_http_client=>PATCH ).
*                    DATA(l_response) = lr_web_http_response->get_text( ).
                    lr_web_http_client->close( ).
                CATCH cx_web_http_client_error INTO DATA(lr_dataS2).
                ENDTRY.

                IF ( l_status-code = 201 OR l_status-code = 204 OR l_status-code = 200 ).
                        rv_result = 'SUCCESS'.
                ELSE.
                        rv_result = 'ERROR'.
                        message = l_text.
                ENDIF.
           ENDIF.
       ENDIF.

    ENDMETHOD.

    METHOD date_to_sap_json.

*        DATA: lv_ts        TYPE c LENGTH 14,
*              lv_year      TYPE i,
*              lv_month     TYPE i,
*              lv_day       TYPE i,
*              lv_hour      TYPE i,
*              lv_min       TYPE i,
*              lv_sec       TYPE i,
*              lv_epoch     TYPE p LENGTH 16 DECIMALS 0,
*              lv_days      TYPE i,
*              lv_seconds   TYPE i,
*              lv_month_off TYPE i,
*              lv_day_off   TYPE i.
*
*        " 範例 timestamp
*        lv_ts = iv_date_time. " YYYYMMDDhhmmss
*
*        " 拆成年月日時分秒
*        lv_year  = lv_ts+0(4).     " 或 lv_ts(0)(4)
*        lv_month = lv_ts+4(2).
*        lv_day   = lv_ts+6(2).
*        lv_hour  = lv_ts+8(2).
*        lv_min   = lv_ts+10(2).
*        lv_sec   = lv_ts+12(2).
*
*        " ===== 計算月偏移 =====
*        IF lv_month < 3.
*          lv_month_off = lv_month + 12 - 3. " 1月、2月當作前一年 13、14月
*        ELSE.
*          lv_month_off = lv_month - 3.
*        ENDIF.
*
*        " ===== 計算天數偏移 =====
*        lv_day_off = ( 153 * lv_month_off + 2 ) / 5.
*
*        " ===== 計算從 1970-01-01 到當前年份的天數 =====
*        lv_days = ( lv_year - 1970 ) * 365
*                  + ( lv_year - 1969 ) / 4
*                  - ( lv_year - 1901 ) / 100
*                  + ( lv_year - 1601 ) / 400
*                  + lv_day_off
*                  + lv_day - 1.
*
*        " ===== 計算總秒數 =====
*        lv_seconds = lv_days * 86400
*                   + lv_hour * 3600
*                   + lv_min  * 60
*                   + lv_sec.
*
*        " ===== 轉毫秒 =====
*        lv_epoch = lv_seconds * 1000.
        DATA: lv_date TYPE syst-datum.
        DATA: lv_timestamp TYPE timestampl.
        DATA: lv_millis TYPE p LENGTH 16,
              lv_seconds TYPE p DECIMALS 0,
              lv_days  TYPE i,
              lv_epoch TYPE syst-datum VALUE '19700101'.
        lv_date = iv_date_time+0(8).
        lv_days = lv_date - lv_epoch.
        lv_seconds = lv_days * 86400.
        lv_millis = lv_seconds * 100.  " 第一次乘 100
        lv_millis = lv_millis * 10.    " 第二次乘 10

        rv_sap_date = '/Date(' && lv_millis && ')/'.
    ENDMETHOD.

    METHOD XmlToJson.

        DATA: l_code TYPE string,
              l_message TYPE string,
              l_lang      TYPE string,
              l_transactionid TYPE string,
              l_timestamp TYPE string,
              l_sap_note  TYPE string,
              l_sap_tran  TYPE string.

        " 抓 <code>
        FIND REGEX '<code>([^<]+)</code>' IN iv_xml SUBMATCHES l_code.
        " 抓 <message> 內容
        FIND REGEX '<message[^>]*>([^<]+)</message>' IN iv_xml SUBMATCHES l_message.
        " 抓 lang 屬性
        FIND REGEX '<message xml:lang="([^"]+)"' IN iv_xml SUBMATCHES l_lang.
*        " 抓 transactionid
*        FIND REGEX '<transactionid>([^<]+)</transactionid>' IN iv_xml SUBMATCHES l_transactionid.
*        " 抓 timestamp
*        FIND REGEX '<timestamp>([^<]+)</timestamp>' IN iv_xml SUBMATCHES l_timestamp.
*        " 抓 SAP Note
*        FIND REGEX '<SAP_Note>([^<]+)</SAP_Note>' IN iv_xml SUBMATCHES l_sap_note.
*        " 抓 SAP Transaction
*        FIND REGEX '<SAP_Transaction>([^<]+)</SAP_Transaction>' IN iv_xml SUBMATCHES l_sap_tran.

        " 組成 JSON 字串
        rv_json = '{ "error": { "code": "' && l_code && '", "message": {"lang": "' && l_lang && '", "value": "' && l_message && '"}} }'.
    ENDMETHOD.
ENDCLASS.
