*&---------------------------------------------------------------------*
*& PoolMóds.        ZFI_RDV_BB_PROCESS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zfi_rdv_bb_process.

**--------------------------------------------------------------------*
** INCLUDE
**--------------------------------------------------------------------*

INCLUDE zfi_rdv_bb_process_top.     " Global Data
INCLUDE zfi_rdv_bb_process_o01.     " PBO-Modules
"INCLUDE ZFI_RDV_ATUALIZA_I01.      " PAI-Modules
INCLUDE zfi_rdv_bb_process_f01.     " FORM-Routines

*--------------------------------------------------------------------*
* START-OF-SELECTION
*--------------------------------------------------------------------*
START-OF-SELECTION.

  IF p_433 IS INITIAL AND p_435 IS INITIAL AND p_798 IS INITIAL.
    MESSAGE 'Selecionar tipo arquivo.' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  IF s_bukrs IS INITIAL.
    MESSAGE 'Obrigatório preenchimento de empresa.' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  LOOP AT s_bukrs INTO gs_bukrs.
    CLEAR: gs_int_log.

    " Get lista de arquivos para download
    gt_lista_input-empresa = gs_bukrs-low.
    PERFORM f_lista_downloads.

    gs_int_log-data = sy-datum.
    gs_int_log-hora = sy-uzeit.
    gs_int_log-interface = 'lista_download'.
    gs_int_log-empresa = gs_bukrs-low.

    IF gv_msg_error IS INITIAL.
      " Grava Log OK
      gs_int_log-status = '200'.
      INSERT INTO ztrdv001 VALUES @gs_int_log.

      " Seleciona arquivos ja processados
      SELECT 'I' AS sign, 'EQ' AS option, arquivo AS low FROM ztrdv001
        WHERE status = '200'
          AND arquivo <> ''
        INTO TABLE @gr_arquivo.

      SORT gt_lista_output-arquivos BY nome.

      " Processamento de arquivos não processados
      LOOP AT gt_lista_output-arquivos INTO gs_arquivo WHERE NOT nome IS INITIAL.
        IF NOT gr_arquivo IS INITIAL.
          CHECK NOT gs_arquivo-nome IN gr_arquivo.
        ENDIF.

        gv_data_criacao = gs_arquivo-data_criacao(4) && gs_arquivo-data_criacao+5(2) && gs_arquivo-data_criacao+8(2).

        " Tipo arquivo VIPF433 - Fatura Diária Incremental
        IF p_433 EQ 'X' AND gs_arquivo-nome CS 'VIP433' AND gv_data_criacao IN s_data.
          CLEAR: gs_int_log.
          gt_vip433_input-empresa = gs_bukrs-low.
          gt_vip433_input-id = gs_arquivo-id.
          gt_vip433_input-nome = gs_arquivo-nome.
          PERFORM f_download_vip433.

          gs_int_log-data = sy-datum.
          gs_int_log-hora = sy-uzeit.
          gs_int_log-interface = 'download_vip433'.
          gs_int_log-empresa = gs_bukrs-low.
          gs_int_log-arquivo = gs_arquivo-nome.

          IF gv_msg_error IS INITIAL."Grava Log OK ZTRDV001 - Log Interface BB
            gs_int_log-status = '200'.
            INSERT INTO ztrdv001 VALUES @gs_int_log.
            PERFORM f_process_vip433.

          ELSE." Grava Log de Erro ZTRDV001 - Log Interface BB
            gs_int_log-status = '500'.
            gs_int_log-mensagem = gv_msg_error.
            INSERT INTO ztrdv001 VALUES @gs_int_log.
            APPEND gs_int_log TO gt_ztrdv001.
          ENDIF.
        ENDIF.

        " Tipo arquivo VIPF435 - Fatura Mensal
        IF p_435 EQ 'X' AND gs_arquivo-nome CS 'VIP435' AND gv_data_criacao IN s_data.
          CLEAR: gs_int_log.
          gt_vip435_input-empresa = gs_bukrs-low.
          gt_vip435_input-id = gs_arquivo-id.
          gt_vip435_input-nome = gs_arquivo-nome.
          PERFORM f_download_vip435.

          gs_int_log-data = sy-datum.
          gs_int_log-hora = sy-uzeit.
          gs_int_log-interface = 'download_vip435'.
          gs_int_log-empresa = gs_bukrs-low.
          gs_int_log-arquivo = gs_arquivo-nome.

          IF gv_msg_error IS INITIAL." Grava Log OK ZTRDV001 - Log Interface BB
            gs_int_log-status = '200'.
            INSERT INTO ztrdv001 VALUES @gs_int_log.
            PERFORM f_process_vip435.

          ELSE. " Grava Log de Erro ZTRDV001 - Log Interface BB
            gs_int_log-status = '500'.
            gs_int_log-mensagem = gv_msg_error.
            INSERT INTO ztrdv001 VALUES @gs_int_log.
            APPEND gs_int_log TO gt_ztrdv001.
          ENDIF.
        ENDIF.

        " Tipo arquivo VIPF798 - Saques Diários
        IF p_798 EQ 'X' AND gs_arquivo-nome CS 'VIP798' AND gv_data_criacao IN s_data.
          CLEAR: gs_int_log.
          gt_vip798_input-empresa = gs_bukrs-low.
          gt_vip798_input-id = gs_arquivo-id.
          gt_vip798_input-nome = gs_arquivo-nome.
          PERFORM f_download_vip798.

          gs_int_log-data = sy-datum.
          gs_int_log-hora = sy-uzeit.
          gs_int_log-interface = 'download_vip798'.
          gs_int_log-empresa = gs_bukrs-low.
          gs_int_log-arquivo = gs_arquivo-nome.

          IF gv_msg_error IS INITIAL." Grava Log OK ZTRDV001 - Log Interface BB
            gs_int_log-status = '200'.
            INSERT INTO ztrdv001 VALUES @gs_int_log.
            PERFORM f_process_vip798.

          ELSE." Grava Log de Erro ZTRDV001 - Log Interface BB
            gs_int_log-status = '500'.
            gs_int_log-mensagem = gv_msg_error.
            INSERT INTO ztrdv001 VALUES @gs_int_log.
            APPEND gs_int_log TO gt_ztrdv001.
          ENDIF.
        ENDIF.
        "ENDIF.
      ENDLOOP.

    ELSE. " Grava Log de Erro
      gs_int_log-status = '500'.
      gs_int_log-mensagem = gv_msg_error.
      INSERT INTO ztrdv001 VALUES @gs_int_log.
      APPEND gs_int_log TO gt_ztrdv001.
    ENDIF.

    " Verifica erros Interface e envia email
    IF NOT gt_ztrdv001 IS INITIAL.
      CALL FUNCTION 'ZFRDV_EMAIL_INTERFACE'
        TABLES
          ztrdv = gt_ztrdv001.
    ENDIF.

  ENDLOOP.

  " Retorno processamentos
  IF gt_return IS INITIAL.
    MESSAGE 'Processamento finalizado com sucesso.' TYPE 'S'.
  ELSE.
    WRITE / 'Ocorreram erros durante o procesamento:'.
    WRITE /.
    LOOP AT gt_return INTO gs_return.
      WRITE / gs_return-message.
    ENDLOOP.
  ENDIF.
