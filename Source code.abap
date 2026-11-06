*&---------------------------------------------------------------------*
*& Report ZMA_FI_REPORT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZMA_FI_REPORT.


TYPE-POOLS: slis.

TABLES: lfa1, bsik, bkpf.

*---------------------------------------------------------------------*
* SELECTION SCREEN
*---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1
  WITH FRAME TITLE TEXT-001.

SELECT-OPTIONS:
  s_bukrs FOR bsik-bukrs,
  s_lifnr FOR lfa1-lifnr,
  s_budat FOR bkpf-budat.

PARAMETERS:
  p_open  AS CHECKBOX DEFAULT 'X',
  p_close AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b1.

*---------------------------------------------------------------------*
* TYPES
*---------------------------------------------------------------------*

TYPES: BEGIN OF str_vendor,

         status     TYPE char10,
         line_color TYPE char4,

         bukrs      TYPE bsik-bukrs,
         lifnr      TYPE lfa1-lifnr,
         name1      TYPE lfa1-name1,

         belnr      TYPE bkpf-belnr,
         gjahr      TYPE bkpf-gjahr,
         buzei      TYPE bsik-buzei,

         blart      TYPE bkpf-blart,
         bldat      TYPE bkpf-bldat,
         budat      TYPE bkpf-budat,

         usnam      TYPE bkpf-usnam,

         shkzg      TYPE bsik-shkzg,
         wrbtr      TYPE bsik-wrbtr,
         waers      TYPE bkpf-waers,

       END OF str_vendor.

TYPES it_vendor TYPE STANDARD TABLE OF str_vendor
                WITH DEFAULT KEY.

*---------------------------------------------------------------------*
* CLASS DEFINITION
*---------------------------------------------------------------------*

CLASS vender DEFINITION.

  PUBLIC SECTION.

    METHODS:
      get_data,
      display_alv.

  PRIVATE SECTION.

    DATA:
      it_data     TYPE it_vendor,
      it_temp     TYPE it_vendor,
      it_fieldcat TYPE slis_t_fieldcat_alv,
      wa_layout   TYPE slis_layout_alv.

    METHODS:
      get_open_items,
      get_cleard_items,
      bulid_fieldcat,
      layout.

ENDCLASS.

*---------------------------------------------------------------------*
* CLASS IMPLEMENTATION
*---------------------------------------------------------------------*

CLASS vender IMPLEMENTATION.

  METHOD get_data.

    CLEAR it_data.

    IF p_open = 'X'.
      get_open_items( ).
    ENDIF.

    IF p_close = 'X'.
      get_cleard_items( ).
    ENDIF.

  ENDMETHOD.

*---------------------------------------------------------------------*
* GET OPEN ITEMS
*---------------------------------------------------------------------*

  METHOD get_open_items.

    DATA wa_temp TYPE str_vendor.

    CLEAR it_temp.

    SELECT
      a~bukrs,
      a~lifnr,
      b~name1,
      a~belnr,
      a~gjahr,
      a~buzei,
      c~blart,
      c~bldat,
      c~budat,
      c~usnam,
      a~shkzg,
      a~wrbtr,
      c~waers

      FROM bsik_view AS a

      INNER JOIN lfa1 AS b
        ON a~lifnr = b~lifnr

      INNER JOIN bkpf AS c
        ON  a~bukrs = c~bukrs
        AND a~belnr = c~belnr
        AND a~gjahr = c~gjahr

      WHERE a~bukrs IN @s_bukrs
        AND a~lifnr IN @s_lifnr
        AND c~budat IN @s_budat

      INTO CORRESPONDING FIELDS OF TABLE @it_temp.

    LOOP AT it_temp INTO wa_temp.

      wa_temp-status = 'OPEN'.

      IF wa_temp-shkzg = 'H'.
        wa_temp-wrbtr = wa_temp-wrbtr * -1.
      ENDIF.

      MODIFY it_temp FROM wa_temp INDEX sy-tabix.

    ENDLOOP.

    APPEND LINES OF it_temp TO it_data.

  ENDMETHOD.

*---------------------------------------------------------------------*
* GET CLEARED ITEMS
*---------------------------------------------------------------------*

  METHOD get_cleard_items.

    DATA wa_temp TYPE str_vendor.

    CLEAR it_temp.

    SELECT
      a~bukrs,
      a~lifnr,
      b~name1,
      a~belnr,
      a~gjahr,
      a~buzei,
      c~blart,
      c~bldat,
      c~budat,
      c~usnam,
      a~shkzg,
      a~wrbtr,
      c~waers

      FROM bsak_view AS a

      INNER JOIN lfa1 AS b
        ON a~lifnr = b~lifnr

      INNER JOIN bkpf AS c
        ON  a~bukrs = c~bukrs
        AND a~belnr = c~belnr
        AND a~gjahr = c~gjahr

      WHERE a~bukrs IN @s_bukrs
        AND a~lifnr IN @s_lifnr
        AND c~budat IN @s_budat

      INTO CORRESPONDING FIELDS OF TABLE @it_temp.

    LOOP AT it_temp INTO wa_temp.

      wa_temp-status = 'CLEARED'.

      IF wa_temp-shkzg = 'H'.
        wa_temp-wrbtr = wa_temp-wrbtr * -1.
      ENDIF.

      MODIFY it_temp FROM wa_temp INDEX sy-tabix.

    ENDLOOP.

    APPEND LINES OF it_temp TO it_data.

  ENDMETHOD.

*---------------------------------------------------------------------*
* BUILD FIELD CATALOG
*---------------------------------------------------------------------*

  METHOD bulid_fieldcat.

    DATA wa_fieldcat TYPE slis_fieldcat_alv.

    CLEAR it_fieldcat.

    DEFINE add_column.

      CLEAR wa_fieldcat.

      wa_fieldcat-fieldname = &1.
      wa_fieldcat-seltext_m = &2.
      wa_fieldcat-outputlen = &3.

      APPEND wa_fieldcat TO it_fieldcat.

    END-OF-DEFINITION.

    add_column 'STATUS'  'Status'         12.
    add_column 'BUKRS'   'Company'        10.
    add_column 'LIFNR'   'Vendor'         12.
    add_column 'NAME1'   'Vendor Name'    25.
    add_column 'BELNR'   'Document'       15.
    add_column 'GJAHR'   'Fiscal Year'    10.
    add_column 'BUZEI'   'Item'             8.
    add_column 'BLART'   'Doc Type'       10.
    add_column 'BLDAT'   'Doc Date'       12.
    add_column 'BUDAT'   'Posting Date'   12.
    add_column 'USNAM'   'Created By'     15.
    add_column 'SHKZG'   'Debit/Credit'   12.
    add_column 'WRBTR'   'Amount'         15.
    add_column 'WAERS'   'Currency'       10.

    READ TABLE it_fieldcat
      INTO wa_fieldcat
      WITH KEY fieldname = 'WRBTR'.

    IF sy-subrc = 0.

      wa_fieldcat-cfieldname = 'WAERS'.

      MODIFY it_fieldcat FROM wa_fieldcat
        INDEX sy-tabix.

    ENDIF.

  ENDMETHOD.

*---------------------------------------------------------------------*
* LAYOUT
*---------------------------------------------------------------------*

  METHOD layout.

    DATA wa_data TYPE str_vendor.

    CLEAR wa_layout.

    wa_layout-info_fieldname = 'LINE_COLOR'.
    wa_layout-colwidth_optimize = 'X'.

    LOOP AT it_data INTO wa_data.

      IF wa_data-status = 'OPEN'.

        wa_data-line_color = 'C310'.

      ELSEIF wa_data-status = 'CLEARED'.

        wa_data-line_color = 'C510'.

      ENDIF.

      MODIFY it_data FROM wa_data INDEX sy-tabix.

    ENDLOOP.

  ENDMETHOD.

*---------------------------------------------------------------------*
* DISPLAY ALV
*---------------------------------------------------------------------*

  METHOD display_alv.

    IF it_data IS INITIAL.

      MESSAGE 'No data found' TYPE 'I'.
      RETURN.

    ENDIF.

    bulid_fieldcat( ).

    layout( ).

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'

      EXPORTING
        i_callback_program       = sy-repid
        i_callback_top_of_page   = 'TOP_OF_PAGE'
        is_layout                = wa_layout
        it_fieldcat              = it_fieldcat

      TABLES
        t_outtab                 = it_data.

    IF sy-subrc <> 0.

      MESSAGE 'Error displaying ALV' TYPE 'E'.

    ENDIF.

  ENDMETHOD.

ENDCLASS.

*---------------------------------------------------------------------*
* TOP OF PAGE
*---------------------------------------------------------------------*

FORM top_of_page.

  DATA:
    it_listheader TYPE slis_t_listheader,
    wa_listheader TYPE slis_listheader.

  CLEAR wa_listheader.

  wa_listheader-typ = 'H'.
  wa_listheader-info = 'VENDOR FINANCIAL REPORT'.

  APPEND wa_listheader TO it_listheader.

  CLEAR wa_listheader.

  wa_listheader-typ = 'S'.
  wa_listheader-key = 'DATE'.

  CONCATENATE sy-datum+6(2)
              sy-datum+4(2)
              sy-datum(4)
         INTO wa_listheader-info
         SEPARATED BY '/'.

  APPEND wa_listheader TO it_listheader.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'

    EXPORTING
      it_list_commentary = it_listheader.

ENDFORM.

*---------------------------------------------------------------------*
* START OF SELECTION
*---------------------------------------------------------------------*

START-OF-SELECTION.

  DATA lo_obj TYPE REF TO vender.

  CREATE OBJECT lo_obj.

  lo_obj->get_data( ).

  lo_obj->display_alv( ).
