*&---------------------------------------------------------------------*
*& PoolMóds.        ZFI_RDV_REPROCESS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zfi_rdv_reprocess.

**--------------------------------------------------------------------*
** INCLUDE
**--------------------------------------------------------------------*

INCLUDE zfi_rdv_reprocess_top.     " Global Data
INCLUDE zfi_rdv_reprocess_o01.     " PBO-Modules
"INCLUDE ZFI_RDV_BB_REPROCESS_I01.     " PAI-Modules
INCLUDE zfi_rdv_reprocess_f01.     " FORM-Routines

*--------------------------------------------------------------------*
* START-OF-SELECTION
*--------------------------------------------------------------------*
START-OF-SELECTION.

  IF s_bukrs IS INITIAL.
    MESSAGE 'Obrigatório preenchimento de empresa.' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  " Tipo arquivo VIPF433 - Fatura Diária Incremental
  IF p_433 EQ 'X'.
    PERFORM f_process_vip433.
  ENDIF.

  " Tipo arquivo VIPF435 - Fatura Mensal
  IF p_435 EQ 'X'.
    PERFORM f_process_vip435.
  ENDIF.

  " Tipo arquivo VIPF798 - Saques Diários
  IF p_798 EQ 'X'.
    PERFORM f_process_vip798.
  ENDIF.
