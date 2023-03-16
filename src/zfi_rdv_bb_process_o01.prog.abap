*&---------------------------------------------------------------------*
*& Include          ZFI_RDV_BB_PROCESS_O01
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b0 WITH FRAME TITLE TEXT-t01.

SELECT-OPTIONS: s_bukrs FOR t001-bukrs NO INTERVALS,
                s_data FOR sy-datum.


SELECTION-SCREEN END OF BLOCK b0.

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t02.

PARAMETERS: p_433 AS CHECKBOX USER-COMMAND check,
            p_435 AS CHECKBOX,
            p_798 AS CHECKBOX.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-t03.

PARAMETERS: p_max TYPE i DEFAULT 1000 MODIF ID sl1.

SELECTION-SCREEN END OF BLOCK b2.


AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.

    IF screen-group1 = 'SL1'.
      IF NOT p_433 IS INITIAL.
        screen-active = 1.
      ELSE.
        screen-active = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
    ENDLOOP.
