*&---------------------------------------------------------------------*
*& Include          ZFI_RDV_BB_REPROCESS_O01
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b0 WITH FRAME TITLE TEXT-t01.

PARAMETERS: p_433 RADIOBUTTON GROUP type DEFAULT 'X' USER-COMMAND check,
            p_435 RADIOBUTTON GROUP type,
            p_798 RADIOBUTTON GROUP type.

SELECTION-SCREEN END OF BLOCK b0.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t02.

SELECT-OPTIONS: s_bukrs  FOR t001-bukrs NO INTERVALS,
                s_kostl  FOR cskt-kostl NO INTERVALS,
                s_cartao FOR ztrdv002-cartao NO INTERVALS MODIF ID sl2,
                s_datar  FOR sy-datum,
                s_datae  FOR sy-datum MODIF ID sl2,
                s_datac  FOR sy-datum MODIF ID sl3.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-t03 .

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 20(15) TEXT-t04 MODIF ID sl1.
PARAMETERS: p_max TYPE i DEFAULT 1000 MODIF ID sl1.

SELECTION-SCREEN POSITION 60.
PARAMETERS: p_200 AS CHECKBOX DEFAULT ' ' MODIF ID sl1.
SELECTION-SCREEN COMMENT 62(26) TEXT-t05 MODIF ID sl1.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK b2.


*--------------------------------------------------------------------*
* AT SELECTION SCREEN
*--------------------------------------------------------------------*

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_kostl-low.

  TYPES: BEGIN OF ty_kostl,
           empresa      TYPE bukrs,
           centro_custo TYPE kostl,
           descricao    TYPE text40,
         END OF ty_kostl.

  DATA: lt_kostl  TYPE TABLE OF ty_kostl,
        lt_return TYPE STANDARD TABLE OF ddshretval WITH HEADER LINE.

  SELECT empresa, centro_custo, descricao
    FROM ztrdv006
    INTO TABLE @lt_kostl
    WHERE empresa IN @s_bukrs.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CENTRO_CUSTO'
      dynpprog        = sy-repid
      dynpnr          = '1000'
      dynprofield     = 'S_KOSTL-LOW'
      window_title    = 'Centro Custo'
      value_org       = 'S'
    TABLES
      value_tab       = lt_kostl
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_cartao-low.

  TYPES: BEGIN OF ty_cartao,
           empresa          TYPE bukrs,
           num_centro_custo TYPE kostl,
           cartao           TYPE zidcartao,
           nome_cartao      TYPE char25,
         END OF ty_cartao.

  DATA: lt_cartao TYPE TABLE OF ty_cartao,
        lt_return TYPE STANDARD TABLE OF ddshretval WITH HEADER LINE.

  IF p_433 EQ abap_true.
    IF p_200 EQ abap_true.
      SELECT empresa, num_centro_custo, cartao, nome_cartao
        FROM ztrdv002
        INTO TABLE @lt_cartao
        WHERE empresa IN @s_bukrs
          AND num_centro_custo IN @s_kostl.
    ELSE.
      SELECT empresa, num_centro_custo, cartao, nome_cartao
        FROM ztrdv002
        INTO TABLE @lt_cartao
        WHERE empresa IN @s_bukrs
          AND num_centro_custo IN @s_kostl
          AND cod_ret = '500'.
    ENDIF.

  ELSEIF p_435 EQ abap_true.
    SELECT empresa, num_centro_custo, cartao, nome_cartao
      FROM ztrdv003
      INTO TABLE @lt_cartao
      WHERE empresa IN @s_bukrs
        AND num_centro_custo IN @s_kostl.

  ELSEIF p_798 EQ abap_true.
    SELECT empresa, centro_custo, num_cartao, nome_cartao
      FROM ztrdv004
      INTO TABLE @lt_cartao
      WHERE empresa IN @s_bukrs
      AND centro_custo IN @s_kostl.

  ENDIF.

  SORT lt_cartao BY empresa num_centro_custo cartao.
  DELETE ADJACENT DUPLICATES FROM lt_cartao.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CARTAO'
      dynpprog        = sy-repid
      dynpnr          = '1000'
      dynprofield     = 'S_CARTAO-LOW'
      window_title    = 'N° Cartão'
      value_org       = 'S'
    TABLES
      value_tab       = lt_cartao
      return_tab      = lt_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.


*----------------------------------------------------------------------*
*  Verificação de Seleção de Operação para tipos Arquivos              *
*----------------------------------------------------------------------*
AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.

    IF screen-group1 = 'SL1'.
      IF NOT p_433 IS INITIAL.
        screen-active = 1.
      ELSE.
        screen-active = 0.
      ENDIF.
    ENDIF.

    IF screen-group1 = 'SL2'.
      IF NOT p_435 IS INITIAL.
        screen-active = 0.
      ELSE.
        screen-active = 1.
      ENDIF.
    ENDIF.

    IF screen-group1 = 'SL3'.
      IF NOT p_435 IS INITIAL OR NOT p_798 IS INITIAL.
        screen-active = 0.
      ELSE.
        screen-active = 1.
      ENDIF.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.
