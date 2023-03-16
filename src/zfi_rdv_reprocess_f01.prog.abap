*&---------------------------------------------------------------------*
*& Include          ZFI_RDV_BB_REPROCESS_F01
*&---------------------------------------------------------------------*

FORM f_process_vip433.
* ============================================================================
*  Processamento de dados arquivo VIP433
* ============================================================================
  DATA: lr_cartao        TYPE RANGE OF sysid,
        lr_transacoes    TYPE RANGE OF zrdv_seq,
        lt_operation     TYPE TABLE OF ztrdv002,
        ls_operation     TYPE ztrdv002,
        ls_ztrdv002      TYPE ztrdv002,
        lt_ztrdv002      TYPE TABLE OF ztrdv002,
        lt_ztrdv006      TYPE TABLE OF ztrdv006,
        ls_ztrdv006      TYPE ztrdv006,
        ls_item          TYPE zrdv_viceri_item_type,
        ls_viceri_return TYPE zrdv_viceri_return_type,
        lv_index         TYPE i,
        lv_index_end     TYPE i.

  IF NOT p_200 IS INITIAL AND s_cartao IS INITIAL.
    MESSAGE 'Para reprocessamento mensagens Ok, obrigatório preenchimento de cartão.' TYPE 'S' DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.

  IF p_200 IS INITIAL.

    SELECT * FROM ztrdv002
        WHERE cod_ret = '500'
          AND empresa IN @s_bukrs
          AND dt_remessa IN @s_datar
          AND data_efet IN @s_datae
          AND data_conf IN @s_datac
          AND num_centro_custo IN @s_kostl
          AND cartao IN @s_cartao
        INTO TABLE @lt_ztrdv002.
  ELSE.

    SELECT * FROM ztrdv002
      WHERE empresa IN @s_bukrs
        AND dt_remessa IN @s_datar
        AND data_efet IN @s_datae
        AND data_conf IN @s_datac
        AND num_centro_custo IN @s_kostl
        AND cartao IN @s_cartao
      INTO TABLE @lt_ztrdv002.
  ENDIF.

  IF sy-subrc IS INITIAL.

    SORT lt_ztrdv002 BY nr_transacao.

***********************************************************
* Registro Cartão
***********************************************************

    MOVE-CORRESPONDING lt_ztrdv002 TO lt_operation.
    DELETE lt_operation WHERE mensagem <> 'Não possivel cadastrar cartão.' .

    IF NOT lt_operation IS INITIAL.
      " Seleciona cartões cadastrados
      SELECT 'I' AS sign, 'EQ' AS option, usrid AS low FROM pa0105
        WHERE subty EQ '0011'
          AND usrid <> ''
        INTO TABLE @lr_cartao.

      SORT lt_operation BY cartao.
      DELETE ADJACENT DUPLICATES FROM lt_operation COMPARING cartao.

      LOOP AT lt_operation INTO ls_operation.
        gv_cartao = bandeira && ls_operation-cartao.
        gv_cpf = ls_operation-cpf.

        " Registra novo cartão para cpf
        IF NOT gv_cartao IN lr_cartao AND NOT gv_cpf IS INITIAL.
          PERFORM f_registra_cartao.

          IF gs_return-message IS INITIAL.
            UPDATE ztrdv002 SET data = sy-datum
                                hora  = sy-uzeit
                                mensagem = 'OK'
                                cod_ret = '200'
                                WHERE nr_transacao = ls_operation-nr_transacao.
            DELETE lt_ztrdv002 WHERE nr_transacao = ls_operation-nr_transacao.
          ELSE.
            UPDATE ztrdv002 SET data = sy-datum
                                hora  = sy-uzeit
                                mensagem = gs_return-message
                                WHERE nr_transacao = ls_operation-nr_transacao.
            DELETE lt_ztrdv002 WHERE nr_transacao = ls_operation-nr_transacao.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.

***********************************************************
* Envio dados Viceri
***********************************************************

    " Seleciona OrganizationUnitId Viceri
    SELECT * FROM ztrdv006
      INTO TABLE lt_ztrdv006.
    SORT lt_ztrdv006 BY centro_custo.

    lv_index_end = lines( lt_ztrdv002 ).

    LOOP AT lt_ztrdv002 INTO ls_ztrdv002.
      lv_index = lv_index + 1.
      lv_index_end = lv_index_end - 1.

      READ TABLE lt_ztrdv006 INTO ls_ztrdv006 WITH KEY
                                                centro_custo = ls_ztrdv002-num_centro_custo
                                                BINARY SEARCH.
      " Organization Unit ID não cadastrada
      IF NOT sy-subrc IS INITIAL.
        ls_ztrdv002-data = sy-datum.
        ls_ztrdv002-hora = sy-uzeit.
        ls_ztrdv002-mensagem = 'Unidade Organizacional não cadastrada.'.
        ls_ztrdv002-cod_ret = '500'.

        MODIFY lt_ztrdv002 FROM ls_ztrdv002 TRANSPORTING data hora mensagem cod_ret
              WHERE nr_transacao = ls_ztrdv002-nr_transacao.
        CONTINUE.
      ENDIF.

      " Organization Unit ID não ativa Viceri
      IF NOT ls_ztrdv006-ativo IS INITIAL.
        CONTINUE.
      ENDIF.

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = ls_ztrdv002-cartao
        IMPORTING
          output = ls_item-nr_cartao.

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = ls_ztrdv002-cod_ramo_estab
        IMPORTING
          output = ls_item-ramo_atividade.

      " 2 = Saque , 3 = Cartão de Crédito
      IF ls_ztrdv002-cod_trans EQ '22'.
        ls_item-id_tipo_transacao = '2'.
        ls_item-debito_credito = 'Saque'.
      ELSE.
        ls_item-id_tipo_transacao = '3'.
        ls_item-debito_credito = 'Cartão de Crédito'.
      ENDIF.

      ls_item-organization_unit_id = ls_ztrdv006-unit_id.
      ls_item-nome_portador = ls_ztrdv002-nome_cartao.
      ls_item-cpf = ls_ztrdv002-cpf.
      ls_item-cedula_identidade = ''.
      ls_item-nr_transacao = ls_ztrdv002-nr_transacao.
      ls_item-data = ls_ztrdv002-data_efet.
      ls_item-valor = ls_ztrdv002-valor_real.
      ls_item-moeda_original = ls_ztrdv002-cod_moeda_orig.
      ls_item-cidade_transacao = ls_ztrdv002-cidade_estab.
      ls_item-uftransacao = ls_ztrdv002-uf_estab.
      ls_item-fornecedor = ls_ztrdv002-nome_estab.
      ls_item-cnpjfornecedor = ls_ztrdv002-cnpj_estab.
      ls_item-tipo_atividade = ls_ztrdv002-nome_ramo_estab.
      ls_item-moeda_faturamento = ls_ztrdv002-cod_moeda_fat.
      ls_item-data_cotacao = ls_ztrdv002-data_conf.
      ls_item-valor_cotacao = ls_ztrdv002-valor_dolar.
      ls_item-valor_convertido = ls_ztrdv002-valor_orig.
      ls_item-comentario = ls_ztrdv002-nome_estab.
      ls_item-saldo = ls_ztrdv002-valor_real.
      ls_item-nm_container = ls_ztrdv002-arquivo.

      CONDENSE: ls_item-nome_portador, ls_item-cidade_transacao, ls_item-uftransacao,
      ls_item-fornecedor, ls_item-tipo_atividade, ls_item-comentario.
      APPEND ls_item TO gt_viceri_input-item.

      IF lv_index_end = 0 OR ( lv_index = p_max AND NOT p_max IS INITIAL ).
        " Envia dados viceri
        PERFORM f_send_viceri.

        " Retorno erro Viceri
        IF gv_msg_error IS INITIAL.
          LOOP AT gt_viceri_input-item INTO ls_item.
            ls_ztrdv002-data = sy-datum.
            ls_ztrdv002-hora = sy-uzeit.

            SORT gt_viceri_output-return BY nr_transacao.
            READ TABLE gt_viceri_output-return INTO ls_viceri_return WITH KEY status_code = '500'
                                                                              nr_transacao = ls_item-nr_transacao
                                                                              BINARY SEARCH.
            IF sy-subrc IS INITIAL.
              ls_ztrdv002-mensagem = ls_viceri_return-message.
              ls_ztrdv002-cod_ret = '500'.
            ELSE.
              ls_ztrdv002-mensagem = 'OK'.
              ls_ztrdv002-cod_ret = '200'.
            ENDIF.

            MODIFY lt_ztrdv002 FROM ls_ztrdv002 TRANSPORTING data hora mensagem cod_ret
              WHERE nr_transacao = ls_item-nr_transacao.

          ENDLOOP.
        ELSE.
          LOOP AT gt_viceri_input-item INTO ls_item.
            ls_ztrdv002-data = sy-datum.
            ls_ztrdv002-hora = sy-uzeit.
            ls_ztrdv002-mensagem = gv_msg_error.
            ls_ztrdv002-cod_ret = '500'.

            MODIFY lt_ztrdv002 FROM ls_ztrdv002 TRANSPORTING data hora mensagem cod_ret
               WHERE nr_transacao = ls_item-nr_transacao.

          ENDLOOP.
        ENDIF.

        CLEAR: lv_index , gt_viceri_input.

      ENDIF.
    ENDLOOP.

    " Update tabela de logs
    UPDATE ztrdv002 FROM TABLE lt_ztrdv002.

  ELSE.
    MESSAGE 'Não existem erros para seleção.' TYPE 'I'.
    EXIT.
  ENDIF.

  " Retorno mensagens
  SELECT * FROM ztrdv002
      WHERE cod_ret = '500'
        AND empresa IN @s_bukrs
        AND dt_remessa IN @s_datar
        AND data_efet IN @s_datae
        AND data_conf IN @s_datac
        AND num_centro_custo IN @s_kostl
      INTO TABLE @lt_ztrdv002.
  SORT lt_ztrdv002 BY nr_transacao.

  IF lt_ztrdv002 IS INITIAL.
    MESSAGE 'Processamento finalizado com sucesso.' TYPE 'S'.
  ELSE.
    DELETE lt_ztrdv002 WHERE mensagem = ''.
    SORT lt_ztrdv002 BY empresa num_centro_custo cartao nr_transacao.
    DELETE ADJACENT DUPLICATES FROM lt_ztrdv002 COMPARING empresa  num_centro_custo cpf cartao.
    WRITE / 'Ocorreram erros durante o reprocesamento:'.
    WRITE /.
    LOOP AT lt_ztrdv002 INTO ls_ztrdv002.
      CLEAR: gv_msg_error.
      CONCATENATE ls_ztrdv002-empresa '-' ls_ztrdv002-nome_centro_custo '-'
        ls_ztrdv002-cartao '-' ls_ztrdv002-nome_cartao '-' ls_ztrdv002-nr_transacao
        '-' ls_ztrdv002-mensagem INTO gv_msg_error SEPARATED BY space.
      WRITE / gv_msg_error.
    ENDLOOP.
  ENDIF.

ENDFORM.

FORM f_process_vip435.
* ============================================================================
*  Processamento de dados arquivo VIP435
* ============================================================================
  DATA: lt_zfatin   TYPE TABLE OF zfi_fatin,
        ls_zfatin   TYPE zfi_fatin,
        lt_zfatout  TYPE TABLE OF zfi_ret,
        ls_zfatout  TYPE zfi_ret,
        lt_ztrdv003 TYPE TABLE OF ztrdv003,
        ls_ztrdv003 TYPE ztrdv003.

  SELECT * FROM ztrdv003
    WHERE empresa IN @s_bukrs
        AND dt_remessa IN @s_datar
        AND num_centro_custo IN @s_kostl
        AND cartao IN @s_cartao
    INTO TABLE @lt_ztrdv003.

  IF sy-subrc IS INITIAL.
    LOOP AT lt_ztrdv003 INTO ls_ztrdv003.
      " Sumarização de operações por cc/cpf/cartao/cod.trans/deb.cred.
      MOVE-CORRESPONDING ls_ztrdv003 TO ls_zfatin.
      ls_zfatin-num_cartao = ls_ztrdv003-cartao.
      ls_zfatin-kostl = ls_ztrdv003-num_centro_custo.
      COLLECT ls_zfatin INTO lt_zfatin.
    ENDLOOP.

    " Processa Fatura
    IF NOT lt_zfatin IS INITIAL.
      CALL FUNCTION 'ZFI_PROCFATURA'
        EXPORTING
          zfatin  = lt_zfatin
        IMPORTING
          zfatout = lt_zfatout.

      LOOP AT lt_zfatout INTO ls_zfatout.
        IF ls_zfatout-codretorno = '200' OR ls_zfatout-msg_ret CS 'Fatura já processada'.
          DELETE FROM ztrdv003 WHERE num_centro_custo = ls_zfatout-kostl.
          DELETE lt_ztrdv003 WHERE num_centro_custo = ls_zfatout-kostl.
        ELSEIF ls_zfatout-codretorno = '500'.
          LOOP AT lt_ztrdv003 INTO ls_ztrdv003 WHERE cpf = ls_zfatout-cpf.
            ls_ztrdv003-data = sy-datum.
            ls_ztrdv003-hora = sy-uzeit.
            ls_ztrdv003-mensagem = ls_zfatout-msg_ret.
            UPDATE ztrdv003 FROM ls_ztrdv003.
            MODIFY lt_ztrdv003 FROM ls_ztrdv003.
          ENDLOOP.
        ENDIF.
      ENDLOOP.
    ENDIF.

  ELSE.
    MESSAGE 'Não existem erros para seleção.' TYPE 'I'.
    EXIT.
  ENDIF.

  " Retorno mensagens
  IF lt_ztrdv003 IS INITIAL.
    MESSAGE 'Processamento finalizado com sucesso.' TYPE 'S'.
  ELSE.
    DELETE lt_ztrdv003 WHERE mensagem = ''.
    SORT lt_ztrdv003 BY empresa num_centro_custo cartao.
    DELETE ADJACENT DUPLICATES FROM lt_ztrdv003 COMPARING empresa  num_centro_custo cpf cartao.
    WRITE / 'Ocorreram erros durante o reprocesamento:'.
    WRITE /.
    LOOP AT lt_ztrdv003 INTO ls_ztrdv003.
      CLEAR: gv_msg_error.
      CONCATENATE ls_ztrdv003-empresa '-' ls_ztrdv003-nome_centro_custo '-'
        ls_ztrdv003-cartao '-' ls_ztrdv003-nome_cartao '-' ls_ztrdv003-nr_transacao
        '-' ls_ztrdv003-mensagem INTO gv_msg_error SEPARATED BY space.
      WRITE / gv_msg_error.
    ENDLOOP.
  ENDIF.

ENDFORM.

FORM f_process_vip798.
* ============================================================================
*  Processamento de dados arquivo VIP798
* ============================================================================
  DATA: lt_zsaqin   TYPE TABLE OF zfi_saqin,
        ls_zsaqin   TYPE zfi_saqin,
        lt_zsaqout  TYPE TABLE OF zfi_ret,
        ls_zsaqout  TYPE zfi_ret,
        lt_ztrdv004 TYPE TABLE OF ztrdv004,
        ls_ztrdv004 TYPE ztrdv004,
        lv_tabix    TYPE sy-tabix.

  SELECT * FROM ztrdv004
    WHERE empresa IN @s_bukrs
        AND dt_remessa IN @s_datar
        AND dt_efetiva IN @s_datae
        AND centro_custo IN @s_kostl
        AND num_cartao IN @s_cartao
    INTO TABLE @lt_ztrdv004.

  IF sy-subrc IS INITIAL.
    LOOP AT lt_ztrdv004 INTO ls_ztrdv004.
      CLEAR: ls_zsaqin, lt_zsaqin, ls_zsaqout, lt_zsaqout.
      REFRESH: lt_zsaqin, lt_zsaqout.
      lv_tabix = sy-tabix.

      MOVE-CORRESPONDING ls_ztrdv004 TO ls_zsaqin.

      " Busca CPF para cartão
      IF ls_zsaqin-cpf IS INITIAL.
        gv_cartao = bandeira && ls_ztrdv004-num_cartao.
        SELECT SINGLE a~pernr , a~cpf_nr
          FROM pa0465 AS a INNER JOIN pa0105 AS b
          ON a~pernr = b~pernr
          AND a~subty = '0001'
          AND b~subty = '0011'
          AND b~usrid = @gv_cartao
          INTO ( @gv_pernr , @gv_cpf_nr ).

        IF sy-subrc IS INITIAL.
          REPLACE ALL OCCURRENCES OF REGEX '[.-]' IN gv_cpf_nr WITH ''.
          gv_cpf = gv_cpf_nr.
          ls_zsaqin-cpf = gv_cpf.
          ls_ztrdv004-cpf = gv_cpf.
          MODIFY lt_ztrdv004 FROM ls_ztrdv004.
        ENDIF.
      ENDIF.

      APPEND ls_zsaqin TO lt_zsaqin.

      " Processa saques
      CALL FUNCTION 'ZFI_PROCSAQUES'
        EXPORTING
          zsaqin  = lt_zsaqin
        IMPORTING
          zsaqout = lt_zsaqout.

      " Retorno sucesso Processa saques
      LOOP AT lt_zsaqout INTO ls_zsaqout.
        IF ls_zsaqout-codretorno EQ '200'.
          DELETE FROM ztrdv004 WHERE arquivo = ls_ztrdv004-arquivo AND item = ls_ztrdv004-item.
          DELETE lt_ztrdv004 INDEX lv_tabix.
        ELSEIF ls_zsaqout-codretorno EQ '500'.
          ls_ztrdv004-data = sy-datum.
          ls_ztrdv004-hora = sy-uzeit.
          ls_ztrdv004-mensagem = ls_zsaqout-msg_ret.
          UPDATE ztrdv004 FROM ls_ztrdv004.
          MODIFY lt_ztrdv004 FROM ls_ztrdv004.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ELSE.
    MESSAGE 'Não existem erros para seleção.' TYPE 'I'.
    EXIT.
  ENDIF.

  " Retorno mensagens
  IF lt_ztrdv004 IS INITIAL.
    MESSAGE 'Processamento finalizado com sucesso.' TYPE 'S'.
  ELSE.
    WRITE / 'Ocorreram erros durante o reprocesamento:'.
    WRITE /.
    SORT lt_ztrdv004 BY empresa centro_custo num_cartao.
    LOOP AT lt_ztrdv004 INTO ls_ztrdv004.
      CLEAR: gv_msg_error.
      CONCATENATE ls_ztrdv004-empresa '-' ls_ztrdv004-nome_centro_custo '-'
        ls_ztrdv004-num_cartao '-' ls_ztrdv004-nome_cartao '-' ls_ztrdv004-mensagem
        INTO gv_msg_error SEPARATED BY space.
      WRITE / gv_msg_error.
    ENDLOOP.
  ENDIF.

ENDFORM.

FORM f_registra_cartao.
* ============================================================================
*  Cria cartão crédito dados RH
*  Infotipo 0105 - Comunicação
*  Tipo 0011 - Número(s) cartão de crédito
* ============================================================================
  CLEAR: gs_return, gv_pernr, gv_cpf_nr.

  gv_cpf_nr = gv_cpf(3) && '.' && gv_cpf+3(3) && '.' && gv_cpf+6(3) && '-' && gv_cpf+9(2).

  SELECT SINGLE a~pernr
    FROM pa0465 AS a INNER JOIN pa0000 AS b
    ON a~pernr = b~pernr
    AND a~cpf_nr EQ @gv_cpf_nr
    AND a~endda GE @sy-datum
    AND a~begda LE @sy-datum
    AND b~stat2 EQ '3'
    AND b~endda GE @sy-datum
    AND b~begda LE @sy-datum
    INTO @gv_pernr.

  IF sy-subrc IS INITIAL.
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
          validitybegin   = sy-datum
          validityend     = '99991231'
          communicationid = gv_cartao
        IMPORTING
          return          = gs_return.
    ENDIF.
  ELSE.
    gs_return-message = 'Não possivel cadastrar cartão.'.
  ENDIF.
ENDFORM.

FORM f_send_viceri.
* ============================================================================
*  Envia dados para API: VICERI
* ============================================================================
  CLEAR: gv_msg_error,gv_msg_type.

  TRY.
      CREATE OBJECT gr_proxy_viceri
        EXPORTING
          logical_port_name = 'ZRDV_VICERI_PORT'.

    CATCH cx_ai_system_fault INTO gs_rif_ex.
      gv_msg_error = gs_rif_ex->get_text( ).
      gv_msg_type = 'I'.
  ENDTRY.

*  generation of the sequence protocol and the sequence
  m_seq_prot ?= gr_proxy_viceri->get_protocol( if_wsprotocol=>sequence ).
  m_seq = m_seq_prot->create_persistent_sequence( ).

*  START SEQUENCING AND GET ID
  m_seq->begin( ).
  m_seq_prot->set_client_sequence( m_seq ).
  gv_seq = m_seq->get_id( ).

  TRY.
      CALL METHOD gr_proxy_viceri->send_viceri
        EXPORTING
          input  = gt_viceri_input
        IMPORTING
          output = gt_viceri_output.

*  end sequencing and commit work
      m_seq->end( ).
      cl_soap_tx_factory=>commit_work( ).

    CATCH cx_ai_system_fault INTO gs_rif_ex.
      gv_msg_error = gs_rif_ex->get_text( ).
      SHIFT gv_msg_error BY 47 PLACES.
      gv_msg_type = 'I'.

  ENDTRY.
ENDFORM.
