*&---------------------------------------------------------------------*
*& Include          ZFI_RDV_BB_PROCESS_O01
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b0 WITH FRAME TITLE TEXT-001.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.

SELECT-OPTIONS: s_bukrs FOR t001-bukrs       MODIF ID itf NO INTERVALS,
                s_data  FOR sy-datum         MODIF ID itf             ,
                s_cc    FOR ztrdv007-cartao  MODIF ID itf NO INTERVALS,
                s_arqf  FOR ztrdv007-arquivo MODIF ID itf             .

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-t03.

PARAMETERS: p_max TYPE i DEFAULT 100 MODIF ID itf.

SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN END OF BLOCK b0.
