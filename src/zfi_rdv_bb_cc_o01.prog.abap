*&---------------------------------------------------------------------*
*& Include          ZFI_RDV_BB_CC_O01
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b0 WITH FRAME TITLE TEXT-t01.

PARAMETERS: p_pernr      TYPE persno,
            p_cpf        TYPE pbr_cpfnr,
            p_cartao(16) TYPE n OBLIGATORY,
            p_begda      TYPE datum DEFAULT sy-datum OBLIGATORY,
            p_endda      TYPE datum DEFAULT '999912311' OBLIGATORY.

SELECTION-SCREEN END OF BLOCK b0.
