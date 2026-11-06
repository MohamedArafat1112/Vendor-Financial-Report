
REPORT zma_fi_report.

TYPE-POOLS: slis.

TABLES: lfa1, bsik, bkpf.

*---------------------------------------------------------------------*
* SELECTION SCREEN
*---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

SELECT-OPTIONS:
  s_bukrs FOR bsik-bukrs,
  s_lifnr FOR lfa1-lifnr,
  s_budat FOR bkpf-budat.

PARAMETERS:
  p_open  AS CHECKBOX DEFAULT 'X',
  p_clear AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b1.

*---------------------------------------------------------------------*
* TYPES
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_vendor,

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

       END OF ty_vendor.

TYPES tt_vendor TYPE STANDARD TABLE OF ty_vendor
                WITH DEFAULT KEY.

*---------------------------------------------------------------------*
* CLASS DEFINITION
*---------------------------------------------------------------------*

CLASS lcl_vendor_report DEFINITION.

  PUBLIC SECTION.

    METHODS:
      get_data,
      display_alv.

  PRIVATE SECTION.

    DATA:
      gt_data     TYPE tt_vendor,
      gt_temp     TYPE tt_vendor,
      gt_fieldcat TYPE slis_t_fieldcat_alv,
      gs_layout   TYPE slis_layout_alv.

    METHODS:
      get_open_items,
      get_cleared_items,
      build_fieldcat,
      prepare_layout.

ENDCLASS.

*---------------------------------------------------------------------*
* CLASS IMPLEMENTATION
*---------------------------------------------------------------------*

CLASS lcl_vendor_report IMPLEMENTATION.

*---------------------------------------------------------------------*
* GET DATA
*---------------------------------------------------------------------*

  METHOD get_data.

    CLEAR gt_data.

    IF p_open = 'X'.
      get_open_items( ).
    ENDIF.

    IF p_clear = 'X'.
      get_cleared_items( ).
    ENDIF.

  ENDMETHOD.

*---------------------------------------------------------------------*
* GET OPEN ITEMS
*---------------------------------------------------------------------*

  METHOD get_open_items.

    CLEAR gt_temp.

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

      INTO CORRESPONDING FIELDS OF TABLE @gt_temp.

    LOOP AT gt_temp ASSIGNING FIELD-SYMBOL(<fs>).

      <fs>-status = 'OPEN'.

      IF <fs>-shkzg = 'H'.
        <fs>-wrbtr = <fs>-wrbtr * -1.
      ENDIF.

    ENDLOOP.

    APPEND LINES OF gt_temp TO gt_data.

  ENDMETHOD.

*---------------------------------------------------------------------*
* GET CLEARED ITEMS
*---------------------------------------------------------------------*

  METHOD get_cleared_items.

    CLEAR gt_temp.

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

      INTO CORRESPONDING FIELDS OF TABLE @gt_temp.

    LOOP AT gt_temp ASSIGNING FIELD-SYMBOL(<fs>).

      <fs>-status = 'CLEARED'.

      IF <fs>-shkzg = 'H'.
        <fs>-wrbtr = <fs>-wrbtr * -1.
      ENDIF.

    ENDLOOP.

    APPEND LINES OF gt_temp TO gt_data.

  ENDMETHOD.

*---------------------------------------------------------------------*
* BUILD FIELD CATALOG
*---------------------------------------------------------------------*

  METHOD build_fieldcat.

    CLEAR gt_fieldcat.

    DATA ls_fieldcat TYPE slis_fieldcat_alv.

    DEFINE add_column.

      CLEAR ls_fieldcat.

      ls_fieldcat-fieldname = &1.
      ls_fieldcat-seltext_m = &2.
      ls_fieldcat-outputlen = &3.

      APPEND ls_fieldcat TO gt_fieldcat.

    END-OF-DEFINITION.

    add_column 'STATUS'  'Status'         12.
    add_column 'BUKRS'   'Company'        10.
    add_column 'LIFNR'   'Vendor'         12.
    add_column 'NAME1'   'Vendor Name'    25.
    add_column 'BELNR'   'Document'       15.
    add_column 'GJAHR'   'Fiscal Year'    10.
    add_column 'BUZEI'   'Item'            8.
    add_column 'BLART'   'Doc Type'       10.
    add_column 'BLDAT'   'Doc Date'       12.
    add_column 'BUDAT'   'Posting Date'   12.
    add_column 'USNAM'   'Created By'     15.
    add_column 'SHKZG'   'Debit/Credit'   12.
    add_column 'WRBTR'   'Amount'         15.
    add_column 'WAERS'   'Currency'       10.

    "Currency Reference

    READ TABLE gt_fieldcat
      ASSIGNING FIELD-SYMBOL(<fc>)
      WITH KEY fieldname = 'WRBTR'.

    IF sy-subrc = 0.
      <fc>-cfieldname = 'WAERS'.
    ENDIF.

  ENDMETHOD.

*---------------------------------------------------------------------*
* PREPARE LAYOUT
*---------------------------------------------------------------------*

  METHOD prepare_layout.

    CLEAR gs_layout.

    "Specify Row Color Field

    gs_layout-info_fieldname = 'LINE_COLOR'.

    "Automatically Optimize Column Width

    gs_layout-colwidth_optimize = 'X'.

    "Loop Through ALV Data

    LOOP AT gt_data ASSIGNING FIELD-SYMBOL(<fs>).

      IF <fs>-status = 'OPEN'.

        <fs>-line_color = 'C310'.

      ELSEIF <fs>-status = 'CLEARED'.

        <fs>-line_color = 'C510'.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

*---------------------------------------------------------------------*
* DISPLAY ALV
*---------------------------------------------------------------------*

  METHOD display_alv.

    IF gt_data IS INITIAL.

      MESSAGE 'No data found' TYPE 'I'.
      RETURN.

    ENDIF.

    "Build Field Catalog

    build_fieldcat( ).

    "Prepare Layout

    prepare_layout( ).

    "Display ALV

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program      = sy-repid
        it_fieldcat             = gt_fieldcat
        is_layout               = gs_layout
        i_callback_top_of_page  = 'TOP_OF_PAGE'
      TABLES
        t_outtab                = gt_data
      EXCEPTIONS
        program_error           = 1
        OTHERS                  = 2.

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

  "Report Title

  wa_listheader-typ = 'H'.
  wa_listheader-info = 'VENDOR FINANCIAL REPORT'.

  APPEND wa_listheader TO it_listheader.

  CLEAR wa_listheader.

  "Current Date

  wa_listheader-typ = 'S'.
  wa_listheader-key = 'DATE'.

  CONCATENATE sy-datum+6(2)
              sy-datum+4(2)
              sy-datum(4)
    INTO wa_listheader-info
    SEPARATED BY '/'.

  APPEND wa_listheader TO it_listheader.

  "Display Header

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = it_listheader.

ENDFORM.

*---------------------------------------------------------------------*
* START OF SELECTION
*---------------------------------------------------------------------*

START-OF-SELECTION.

  DATA go_report TYPE REF TO lcl_vendor_report.

  CREATE OBJECT go_report.

  go_report->get_data( ).

  go_report->display_alv( ).
