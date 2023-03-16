*&---------------------------------------------------------------------*
*& Report ZFI_RDV_BB_CC
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zfi_rdv_bb_cc.

INCLUDE zfi_rdv_bb_cc_top                       .  " Global Data
INCLUDE zfi_rdv_bb_cc_o01                       .  " PBO-Modules
* INCLUDE ZFI_RDV_BB_CC_I01                       .  " PAI-Modules
INCLUDE zfi_rdv_bb_cc_f01                       .  " FORM-Routines

*--------------------------------------------------------------------*
* START-OF-SELECTION
*--------------------------------------------------------------------*
START-OF-SELECTION.

  DATA: lv_c19(19) TYPE c,
        lv_len     TYPE i.

  gv_pernr = p_pernr.
  gv_cpf = p_cpf.
  gv_cartao = p_cartao.
  gv_begda = p_begda.
  gv_endda = p_endda.

  " Verifica se N° Pessoal ou CPF preenchidos
  IF gv_pernr IS INITIAL AND gv_cpf IS INITIAL.
    MESSAGE 'Preenchimento de N° Pessoal ou CPF obrigatório.' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  " Verifica dados se N° Pessoal e CPF preenchidos
  IF gv_pernr IS NOT INITIAL AND gv_cpf IS NOT INITIAL.
    PERFORM f_chek_data.
    IF gv_message IS NOT INITIAL.
      MESSAGE gv_message TYPE 'S' DISPLAY LIKE 'E'.
      EXIT.
    ENDIF.
  ENDIF.

  " Se somente CPF preenchido busca N° Pessoal
  IF gv_pernr IS INITIAL AND  gv_cpf IS NOT INITIAL.
    PERFORM f_get_pernr.
    IF gv_message IS NOT INITIAL.
      MESSAGE gv_message TYPE 'S' DISPLAY LIKE 'E'.
      EXIT.
    ENDIF.
  ENDIF.

  " Verifica padrão cartão e registra cartão
  lv_len = strlen( gv_cartao ).
  IF lv_len NE 16.
    MESSAGE 'Preenchimento cartão incorreto.' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ELSE.
    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
      EXPORTING
        input  = gv_cartao
      IMPORTING
        output = lv_c19.

    gv_cartao = 'BB' && lv_c19.

    SELECT SINGLE pernr FROM pa0105
      INTO gv_pernr
      WHERE subty = '0011'
        AND usrid = gv_cartao.

    IF sy-subrc IS INITIAL.

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = gv_pernr
        IMPORTING
          output = gv_message.

      CONCATENATE 'Cartão ja cadastrado para N° Pessoal:' gv_message '.' INTO gv_message.
      MESSAGE gv_message TYPE 'S' DISPLAY LIKE 'E'.
    ELSE.

      PERFORM f_get_name.

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = gv_pernr
        IMPORTING
          output = gv_text2.

      CONCATENATE 'Você irá gravar o cartão' p_cartao INTO gv_text1 SEPARATED BY space.
      CONCATENATE gv_text2 '-' gv_name INTO gv_text2 SEPARATED BY space.
      gv_text3 = 'Confirma dados?'.

      CALL FUNCTION 'COPO_POPUP_TO_GOON'
        EXPORTING
          textline1 = gv_text1
          textline2 = gv_text2
          textline3 = gv_text3
          titel     = 'Gravar Cartão'
        IMPORTING
          answer    = confirmation.
      IF confirmation = 'G'.
        " Registra Cartão
        PERFORM f_registra_cartao.

        IF NOT gs_return-message IS INITIAL.
          MESSAGE gs_return-message TYPE 'S' DISPLAY LIKE 'E'.
        ELSE.
          MESSAGE  'Cartão gravado com sucesso.' TYPE 'S'.
        ENDIF.
      ELSE.
        MESSAGE  'Operação Cancelada.' TYPE 'S' DISPLAY LIKE 'I'.
      ENDIF.
    ENDIF.
  ENDIF.
