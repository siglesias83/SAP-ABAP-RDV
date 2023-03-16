*&---------------------------------------------------------------------*
*& PoolMóds.        ZFI_RDV_BB_PROCESS
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zfi_rdv_visa_process.

**--------------------------------------------------------------------*
** INCLUDE
**--------------------------------------------------------------------*

INCLUDE zfi_rdv_visa_process_top.
INCLUDE zfi_rdv_visa_process_o01.
INCLUDE zfi_rdv_visa_process_f01.

*--------------------------------------------------------------------*
* START-OF-SELECTION
*--------------------------------------------------------------------*
START-OF-SELECTION.

  LOOP AT s_bukrs INTO gs_bukrs.

    CLEAR: gs_int_log.

    " Get lista de arquivos para download
    gt_lista_input-empresa = gs_bukrs-low.
    PERFORM f_lista_downloads.

    gs_int_log-data = sy-datum.
    gs_int_log-hora = sy-uzeit.
    gs_int_log-interface = 'lista_download_visa'.
    gs_int_log-empresa = gs_bukrs-low.

    IF gt_lista_output-lista[] IS INITIAL.

      gv_msg_error   = 'Nenhum arquivos disponível para processamento.'.

    ENDIF.


    IF gv_msg_error IS INITIAL.

      " Grava Log OK
      gs_int_log-status = '200'.
      INSERT INTO ztrdv001 VALUES @gs_int_log.

      " Seleciona arquivos ja processados
      SELECT 'I' AS sign, 'EQ' AS option, arquivo AS low FROM ztrdv001
        WHERE status = '200'
          AND arquivo <> ''
        INTO TABLE @gr_arquivo.

      SORT gt_lista_output-lista BY arquivo.

      " Processamento de arquivos não processados
      LOOP AT gt_lista_output-lista INTO gs_arquivo WHERE NOT arquivo IS INITIAL.

        IF NOT gr_arquivo IS INITIAL.
          CHECK NOT gs_arquivo-arquivo IN gr_arquivo.
        ENDIF.


        DATA(lv_len) = strlen( gs_arquivo-arquivo ).

        lv_len = lv_len - 18.

        gv_data_criacao = gs_arquivo-arquivo+lv_len(8).

        "Verifica Filtro do Nome do arquivo
        IF NOT gs_arquivo-arquivo IN s_arqf.
          CONTINUE.
        ENDIF.

        "Verifica se arquivo corresponde a data de seleção
        IF gv_data_criacao IN s_data.

          gt_downarq_input-empresa  = gs_bukrs-low.
          gt_downarq_input-nome     = gs_arquivo-arquivo.

          PERFORM f_download_visa.

          gs_int_log-data = sy-datum.
          gs_int_log-hora = sy-uzeit.
          gs_int_log-interface = 'download_visa'.
          gs_int_log-empresa = gs_bukrs-low.
          gs_int_log-arquivo = gs_arquivo-arquivo.

          IF gv_msg_error IS INITIAL."Grava Log OK ZTRDV001 - Log Interface VISA

            gs_int_log-status = '200'.
            MODIFY ztrdv001 FROM @gs_int_log.

*            Blocos de Processamento
            PERFORM f_quebra_blocos.

*             Bloco de Cadastro de Cartão x Funcionario
            IF gt_bloco_3[] IS NOT INITIAL.

              PERFORM f_process_visa_t3.

            ENDIF.
*           Bloco de Envio de Informações Viceri
            IF gt_bloco_5[] IS NOT INITIAL.

              PERFORM f_process_visa_t5.
            ENDIF.

          ELSE." Grava Log de Erro ZTRDV001 - Log Interface VISA

            gs_int_log-status = '500'.
            gs_int_log-mensagem = gv_msg_error.
            MODIFY ztrdv001 FROM  @gs_int_log .
            APPEND gs_int_log TO gt_ztrdv001  .

          ENDIF.
        ENDIF.
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
  IF gv_msg_error IS NOT INITIAL AND gt_return[] IS INITIAL.

    MESSAGE gv_msg_error TYPE 'S' DISPLAY LIKE 'E'.

  ELSEIF s_bukrs IS INITIAL.

    MESSAGE 'Informe ao menos uma empresa para processamento.' TYPE 'S' DISPLAY LIKE 'E'.

  ELSEIF gt_return IS INITIAL.

    MESSAGE 'Processamento finalizado com sucesso.' TYPE 'S'.

  ELSE.
    WRITE / 'Ocorreram erros durante o procesamento:'.
    WRITE /.
    LOOP AT gt_return INTO gs_return.
      WRITE / gs_return-message.
    ENDLOOP.
  ENDIF.
