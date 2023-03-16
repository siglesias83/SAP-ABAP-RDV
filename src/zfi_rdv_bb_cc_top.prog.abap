*&---------------------------------------------------------------------*
*& Include ZFI_RDV_BB_CC_TOP                        - Report ZFI_RDV_BB_CC
*&---------------------------------------------------------------------*

DATA: gv_pernr     TYPE persno,
      gv_cpf       TYPE pbr_cpfnr,
      gv_cartao    TYPE ad_smtpadr,
      gv_begda     TYPE datum,
      gv_endda     TYPE datum,
      gs_return    TYPE bapireturn1,
      gv_message   TYPE bapi_msg,
      gv_name(80)  TYPE c,
      gv_text1(70) TYPE c,
      gv_text2(70) TYPE c,
      gv_text3(70) TYPE c,
      confirmation.
