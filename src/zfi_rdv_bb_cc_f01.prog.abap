*&---------------------------------------------------------------------*
*& Include          ZFI_RDV_BB_CC_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form F_CHEK_DATA
*&---------------------------------------------------------------------*
*& Verifica dados RE -> CPF
*&---------------------------------------------------------------------*
FORM f_chek_data .
  SELECT COUNT(*) FROM pa0465
    WHERE pernr EQ gv_pernr
      AND cpf_nr EQ gv_cpf.

  IF sy-subrc IS NOT INITIAL.
    gv_message = 'CPF não pertence a este N° Pessoal.' .
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_PERNR
*&---------------------------------------------------------------------*
*& Busca RE pelo CPF
*&---------------------------------------------------------------------*
FORM f_get_pernr .
  SELECT SINGLE pernr FROM pa0465
    INTO gv_pernr
    WHERE subty EQ '0001'
      AND endda GE sy-datum
      AND begda LE sy-datum
      AND cpf_nr EQ gv_cpf.

  IF sy-subrc IS NOT INITIAL.
    gv_message = 'CPF não localizado.'.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_REGISTRA_CARTAO
*&---------------------------------------------------------------------*
*&  Cria cartão crédito dados RH
*&  Infotipo 0105 - Comunicação
*&  Tipo 0011 - Número(s) cartão de crédito
*&---------------------------------------------------------------------*
FORM f_registra_cartao.

  CALL FUNCTION 'BAPI_EMPLOYEE_ENQUEUE'
    EXPORTING
      number = gv_pernr
    IMPORTING
      return = gs_return.

  IF gs_return IS INITIAL.
    CALL FUNCTION 'BAPI_EMPLCOMM_CREATE'
      EXPORTING
        employeenumber  = gv_pernr
        subtype         = '0011'
        validitybegin   = gv_begda
        validityend     = gv_endda
        communicationid = gv_cartao
      IMPORTING
        return          = gs_return.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*& Form F_GET_NAME
*&---------------------------------------------------------------------*
*& Retorna nome com base em RE
*&---------------------------------------------------------------------*
FORM f_get_name .
  DATA: lv_vorna TYPE pad_vorna,
        lv_nachn TYPE pad_nachn.

  SELECT SINGLE vorna nachn FROM pa0002
    INTO ( lv_vorna , lv_nachn )
    WHERE pernr EQ gv_pernr
    AND endda GE sy-datum
      AND begda LE sy-datum.

  CONCATENATE lv_vorna lv_nachn INTO gv_name SEPARATED BY space.
ENDFORM.
