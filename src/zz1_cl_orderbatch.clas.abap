CLASS zz1_cl_orderbatch DEFINITION
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



CLASS ZZ1_CL_ORDERBATCH IMPLEMENTATION.


    METHOD if_apj_dt_exec_object~get_parameters.

        " Return the supported selection parameters here
        et_parameter_def = VALUE #(
            ( selname = 'P_CLNT' kind = if_apj_dt_exec_object=>parameter datatype = 'C' length = 3 param_text =
            '環境' changeable_ind = abap_true )"DEV QAS PRD
            ( selname = 'S_DATE' kind = if_apj_dt_exec_object=>select_option datatype = 'D' length = 8 param_text =
            '建立日期' changeable_ind = abap_true )
            ( selname = 'S_PLANT' kind = if_apj_dt_exec_object=>select_option datatype = 'C' length = 4 param_text =
            '生產工廠' changeable_ind = abap_true )
        ).

        " Return the default parameters values here
        et_parameter_val = VALUE #(
          ( selname = 'S_DATE' kind = if_apj_dt_exec_object=>select_option sign = 'I' option = 'BT' low = cl_abap_context_info=>get_system_date( )  high = cl_abap_context_info=>get_system_date( ) )
         ).

    ENDMETHOD.


    METHOD if_apj_rt_exec_object~execute.
        "Execution logic when the job is started
        DATA: p_clnt TYPE c LENGTH 3,
              s_plant TYPE RANGE OF I_ManufacturingOrder-ProductionPlant,
              s_date TYPE RANGE OF d,
              a(2).
        DATA: BEGIN OF lwa_data,
                ManufacturingOrder TYPE I_ManufacturingOrder-ManufacturingOrder,
                ManufacturingOrderType TYPE I_ManufacturingOrder-ManufacturingOrderType,
                CreationDate TYPE I_ManufacturingOrder-CreationDate,
                Material TYPE I_ManufacturingOrder-Material,
                Batch TYPE I_ManufacturingOrder-Batch,
                ProductionPlant TYPE I_ManufacturingOrder-ProductionPlant,
                YY1_PO_CHARG_ORD TYPE I_ManufacturingOrder-yy1_po_charg_ord,
                yy1_mes_po_ord TYPE I_ManufacturingOrder-yy1_mes_po_ord,
                yy1_mes_status_ord TYPE I_ManufacturingOrder-yy1_mes_status_ord,
                yy1_material_delivery_ord TYPE I_ManufacturingOrder-yy1_material_delivery_ord,
              END OF lwa_data,
              lt_data  LIKE STANDARD TABLE OF lwa_data.
*              lwa_wotype TYPE ZZ1_WOTYPE,
*              lt_wotype TYPE STANDARD TABLE OF ZZ1_WOTYPE.

*        DATA: BEGIN OF lwa_mc104,
*            Product TYPE I_Product-Product,
*            CharcValue  TYPE ZZ1_I_ObjectCharacteristics-CharcValue,
*        END OF lwa_mc104,
*        lt_mc104 LIKE STANDARD TABLE OF lwa_mc104.

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
                WHEN 'S_PLANT'.
                    APPEND VALUE #( sign = ls_parameter-sign
                                    option = ls_parameter-option
                                    low = ls_parameter-low
                                    high = ls_parameter-high ) TO s_plant.
            ENDCASE.
        ENDLOOP.
        TRY.
            DATA(l_log) = cl_bali_log=>create_with_header( cl_bali_header_setter=>create( object =
                           'ZZ1_ORDERBATCH_LOG' subobject = 'ZZ1_ORDERBATCH' ) ).
        CATCH cx_bali_runtime.
            "handle exception
            a = 2.
        ENDTRY.

*        SELECT * FROM ZZ1_WOTYPE INTO CORRESPONDING FIELDS OF TABLE @lt_wotype.
*        SORT lt_wotype BY aufart.

*        IF lt_wotype[] IS NOT INITIAL.
            SELECT m~ManufacturingOrder, m~ManufacturingOrderType, m~CreationDate,
                   m~Material, m~Batch, m~ProductionPlant, m~YY1_PO_CHARG_ORD,
                   m~yy1_mes_po_ord, m~yy1_mes_status_ord, m~yy1_material_delivery_ord
                FROM I_ManufacturingOrder as m
                WHERE CreationDate IN @s_date AND ProductionPlant IN @s_plant
                  AND Batch IS INITIAL
                  AND EXISTS (
                        SELECT 1 FROM ZZ1_WOTYPE as w WHERE m~ManufacturingOrderType = w~aufart
                      )
                INTO CORRESPONDING FIELDS OF TABLE @lt_data.
*        ENDIF.


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
*            CLEAR: lwa_mc104, lt_mc104[].
*            SELECT a~Product, b~CharcValue
*              FROM I_Product AS a
*              JOIN ZZ1_I_ObjectCharacteristics AS b ON  a~Product = b~material
*                                                    AND b~Class          = 'Z_MATERIAL_CL01'
*                                                    AND b~Characteristic = 'Z_MY_MC_104'
*              WHERE charcvalue IS NOT INITIAL
*            INTO CORRESPONDING FIELDS OF TABLE @lt_mc104.
*            SORT lt_mc104 BY Product.



            LOOP AT lt_data INTO lwa_data.
                IF lwa_data-yy1_po_charg_ord IS NOT INITIAL.
                    lwa_data-batch = lwa_data-yy1_po_charg_ord.
*                ELSE.
*                    CLEAR lwa_mc104.
*                    READ TABLE lt_mc104 INTO lwa_mc104 BINARY SEARCH WITH KEY Product = lwa_data-material.
*                    IF sy-subrc = 0.
*                        lwa_data-batch = lwa_mc104-charcvalue.
*                    ENDIF.
                ENDIF.

                IF lwa_data-batch IS NOT INITIAL.
                    MODIFY ENTITY I_ProductionOrderTP
                        UPDATE FIELDS (
                                        batch
                                        yy1_mes_po_ord
                                        yy1_mes_status_ord
                                        yy1_material_delivery_ord
                                      )
                        WITH VALUE #(
                                      (
                                        %key-productionorder = lwa_data-manufacturingorder
                                        %data-batch = lwa_data-batch
                                        %data-yy1_mes_po_ord = lwa_data-yy1_mes_po_ord
                                        %data-yy1_mes_status_ord = lwa_data-yy1_mes_status_ord
                                        %data-yy1_material_delivery_ord = lwa_data-yy1_material_delivery_ord
                                      )
                                     )
                        FAILED DATA(failed)
                        REPORTED DATA(reported)
                        MAPPED DATA(mapped).

                    IF failed IS INITIAL.
                        CONCATENATE '批次更新成功:' lwa_data-ManufacturingOrder INTO l_text2.
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
                        CONCATENATE '批次更新失敗:' lwa_data-ManufacturingOrder INTO l_text2.
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
        DATA: p_clnt TYPE c LENGTH 3,
              s_plant TYPE RANGE OF I_ManufacturingOrder-ProductionPlant,
              s_date TYPE RANGE OF d,
              a(2).

        DATA: BEGIN OF lwa_data,
                ManufacturingOrder TYPE I_ManufacturingOrder-ManufacturingOrder,
                ManufacturingOrderType TYPE I_ManufacturingOrder-ManufacturingOrderType,
                CreationDate TYPE I_ManufacturingOrder-CreationDate,
                Material TYPE I_ManufacturingOrder-Material,
                Batch TYPE I_ManufacturingOrder-Batch,
                ProductionPlant TYPE I_ManufacturingOrder-ProductionPlant,
                YY1_PO_CHARG_ORD TYPE I_ManufacturingOrder-yy1_po_charg_ord,
                yy1_mes_po_ord TYPE I_ManufacturingOrder-yy1_mes_po_ord,
                yy1_mes_status_ord TYPE I_ManufacturingOrder-yy1_mes_status_ord,
                yy1_material_delivery_ord TYPE I_ManufacturingOrder-yy1_material_delivery_ord,
              END OF lwa_data,
              lt_data  LIKE STANDARD TABLE OF lwa_data.

        DATA:l_text2(200).
        " Getting the actual parameter values(Just for show. Not needed for the logic below)
        CLEAR: s_plant, s_date.
        APPEND VALUE #( sign = 'I'
                option = 'EQ'
                low = '6310' ) TO s_plant.

        APPEND VALUE #( sign = 'I'
                option = 'EQ'
                low = '20250904' ) TO s_date.

        SELECT m~ManufacturingOrder, m~ManufacturingOrderType, m~CreationDate,
               m~Material, m~Batch, m~ProductionPlant, m~YY1_PO_CHARG_ORD,
               m~yy1_mes_po_ord, m~yy1_mes_status_ord, m~yy1_material_delivery_ord
            FROM I_ManufacturingOrder as m
            WHERE CreationDate IN @s_date AND ProductionPlant IN @s_plant
              AND Batch IS INITIAL
              AND EXISTS (
                    SELECT 1 FROM ZZ1_WOTYPE as w WHERE m~ManufacturingOrderType = w~aufart
                  )
            INTO CORRESPONDING FIELDS OF TABLE @lt_data.


        IF lt_data IS INITIAL."沒資料
            DATA(l_success_text2) = cl_bali_free_text_setter=>create( severity =
                            if_bali_constants=>C_SEVERITY_STATUS "c_severity_error
                            text = '無可執行之資料' ).
        ELSE. "call api
            LOOP AT lt_data INTO lwa_data.
                IF lwa_data-yy1_po_charg_ord IS NOT INITIAL.
                    lwa_data-batch = lwa_data-yy1_po_charg_ord.
                ENDIF.

                IF lwa_data-batch IS NOT INITIAL.
                    MODIFY ENTITY I_ProductionOrderTP
                        UPDATE FIELDS (
                                        batch
                                        yy1_mes_po_ord
                                        yy1_mes_status_ord
                                        yy1_material_delivery_ord
                                      )
                        WITH VALUE #(
                                      (
                                        %key-productionorder = lwa_data-manufacturingorder
                                        %data-batch = lwa_data-batch
                                        %data-yy1_mes_po_ord = lwa_data-yy1_mes_po_ord
                                        %data-yy1_mes_status_ord = lwa_data-yy1_mes_status_ord
                                        %data-yy1_material_delivery_ord = lwa_data-yy1_material_delivery_ord
                                      )
                                     )
                        FAILED DATA(failed)
                        REPORTED DATA(reported)
                        MAPPED DATA(mapped).

                    IF failed IS INITIAL.
                        CONCATENATE '批次更新成功:' lwa_data-ManufacturingOrder INTO l_text2.
                    ELSE.
                        CONCATENATE '批次更新失敗:' lwa_data-ManufacturingOrder INTO l_text2.
                    ENDIF.
               ENDIF.
            ENDLOOP.
        ENDIF.

        COMMIT WORK.
    ENDMETHOD.
ENDCLASS.
