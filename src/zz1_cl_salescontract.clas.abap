CLASS zz1_cl_salescontract DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .
    INTERFACES if_rap_query_provider .
*    INTERFACES if_amdp_marker_hdb.
*    CLASS-METHODS exec_installment FOR TABLE FUNCTION ZZ1_TF_salescontract.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zz1_cl_salescontract IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
  ENDMETHOD.


  METHOD if_rap_query_provider~select.
    IF io_request->is_data_requested( ).
      DATA(l_size)     = io_request->get_paging( )->get_page_size( ).
      DATA(l_offset)    = io_request->get_paging( )->get_offset( ).
      DATA(l_max_rows) = COND #( WHEN l_size = if_rap_query_paging=>page_size_unlimited THEN 0 ELSE l_size ).

      DATA(lt_parameter) = io_request->get_parameters( ).

      DATA(lt_fields)  = io_request->get_requested_elements( ).
      DATA(lt_sort)    = io_request->get_sort_elements( ).

      DATA: l_offset_next TYPE i.
      DATA: l_total TYPE int8.
      DATA: lwa_filter TYPE if_rap_query_filter=>ty_name_range_pairs.
      DATA: lwa_parameter TYPE if_rap_query_request=>ty_parameter.
      DATA: lwa_range TYPE LINE OF  if_rap_query_filter=>tt_range_option.
      DATA: BEGIN OF lwa_data,
              SalesContract(10),
              SalesContractItem(6),
              PurchaseOrderByCustomer(40),
              SalesContractDate(8),
              SoldToParty(10),
              Name(20),
              Product(40),
              SalesContractItemText(40),
              yy1_staging_plant1_sdi(4),
              Plant(4),
              OrderQuantityUnit(3),
              OrderQuantity                  TYPE p LENGTH 13 DECIMALS 0,
              Reservation(10),
              ReservationItem(6),
              GoodsMovementType(5),
              ResvnItmRequiredQtyInEntryUnit TYPE p LENGTH 13 DECIMALS 0,
              PurchaseRequisition(10),
              PurchaseRequisitionItem(6),
              OrderedQuantity                TYPE p LENGTH 13 DECIMALS 0,
              UnreleasedQuantity             TYPE p LENGTH 13 DECIMALS 0,
              releasedQuantity               TYPE p LENGTH 13 DECIMALS 0,
              CreatedByUser(10),
              CreationDate(8),
            END OF lwa_data,
            lt_data  LIKE STANDARD TABLE OF lwa_data,
            lt_data2 LIKE STANDARD TABLE OF lwa_data.

      DATA : lwa_salesconta  TYPE ZZ1_I_salescontract1,
             lt_salesconta   TYPE STANDARD TABLE OF ZZ1_I_salescontract1
               WITH NON-UNIQUE SORTED KEY key COMPONENTS SalesContract product,
             lwa_group       TYPE ZZ1_I_salescontract1,
             lt_group        TYPE STANDARD TABLE OF ZZ1_I_salescontract1,
             lwa_reservation TYPE ZZ1_I_salescontract3,
             lt_reservation  TYPE STANDARD TABLE OF ZZ1_I_salescontract3,
             lwa_purchase    TYPE i_purchaserequisitionitemapi01,
             lt_purchase     TYPE STANDARD TABLE OF i_purchaserequisitionitemapi01
                WITH NON-UNIQUE SORTED KEY key COMPONENTS yy1_contract_number_pri material..
      DATA : BEGIN OF lwa_reservation2,
               Reservation                    TYPE ZZ1_I_salescontract3-Reservation,
               ReservationItem                TYPE ZZ1_I_salescontract3-ReservationItem,
               GoodsMovementType              TYPE ZZ1_I_salescontract3-GoodsMovementType,
               ResvnItmRequiredQtyInEntryUnit TYPE ZZ1_I_salescontract3-ResvnItmRequiredQtyInEntryUnit,
               yy1_contract_number_pri(10),
               Product                        TYPE ZZ1_I_salescontract3-Product,
             END OF lwa_reservation2,
             lt_reservation2 LIKE STANDARD TABLE OF lwa_reservation2
               WITH NON-UNIQUE SORTED KEY key COMPONENTS yy1_contract_number_pri product.
      DATA : BEGIN OF lwa_customer,
               Customer           TYPE I_customer-Customer,
               addressid          TYPE i_customer-AddressID,
               AddressSearchTerm2 TYPE zz1_i_address_2-AddressSearchTerm2,
             END OF lwa_customer,
             lt_customer LIKE STANDARD TABLE OF lwa_customer.
      DATA: BEGIN OF lwa_keys,
              reservation TYPE i_reservationdocumenttp-reservation,
            END OF lwa_keys.
      DATA lt_keys LIKE STANDARD TABLE OF lwa_keys.
      DATA : lt_rever TYPE I_ReservationDocumentTP.
      DATA : l_totalquan  TYPE p LENGTH 13 DECIMALS 0,
             l_totalquan2 TYPE p LENGTH 13 DECIMALS 0.

      "group用
      DATA : BEGIN OF lwa_groupquan,
               SalesContract(10),
               product(40),
               SalesContractItemText(40),
               OrderQuantityUnit(3),
               OrderQuantity             TYPE p LENGTH 13 DECIMALS 0,
               UnreleasedQuantity        TYPE p LENGTH 13 DECIMALS 0,
               releasedQuantity          TYPE p LENGTH 13 DECIMALS 0,
             END OF lwa_groupquan,
             lt_groupquan  LIKE STANDARD TABLE OF lwa_groupquan,
             lt_groupquan2 LIKE STANDARD TABLE OF lwa_groupquan..

      DATA:s_contr   TYPE RANGE OF vbeln,
           s_contr2  TYPE RANGE OF vbeln,
           s_reser   TYPE RANGE OF vbeln,
           s_purch   TYPE RANGE OF vbeln,
           s_purchc  TYPE RANGE OF bstkd,
           s_contday TYPE RANGE OF d,
           s_kunnr   TYPE RANGE OF kunnr,
           s_name    TYPE RANGE OF char40,
           s_matnr   TYPE RANGE OF matnr,
           s_text    TYPE RANGE OF char40,
           s_plant   TYPE RANGE OF char4,
           s_mvt     TYPE RANGE OF bwart,
           s_user    TYPE RANGE OF usnam,
           s_udat    TYPE RANGE OF datum
           .
      TRY.
          DATA(lt_filter)  = io_request->get_filter( )->get_as_ranges( ).
          LOOP AT lt_filter INTO lwa_filter.
            CASE lwa_filter-name.
              WHEN 'SALESCONTRACT'.
                MOVE-CORRESPONDING lwa_filter-range[] TO s_contr[].
                MOVE-CORRESPONDING lwa_filter-range[] TO s_contr2[].
                LOOP AT s_contr2 INTO DATA(lwa_contr).
                  DATA(l_index) = sy-tabix.
                  lwa_contr-low = |{ lwa_contr-low ALPHA = IN }|.
                  lwa_contr-high = |{ lwa_contr-high ALPHA = IN }|.
                  MODIFY s_contr2 FROM lwa_contr INDEX l_index.
                ENDLOOP.
              WHEN 'RESERVATION'.
                MOVE-CORRESPONDING lwa_filter-range[] TO s_reser[].
                LOOP AT s_reser INTO DATA(lwa_reser).
                  l_index = sy-tabix.
                  lwa_reser-low = |{ lwa_reser-low ALPHA = IN }|.
                  lwa_reser-high = |{ lwa_reser-high ALPHA = IN }|.
                  MODIFY s_reser FROM lwa_reser INDEX l_index.
                ENDLOOP.
              WHEN 'PURCHASEREQUISITION'.
                MOVE-CORRESPONDING lwa_filter-range[] TO s_purch[].
                LOOP AT s_purch INTO DATA(lwa_purch).
                  l_index = sy-tabix.
                  lwa_purch-low = |{ lwa_purch-low ALPHA = IN }|.
                  lwa_purch-high = |{ lwa_purch-high ALPHA = IN }|.
                  MODIFY s_purch FROM lwa_purch INDEX l_index.
                ENDLOOP.
              WHEN 'PURCHASEORDERBYCUSTOMER'.
                MOVE-CORRESPONDING lwa_filter-range[] TO s_purchc[].
              WHEN 'SALESCONTRACTDATE'.
                MOVE-CORRESPONDING lwa_filter-range[] TO s_contday[].
              WHEN 'SOLDTOPARTY'.
                MOVE-CORRESPONDING lwa_filter-range[] TO s_kunnr[].
              WHEN 'NAME'.
                MOVE-CORRESPONDING lwa_filter-range[] TO s_name[].
              WHEN 'PRODUCT'.
                MOVE-CORRESPONDING lwa_filter-range[] TO s_matnr[].
              WHEN 'SALESCONTRACTITEMTEXT'.
                MOVE-CORRESPONDING lwa_filter-range[] TO s_text[].
              WHEN 'PLANT'.
                MOVE-CORRESPONDING lwa_filter-range[] TO s_plant[].
              WHEN 'GOODSMOVEMENTTYPE'.
                MOVE-CORRESPONDING lwa_filter-range[] TO s_mvt[].
              WHEN 'CREATEDBYUSER'.
                MOVE-CORRESPONDING lwa_filter-range[] TO s_user[].
              WHEN 'CREATIONDATE'.
                MOVE-CORRESPONDING lwa_filter-range[] TO s_udat[].
            ENDCASE.
          ENDLOOP.
        CATCH cx_rap_query_filter_no_range.
          DATA(lt_filter2)  = io_request->get_filter( ).
      ENDTRY.

      SELECT * FROM ZZ1_I_salescontract1
        WHERE salescontract IN @s_contr2[] AND PurchaseOrderByCustomer IN @s_purchc
          AND SalesContractDate IN @s_contday AND SoldToParty IN @s_kunnr   AND Product IN @s_matnr
          AND SalesContractItemText IN @s_text AND Plant IN @s_plant AND CreatedByUser IN  @s_user AND CreationDate IN  @s_udat
          INTO CORRESPONDING FIELDS OF TABLE @lt_salesconta.
      SORT lt_salesconta BY salescontract product salescontractitem.

      lt_group = lt_salesconta.
      SORT lt_salesconta BY salescontract product salescontractitem.
      DELETE ADJACENT DUPLICATES FROM lt_group COMPARING salescontract product.

      IF lt_salesconta[] IS NOT INITIAL.
        SELECT *
        FROM I_customer AS a  JOIN zz1_i_address_2 AS b ON b~AddressID = a~AddressID
        FOR ALL ENTRIES IN @lt_salesconta
        WHERE a~customer = @lt_salesconta-soldtoparty  AND a~AddressSearchTerm2 IN @s_name
        INTO CORRESPONDING FIELDS OF TABLE @lt_customer.
      ENDIF.
      SELECT * FROM i_purchaserequisitionitemapi01 WHERE yy1_contract_number_pri IN @s_contr[] AND PurchaseRequisition IN @s_purch
       INTO CORRESPONDING FIELDS OF TABLE @lt_purchase.
      SORT lt_purchase BY PurchaseRequisition PurchaseRequisitionitem.

      SELECT * FROM ZZ1_I_salescontract3 WHERE GoodsMovementType  IN  @s_mvt AND Reservation IN @s_reser
        INTO CORRESPONDING FIELDS OF TABLE @lt_reservation.
      SORT lt_reservation BY reservation reservationitem.
      LOOP AT lt_reservation INTO lwa_reservation.
        CLEAR : lwa_keys.
        lwa_keys-reservation = lwa_reservation-Reservation.
        APPEND lwa_keys TO lt_keys.
      ENDLOOP.
      READ ENTITIES OF I_ReservationDocumentTP
        ENTITY ReservationDocument
          ALL FIELDS
          WITH CORRESPONDING #( lt_keys )
        RESULT   DATA(lt_header)
        FAILED   DATA(lt_failed)
        REPORTED DATA(lt_reported).
      IF lt_header[] IS NOT INITIAL.
        SORT lt_header BY reservation yy1_contract_number_rd_rdh.
        DELETE lt_header WHERE yy1_contract_number_rd_rdh NOT IN s_contr[].
      ENDIF.
      LOOP AT lt_header INTO DATA(lwa_header).
        LOOP AT lt_reservation INTO lwa_reservation WHERE reservation = lwa_header-Reservation.
          CLEAR :lwa_reservation2.
          MOVE-CORRESPONDING lwa_reservation TO lwa_reservation2.
          lwa_reservation2-yy1_contract_number_pri = lwa_header-yy1_contract_number_rd_rdh.
          APPEND lwa_reservation2 TO lt_reservation2.
        ENDLOOP.
      ENDLOOP.

      LOOP AT lt_group INTO lwa_group.
        CLEAR: lt_groupquan.
        LOOP AT lt_salesconta INTO lwa_salesconta USING KEY key WHERE SalesContract = lwa_group-SalesContract AND product = lwa_group-product...
          CLEAR: lwa_data,lwa_customer,lt_data2, lt_groupquan2.
          CLEAR: l_totalquan,l_totalquan2.
          SHIFT lwa_salesconta-SalesContract LEFT DELETING LEADING '0'.
          lwa_data-salescontract = lwa_salesconta-SalesContract.
          lwa_data-purchaseorderbycustomer = lwa_salesconta-PurchaseOrderByCustomer.
          lwa_data-SalesContractDate = lwa_salesconta-SalesContractDate.
          lwa_data-soldtoparty = lwa_salesconta-soldtoparty.
          READ TABLE lt_customer INTO lwa_customer WITH KEY customer = lwa_salesconta-soldtoparty.
          CHECK lwa_customer-addresssearchterm2 IN s_name[].
          lwa_data-Name = lwa_customer-addresssearchterm2.
          lwa_data-salescontractitem = lwa_salesconta-salescontractitem.
          lwa_data-product = lwa_salesconta-product.
          lwa_data-salescontractitemtext = lwa_salesconta-salescontractitemtext.
          lwa_data-yy1_staging_plant1_sdi = lwa_salesconta-yy1_staging_plant1_sdi.
          lwa_data-plant = lwa_salesconta-plant.
          lwa_data-orderquantityunit = lwa_salesconta-OrderQuantityUnit.
          lwa_data-orderquantity = lwa_salesconta-OrderQuantity.
          lwa_data-unreleasedquantity = lwa_salesconta-OrderQuantity.
          lwa_data-releasedquantity = 0.
          l_totalquan = lwa_salesconta-OrderQuantity.
          lwa_data-createdbyuser = lwa_salesconta-CreatedByUser.
          lwa_data-creationdate  = lwa_salesconta-creationdate.
          APPEND lwa_data TO lt_data2.

          CLEAR: lwa_groupquan.
          lwa_groupquan-SalesContract = lwa_group-SalesContract.
          SHIFT lwa_groupquan-SalesContract LEFT DELETING LEADING '0'.
          lwa_groupquan-product = lwa_group-product.
          lwa_groupquan-SalesContractItemText = '小計'.
          lwa_groupquan-orderquantityunit = lwa_salesconta-OrderQuantityUnit.
          lwa_groupquan-orderquantity = lwa_salesconta-OrderQuantity.
          lwa_groupquan-unreleasedquantity = lwa_salesconta-OrderQuantity.
          APPEND lwa_groupquan TO lt_groupquan2.

          LOOP AT lt_reservation2 INTO lwa_reservation2 USING KEY key WHERE yy1_contract_number_pri = lwa_salesconta-SalesContract AND product = lwa_salesconta-product.
            CLEAR:lwa_data.
            lwa_data-salescontract = lwa_salesconta-SalesContract.
            lwa_data-purchaseorderbycustomer = lwa_salesconta-PurchaseOrderByCustomer.
            lwa_data-SalesContractDate = lwa_salesconta-SalesContractDate.
            lwa_data-soldtoparty = lwa_salesconta-soldtoparty.
            lwa_data-Name = lwa_customer-addresssearchterm2.
            lwa_data-salescontractitem = lwa_salesconta-salescontractitem.
            lwa_data-product = lwa_salesconta-product.
            lwa_data-salescontractitemtext = lwa_salesconta-salescontractitemtext.
            lwa_data-yy1_staging_plant1_sdi = lwa_salesconta-yy1_staging_plant1_sdi.
            lwa_data-plant = lwa_salesconta-plant.

            lwa_data-orderquantityunit = lwa_salesconta-OrderQuantityUnit.
            lwa_data-orderquantity = lwa_salesconta-OrderQuantity.
            lwa_data-reservation = lwa_reservation2-Reservation.
            lwa_data-reservationitem = lwa_reservation2-ReservationItem.
            lwa_data-goodsmovementtype = lwa_reservation2-GoodsMovementType.
            lwa_data-ResvnItmRequiredQtyInEntryUnit = lwa_reservation2-ResvnItmRequiredQtyInEntryUnit.
            l_totalquan -= lwa_reservation2-ResvnItmRequiredQtyInEntryUnit.
            l_totalquan2 += lwa_reservation2-ResvnItmRequiredQtyInEntryUnit.
*          lwa_data-unreleasedquantity = l_totalquan.
*          lwa_data-releasedquantity = l_totalquan2.
            lwa_data-unreleasedquantity = -1 * lwa_reservation2-ResvnItmRequiredQtyInEntryUnit..
            lwa_data-releasedquantity = lwa_reservation2-ResvnItmRequiredQtyInEntryUnit..
            APPEND lwa_data TO lt_data2.

            CLEAR: lwa_groupquan.
            lwa_groupquan-SalesContract = lwa_group-SalesContract.
            SHIFT lwa_groupquan-SalesContract LEFT DELETING LEADING '0'.
            lwa_groupquan-product = lwa_group-product.
            lwa_groupquan-SalesContractItemText = '小計'.
            lwa_groupquan-orderquantityunit = lwa_salesconta-OrderQuantityUnit.
            lwa_groupquan-unreleasedquantity = -1 * lwa_reservation2-ResvnItmRequiredQtyInEntryUnit..
            lwa_groupquan-releasedquantity = lwa_reservation2-ResvnItmRequiredQtyInEntryUnit.
            APPEND lwa_groupquan TO lt_groupquan2.
          ENDLOOP.

          LOOP AT lt_purchase INTO lwa_purchase USING KEY key WHERE yy1_contract_number_pri = lwa_salesconta-SalesContract AND Material =  lwa_salesconta-product.
            CLEAR : lwa_data.
            lwa_data-salescontract = lwa_salesconta-SalesContract.
            lwa_data-purchaseorderbycustomer = lwa_salesconta-PurchaseOrderByCustomer.
            lwa_data-SalesContractDate = lwa_salesconta-SalesContractDate.
            lwa_data-soldtoparty = lwa_salesconta-soldtoparty.
            lwa_data-Name = lwa_customer-addresssearchterm2.
            lwa_data-salescontractitem = lwa_salesconta-salescontractitem.
            lwa_data-product = lwa_salesconta-product.
            lwa_data-salescontractitemtext = lwa_salesconta-salescontractitemtext.
            lwa_data-yy1_staging_plant1_sdi = lwa_salesconta-yy1_staging_plant1_sdi.
            lwa_data-plant = lwa_salesconta-plant.

            lwa_data-orderquantityunit = lwa_salesconta-OrderQuantityUnit.
            lwa_data-orderquantity = lwa_salesconta-OrderQuantity.
            lwa_data-purchaserequisition = lwa_purchase-PurchaseRequisition.
            lwa_data-purchaserequisitionitem = lwa_purchase-PurchaseRequisitionitem.
            lwa_data-OrderedQuantity  =  lwa_purchase-PurReqnPriceQuantity.
            l_totalquan -= lwa_purchase-PurReqnPriceQuantity.
            l_totalquan2 += lwa_purchase-PurReqnPriceQuantity.
*          lwa_data-unreleasedquantity = l_totalquan.
*          lwa_data-releasedquantity = l_totalquan2.
            lwa_data-unreleasedquantity = -1 * lwa_purchase-PurReqnPriceQuantity.
            lwa_data-releasedquantity = lwa_purchase-PurReqnPriceQuantity.
            APPEND lwa_data TO lt_data2.

            CLEAR: lwa_groupquan.
            lwa_groupquan-SalesContract = lwa_group-SalesContract.
            SHIFT lwa_groupquan-SalesContract LEFT DELETING LEADING '0'.
            lwa_groupquan-product = lwa_group-product.
            lwa_groupquan-SalesContractItemText = '小計'.
            lwa_groupquan-orderquantityunit = lwa_salesconta-OrderQuantityUnit.
            lwa_groupquan-unreleasedquantity = -1 * lwa_purchase-PurReqnPriceQuantity.
            lwa_groupquan-releasedquantity = lwa_purchase-PurReqnPriceQuantity.
            APPEND lwa_groupquan TO lt_groupquan2.
          ENDLOOP.

          IF l_totalquan2 <> lwa_salesconta-OrderQuantity.
            APPEND LINES OF lt_data2 TO lt_data.
            LOOP AT lt_groupquan2 INTO lwa_groupquan.
              COLLECT lwa_groupquan INTO lt_groupquan.
            ENDLOOP..
          ENDIF.
*                clear:lwa_data , lwa_customer.
*                lwa_data-salescontract = lwa_salesconta-SalesContract.
*                lwa_data-purchaseorderbycustomer = lwa_salesconta-PurchaseOrderByCustomer.
*                lwa_data-SalesContractDate = lwa_salesconta-SalesContractDate.
*                lwa_data-soldtoparty = lwa_salesconta-soldtoparty.
*                READ TABLE lt_customer INTO lwa_customer WITH KEY customer = lwa_salesconta-soldtoparty.
*                lwa_data-Name = lwa_customer-addresssearchterm2.
*                lwa_data-salescontractitem = lwa_salesconta-salescontractitem.
*                lwa_data-product = lwa_salesconta-product.
*                lwa_data-salescontractitemtext = lwa_salesconta-salescontractitemtext.
*                lwa_data-plant = lwa_salesconta-plant.
*                lwa_data-orderquantityunit = lwa_salesconta-OrderQuantityUnit.
*                lwa_data-orderquantity = lwa_salesconta-OrderQuantity.
*                lwa_data-unreleasedquantity = l_totalquan.
*                lwa_data-releasedquantity = l_totalquan2.
*                lwa_data-createdbyuser = lwa_salesconta-CreatedByUser.
*                lwa_data-creationdate  = lwa_salesconta-creationdate.
*                APPEND lwa_data TO lt_data.
        ENDLOOP.
        CLEAR lt_data2.
        MOVE-CORRESPONDING lt_groupquan TO lt_data2.
        APPEND LINES OF lt_data2 TO lt_data.
      ENDLOOP..




      l_total = lines( lt_data ).

      IF l_offset = 0.
        l_offset_next = l_size + 1.
        DELETE lt_data FROM l_offset_next .
      ELSE.
        l_offset_next = l_offset + l_size + 1.
        DELETE lt_data FROM l_offset_next .
        DELETE lt_data FROM 1 TO l_offset.
      ENDIF.

      io_response->set_total_number_of_records( l_total ).
      io_response->set_data( lt_data ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
