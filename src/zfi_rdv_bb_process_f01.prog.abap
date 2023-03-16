*&---------------------------------------------------------------------*
*& Include          ZFI_RDV_BB_PROCESS_F01
*&---------------------------------------------------------------------*

FORM f_process_vip433.
* ============================================================================
*  Processamento de dados arquivo VIP433
* ============================================================================
  TYPES: BEGIN OF linetype,
           sign   TYPE c LENGTH 1,
           option TYPE c LENGTH 2,
           low    TYPE zrdv_seq,
           high   TYPE zrdv_seq,
         END OF linetype.

  DATA: lr_cartao        TYPE RANGE OF sysid,
        lr_200           TYPE RANGE OF zrdv_seq,
        lr_500           TYPE RANGE OF zrdv_seq,
        lr_aux           TYPE RANGE OF zrdv_seq,
        ls_aux           TYPE linetype,
        lt_operation     TYPE TABLE OF zrdv_vip433tipo05oper_type,
        ls_ztrdv002      TYPE ztrdv002,
        lt_ztrdv002      TYPE TABLE OF ztrdv002,
        lt_ztrdv006      TYPE TABLE OF ztrdv006,
        ls_ztrdv006      TYPE ztrdv006,
        ls_vip433_op     TYPE zrdv_vip433tipo05oper_type,
        ls_item          TYPE zrdv_viceri_item_type,
        ls_viceri_return TYPE zrdv_viceri_return_type,
        lv_index         TYPE i,
        lv_index_end     TYPE i.


  SORT gt_vip433_output-tipo05-operation BY nr_transacao.
  READ TABLE gt_vip433_output-tipo05-operation INTO ls_vip433_op INDEX 1.

* Seleciona histórico de transações code 200 - ok
  SELECT 'I' AS sign, 'EQ' AS option, nr_transacao AS low FROM ztrdv002
    WHERE nr_transacao GE @ls_vip433_op-nr_transacao
      AND empresa EQ @gs_bukrs-low
      AND cod_ret EQ '200'
    INTO TABLE @lr_200.

* Elimina transações ja processadas
  IF NOT lr_200 IS INITIAL.
    DELETE gt_vip433_output-tipo05-operation WHERE nr_transacao IN lr_200.
  ENDIF.

  ls_ztrdv002-mandt = sy-mandt.
  ls_ztrdv002-data = sy-datum.
  ls_ztrdv002-hora = sy-uzeit.
  ls_ztrdv002-empresa = gs_bukrs-low.
  ls_ztrdv002-arquivo = gs_arquivo-nome.
  ls_ztrdv002-remessa = gt_vip433_output-tipo05-header-num_remessa.
  ls_ztrdv002-dt_remessa = gt_vip433_output-tipo05-header-data_gera+4(4) && gt_vip433_output-header-data_gera+2(2) && gt_vip433_output-header-data_gera(2).
  ls_ztrdv002-cod_cliente = gt_vip433_output-tipo05-header-cod_cliente.

***********************************************************
* Registro Cartão
***********************************************************

* Seleciona cartões cadastrados
  SELECT 'I' AS sign, 'EQ' AS option, usrid AS low FROM pa0105
    WHERE subty EQ '0011'
      AND usrid <> ''
    INTO TABLE @lr_cartao.

  MOVE-CORRESPONDING gt_vip433_output-tipo05-operation TO lt_operation.
  SORT lt_operation BY cartao.
  DELETE ADJACENT DUPLICATES FROM lt_operation COMPARING cartao.

  LOOP AT lt_operation INTO ls_vip433_op.
    gv_cartao = bandeira && ls_vip433_op-cartao.
    gv_cpf = ls_vip433_op-cpf.

* Registra novo cartão para cpf
    IF NOT gv_cartao IN lr_cartao AND NOT gv_cpf IS INITIAL.
      PERFORM f_registra_cartao.

      IF NOT gs_return-message IS INITIAL.
        " Dados para tabela de logs
        MOVE-CORRESPONDING ls_vip433_op TO ls_ztrdv002.
        ls_ztrdv002-data_efet = ls_vip433_op-data_efet+4(4) && ls_vip433_op-data_efet+2(2) && ls_vip433_op-data_efet(2)."ls_vip433_op-data_efet.
        ls_ztrdv002-data_conf = ls_vip433_op-data_conf+4(4) && ls_vip433_op-data_conf+2(2) && ls_vip433_op-data_conf(2)."ls_vip433_op-data_conf.
        ls_ztrdv002-mensagem = gs_return-message.
        ls_ztrdv002-cod_ret = '500'.
        APPEND ls_ztrdv002 TO lt_ztrdv002.
        " Dados para verificação posterior
        ls_aux-sign = 'I'.
        ls_aux-option = 'EQ'.
        ls_aux-low = ls_vip433_op-nr_transacao.
        APPEND ls_aux TO lr_aux.
      ENDIF.
    ENDIF.
  ENDLOOP.

***********************************************************
* Envio dados Viceri
***********************************************************

* Seleciona histórico de transações code 500 - error
  SELECT 'I' AS sign, 'EQ' AS option, nr_transacao AS low FROM ztrdv002
    WHERE nr_transacao GE @ls_vip433_op-nr_transacao
      AND empresa EQ @gs_bukrs-low
      AND cod_ret EQ '500'
    INTO TABLE @lr_500.

* Seleciona OrganizationUnitId Viceri
  SELECT * FROM ztrdv006
    INTO TABLE lt_ztrdv006.
  SORT lt_ztrdv006 BY centro_custo.

  DELETE gt_vip433_output-tipo05-operation WHERE cod_trans NE '10' AND cod_trans NE '22'.
  lv_index_end = lines( gt_vip433_output-tipo05-operation ).

  LOOP AT gt_vip433_output-tipo05-operation INTO ls_vip433_op.
    lv_index = lv_index + 1.
    lv_index_end = lv_index_end - 1.

* Logs para tabela
    ls_ztrdv002-data = sy-datum.
    ls_ztrdv002-hora = sy-uzeit.
    MOVE-CORRESPONDING ls_vip433_op TO ls_ztrdv002.
    ls_ztrdv002-data_efet = ls_vip433_op-data_efet+4(4) && ls_vip433_op-data_efet+2(2) && ls_vip433_op-data_efet(2)."ls_vip433_op-data_efet.
    ls_ztrdv002-data_conf = ls_vip433_op-data_conf+4(4) && ls_vip433_op-data_conf+2(2) && ls_vip433_op-data_conf(2)."ls_vip433_op-data_conf.

    READ TABLE lt_ztrdv006 INTO ls_ztrdv006 WITH KEY
                                        centro_custo = ls_vip433_op-num_centro_custo
                                        BINARY SEARCH.

* Organization Unit ID não cadastrada
    IF NOT sy-subrc IS INITIAL.
      ls_ztrdv002-mensagem = 'Unid. Organizacional não cadastrada SAP.'.
      ls_ztrdv002-cod_ret = '500'.
      IF ls_vip433_op-nr_transacao NOT IN lr_aux OR lr_aux IS INITIAL.
        APPEND ls_ztrdv002 TO lt_ztrdv002.
      ENDIF.
      CONTINUE.
    ENDIF.

* Organization Unit ID não ativa Viceri
    IF NOT ls_ztrdv006-ativo IS INITIAL.
      ls_ztrdv002-mensagem = 'Unid. Organizacional não ativa Viceri.'.
      ls_ztrdv002-cod_ret = '200'.
      IF ls_vip433_op-nr_transacao NOT IN lr_aux OR lr_aux IS INITIAL.
        APPEND ls_ztrdv002 TO lt_ztrdv002.
      ENDIF.
      CONTINUE.
    ENDIF.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING
        input  = ls_vip433_op-cartao
      IMPORTING
        output = ls_item-nr_cartao.

    CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
      EXPORTING
        input  = ls_vip433_op-cod_ramo_estab
      IMPORTING
        output = ls_item-ramo_atividade.

    " 2 = Saque , 3 = Cartão de Crédito
    IF ls_vip433_op-cod_trans EQ '22'.
      ls_item-id_tipo_transacao = '2'.
      ls_item-debito_credito = 'Saque'.
    ELSE.
      ls_item-id_tipo_transacao = '3'.
      ls_item-debito_credito = 'Cartão de Crédito'.
    ENDIF.

    ls_item-organization_unit_id = ls_ztrdv006-unit_id.
    ls_item-nome_portador = ls_vip433_op-nome_cartao.
    ls_item-cpf = ls_vip433_op-cpf.
    ls_item-cedula_identidade = ''.
    ls_item-nr_transacao = ls_vip433_op-nr_transacao.
    ls_item-data = ls_vip433_op-data_efet+4(4) && ls_vip433_op-data_efet+2(2) && ls_vip433_op-data_efet(2)."ls_vip433_op-data_efet.
    ls_item-valor = ls_vip433_op-valor_real.
    ls_item-moeda_original = ls_vip433_op-cod_moeda_orig.
    ls_item-cidade_transacao = ls_vip433_op-cidade_estab.
    ls_item-uftransacao = ls_vip433_op-uf_estab.
    ls_item-fornecedor = ls_vip433_op-nome_estab.
    ls_item-cnpjfornecedor = ls_vip433_op-cnpj_estab.
    ls_item-tipo_atividade = ls_vip433_op-nome_ramo_estab.
    ls_item-moeda_faturamento = ls_vip433_op-cod_moeda_fat.
    ls_item-data_cotacao = ls_vip433_op-data_conf+4(4) && ls_vip433_op-data_conf+2(2) && ls_vip433_op-data_conf(2)."ls_vip433_op-data_conf.
    ls_item-valor_cotacao = ls_vip433_op-valor_dolar.
    ls_item-valor_convertido = ls_vip433_op-valor_orig.
    ls_item-comentario = ls_vip433_op-descr.
    ls_item-saldo = ls_vip433_op-valor_real.
    ls_item-nm_container = gs_arquivo-nome.

    CONDENSE: ls_item-nome_portador, ls_item-cidade_transacao, ls_item-uftransacao,
    ls_item-fornecedor, ls_item-tipo_atividade, ls_item-comentario.
    APPEND ls_item TO gt_viceri_input-item.

* Elimina logs antigos
    IF ls_vip433_op-nr_transacao IN lr_500 AND NOT lr_500 IS INITIAL.
      DELETE FROM ztrdv002 WHERE nr_transacao = ls_vip433_op-nr_transacao.
    ENDIF.

* Logs para tabela
    IF ls_vip433_op-nr_transacao NOT IN lr_aux OR lr_aux IS INITIAL.
      APPEND ls_ztrdv002 TO lt_ztrdv002.
    ENDIF.

    IF lv_index_end = 0 OR ( lv_index = p_max AND NOT p_max IS INITIAL ).
* Envia dados viceri
      PERFORM f_send_viceri.

* Retorno erro Viceri
      IF gv_msg_error IS INITIAL.
        LOOP AT gt_viceri_input-item INTO ls_item.

          SORT gt_viceri_output-return BY nr_transacao.
          READ TABLE gt_viceri_output-return INTO ls_viceri_return WITH KEY status_code = '500'
                                                                            nr_transacao = ls_item-nr_transacao
                                                                            BINARY SEARCH.
          IF sy-subrc IS INITIAL.
            ls_ztrdv002-mensagem = ls_viceri_return-message.
            ls_ztrdv002-cod_ret = '500'.
            MODIFY lt_ztrdv002 FROM ls_ztrdv002 TRANSPORTING mensagem cod_ret
              WHERE nr_transacao = ls_item-nr_transacao.
          ELSE.
            IF ls_item-nr_transacao NOT IN lr_aux OR lr_aux IS INITIAL.
              ls_ztrdv002-mensagem = 'OK'.
              ls_ztrdv002-cod_ret = '200'.
              MODIFY lt_ztrdv002 FROM ls_ztrdv002 TRANSPORTING mensagem cod_ret
                WHERE nr_transacao = ls_item-nr_transacao.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ELSE.
        " Gravar todas as linha como erro
        LOOP AT gt_viceri_input-item INTO ls_item.
          ls_ztrdv002-mensagem = gv_msg_error.
          ls_ztrdv002-cod_ret = '500'.

          MODIFY lt_ztrdv002 FROM ls_ztrdv002 TRANSPORTING mensagem cod_ret
            WHERE nr_transacao = ls_item-nr_transacao.

        ENDLOOP.
      ENDIF.

      CLEAR: lv_index , gt_viceri_input.

    ENDIF.
  ENDLOOP.

* Grava Logs
  MODIFY ztrdv002 FROM TABLE lt_ztrdv002.
  DELETE lt_ztrdv002 WHERE cod_ret EQ '200'.

  IF NOT lt_ztrdv002 IS INITIAL.

    " Envia email de erro processamento VIP433
    CLEAR: gs_return.

    CALL FUNCTION 'ZFRDV_EMAIL_VIP433'
      IMPORTING
        return = gs_return
      TABLES
        ztrdv  = lt_ztrdv002.

    IF NOT gs_return IS INITIAL.
      APPEND gs_return TO gt_return.
    ENDIF.
  ENDIF.

ENDFORM.

FORM f_process_vip435.
* ============================================================================
*  Processamento de dados arquivo VIP435
* ============================================================================
  DATA: ls_vip435_op  TYPE zrdv_vip435tipo05oper_type,
        lt_zfatin     TYPE TABLE OF zfi_fatin,
        ls_zfatin     TYPE zfi_fatin,
        ls_zfatin_old TYPE zfi_fatin,
        lt_zfatout    TYPE TABLE OF zfi_ret,
        ls_zfatout    TYPE zfi_ret,
        lt_ztrdv003   TYPE TABLE OF ztrdv003,
        ls_ztrdv003   TYPE ztrdv003.

  CLEAR: ls_zfatin, lt_zfatin.

  ls_zfatin-remessa = gt_vip435_output-tipo05-header-num_remessa.
  ls_zfatin-dt_remessa = gt_vip435_output-tipo05-header-data_gera+4(4) && gt_vip435_output-header-data_gera+2(2) && gt_vip435_output-header-data_gera(2).
  ls_zfatin-cod_cliente = gt_vip435_output-tipo05-header-cod_cliente.
  ls_zfatin-valor_tot = gt_vip435_output-tipo05-header-soma_valor / 100.
  GET TIME.

  LOOP AT gt_vip435_output-tipo05-operation INTO ls_vip435_op.
* Sumarização de operações por cc/cpf/cartao/cod.trans/deb.cred.
    ls_zfatin-cpf = ls_vip435_op-cpf.
    ls_zfatin-num_cartao = ls_vip435_op-cartao.
    ls_zfatin-cod_trans = ls_vip435_op-cod_trans_bb.
    ls_zfatin-kostl = ls_vip435_op-num_centro_custo.
    ls_zfatin-shkzg = ls_vip435_op-deb_cred.
    ls_zfatin-valor = ls_vip435_op-valor_real / 100.
    COLLECT ls_zfatin INTO lt_zfatin.

    " Dados para tabela de logs
    ls_ztrdv003-mandt = sy-mandt.
    ls_ztrdv003-data = sy-datum.
    ls_ztrdv003-hora = sy-uzeit.
    ls_ztrdv003-empresa = gs_bukrs-low.
    ls_ztrdv003-arquivo = gs_arquivo-nome.
    MOVE-CORRESPONDING ls_vip435_op TO ls_ztrdv003.
    MOVE-CORRESPONDING ls_zfatin TO ls_ztrdv003.
    ls_ztrdv003-valor_tot = gt_vip435_output-tipo05-trailer-soma_valor.
    APPEND ls_ztrdv003 TO lt_ztrdv003.
  ENDLOOP.

* Processa Fatura
  IF NOT lt_zfatin IS INITIAL.
    CALL FUNCTION 'ZFI_PROCFATURA'
      EXPORTING
        zfatin  = lt_zfatin
      IMPORTING
        zfatout = lt_zfatout.
  ENDIF.

  LOOP AT lt_zfatout INTO ls_zfatout.
    IF ls_zfatout-codretorno = '200' OR ls_zfatout-msg_ret CS 'Fatura já processada'.
      DELETE lt_ztrdv003 WHERE num_centro_custo = ls_zfatout-kostl.
    ELSE.
      LOOP AT lt_ztrdv003 INTO ls_ztrdv003 WHERE cpf = ls_zfatout-cpf
                                             AND remessa = ls_zfatout-remessa.
        ls_ztrdv003-mensagem = ls_zfatout-msg_ret.
        ls_ztrdv003-cod_ret = ls_zfatout-codretorno.
        MODIFY lt_ztrdv003 FROM ls_ztrdv003.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

* Processamento de Logs
  IF NOT lt_ztrdv003 IS INITIAL.

* Verifica tabela de Logs para arquivo
    SELECT COUNT(*) FROM ztrdv003
      WHERE arquivo = gs_arquivo-nome.
    IF sy-subrc IS INITIAL.
      DELETE FROM ztrdv003 WHERE arquivo = gs_arquivo-nome.
    ENDIF.

* Grava Logs
    INSERT ztrdv003 FROM TABLE lt_ztrdv003.

* Envia email de erro processamento VIP435
    CLEAR: gs_return.
    DELETE lt_ztrdv003 WHERE cpf = '' OR mensagem = ''.
    SORT lt_ztrdv003 BY empresa num_centro_custo cpf cartao.
    DELETE ADJACENT DUPLICATES FROM lt_ztrdv003 COMPARING empresa  num_centro_custo cpf cartao.

    CALL FUNCTION 'ZFRDV_EMAIL_VIP435'
      IMPORTING
        return = gs_return
      TABLES
        ztrdv  = lt_ztrdv003.

    IF NOT gs_return IS INITIAL.
      APPEND gs_return TO gt_return.
    ENDIF.
  ENDIF.

ENDFORM.

FORM f_process_vip798.
* ============================================================================
*  Processamento de dados arquivo VIP798
* ============================================================================
  DATA: ls_vip798_op TYPE zrdv_vip798tipo01oper_type,
        lt_zsaqin    TYPE TABLE OF zfi_saqin,
        ls_zsaqin    TYPE zfi_saqin,
        lt_zsaqout   TYPE TABLE OF zfi_ret,
        ls_zsaqout   TYPE zfi_ret,
        lt_ztrdv004  TYPE TABLE OF ztrdv004,
        ls_ztrdv004  TYPE ztrdv004,
        lv_item      TYPE zrdv_item.

  CLEAR: ls_zsaqin, lt_zsaqin, lv_item.

  ls_zsaqin-remessa = gt_vip798_output-header-num_remessa.
  ls_zsaqin-dt_remessa = gt_vip798_output-header-data_proc+4(4) && gt_vip798_output-header-data_proc+2(2) && gt_vip798_output-header-data_proc(2).
  ls_zsaqin-cod_cliente = gt_vip798_output-header-cod_empresa.

  LOOP AT gt_vip798_output-tipo01-operation INTO ls_vip798_op.
    CLEAR: gv_pernr, gv_cpf_nr, gv_cpf, ls_ztrdv004, lt_zsaqin, lt_zsaqout.
    REFRESH: lt_zsaqin, lt_zsaqout.
    GET TIME.
    lv_item = lv_item + 1.
    ls_zsaqin-num_cartao = ls_vip798_op-cartao.
    ls_zsaqin-descricao = ls_vip798_op-descricao.
    ls_zsaqin-valor = ls_vip798_op-valor / 100.
    ls_zsaqin-dt_efetiva = ls_vip798_op-data_contab+4(4) && ls_vip798_op-data_contab+2(2) && ls_vip798_op-data_contab(2).
    gv_cartao = bandeira && ls_zsaqin-num_cartao.

    MOVE-CORRESPONDING ls_zsaqin TO ls_ztrdv004.
    ls_ztrdv004-mandt = sy-mandt.
    ls_ztrdv004-data = sy-datum.
    ls_ztrdv004-hora = sy-uzeit.
    ls_ztrdv004-empresa = gs_bukrs-low.
    ls_ztrdv004-arquivo = gs_arquivo-nome.
    ls_ztrdv004-item = lv_item.
    ls_ztrdv004-nome_cartao = ls_vip798_op-nome_cartao.
    ls_ztrdv004-nome_centro_custo = ls_vip798_op-nome_centro_custo.

* Verifica se existe cadastro do cartao
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
      APPEND ls_zsaqin TO lt_zsaqin.

      " Processa saques
      CALL FUNCTION 'ZFI_PROCSAQUES'
        EXPORTING
          zsaqin  = lt_zsaqin
        IMPORTING
          zsaqout = lt_zsaqout.

* Retorno erro Processa saques
      LOOP AT lt_zsaqout INTO ls_zsaqout WHERE codretorno EQ '500'.
        ls_ztrdv004-centro_custo = ls_zsaqout-kostl.
        ls_ztrdv004-mensagem = ls_zsaqout-msg_ret.
        ls_ztrdv004-cod_ret = ls_zsaqout-codretorno.
        APPEND ls_ztrdv004 TO lt_ztrdv004.
      ENDLOOP.

    ELSE.
      " Erro não existe cadastro cartão
      ls_ztrdv004-cpf = ''.
      ls_ztrdv004-centro_custo = ls_vip798_op-num_centro_custo.
      ls_ztrdv004-mensagem = 'Cartão não cadastrado.'.
      ls_ztrdv004-cod_ret = '500'.
      APPEND ls_ztrdv004 TO lt_ztrdv004.
      INSERT INTO ztrdv004 VALUES ls_ztrdv004.
    ENDIF.
  ENDLOOP.

* Processamento de Logs
  IF NOT lt_ztrdv004 IS INITIAL.

    " Verifica tabela de Logs para arquivo
    SELECT COUNT(*) FROM ztrdv004
      WHERE arquivo = gs_arquivo-nome.
    IF sy-subrc IS INITIAL.
      DELETE FROM ztrdv004 WHERE arquivo = gs_arquivo-nome.
    ENDIF.

* Grava Logs
    INSERT ztrdv004 FROM TABLE lt_ztrdv004.

* Envia email de erro processamento VIP798
    CLEAR: gs_return.
    CALL FUNCTION 'ZFRDV_EMAIL_VIP798'
      IMPORTING
        return = gs_return
      TABLES
        ztrdv  = lt_ztrdv004.

    IF NOT gs_return IS INITIAL.
      APPEND gs_return TO gt_return.
    ENDIF.
  ENDIF.

ENDFORM.

FORM f_lista_downloads.
* ============================================================================
*  Envia dados para API: LISTA DOWNLOADS
* ============================================================================
  CLEAR: gv_msg_error,gv_msg_type.
  CLEAR: gt_lista_output.

  TRY.
      CREATE OBJECT gr_proxy_lista
        EXPORTING
          logical_port_name = 'ZRDV_LISTADOWNLOAD_PORT'.

    CATCH cx_ai_system_fault INTO gs_rif_ex.
      gv_msg_error = gs_rif_ex->get_text( ).
      gv_msg_type = 'I'.
  ENDTRY.

*  generation of the sequence protocol and the sequence
  m_seq_prot ?= gr_proxy_lista->get_protocol( if_wsprotocol=>sequence ).
  m_seq = m_seq_prot->create_persistent_sequence( ).

*  START SEQUENCING AND GET ID
  m_seq->begin( ).
  m_seq_prot->set_client_sequence( m_seq ).
  gv_seq = m_seq->get_id( ).

  TRY.
      CALL METHOD gr_proxy_lista->lista_downloads
        EXPORTING
          input  = gt_lista_input
        IMPORTING
          output = gt_lista_output.

*  end sequencing and commit work
      m_seq->end( ).
      cl_soap_tx_factory=>commit_work( ).

    CATCH cx_ai_system_fault INTO gs_rif_ex.
      gv_msg_error = gs_rif_ex->get_text( ).
      gv_msg_type = 'I'.

  ENDTRY.

ENDFORM.

FORM f_download_vip433.
* ============================================================================
*  Envia dados para API: DOWNLOADVIP433
* ============================================================================
  CLEAR: gv_msg_error,gv_msg_type.
  CLEAR: gt_vip433_output.

  TRY.
      CREATE OBJECT gr_proxy_download
        EXPORTING
          logical_port_name = 'ZRDV_DOWNLOAD_PORT'.

    CATCH cx_ai_system_fault INTO gs_rif_ex.
      gv_msg_error = gs_rif_ex->get_text( ).
      gv_msg_type = 'I'.
  ENDTRY.

*  generation of the sequence protocol and the sequence
  m_seq_prot ?= gr_proxy_download->get_protocol( if_wsprotocol=>sequence ).
  m_seq = m_seq_prot->create_persistent_sequence( ).

*  START SEQUENCING AND GET ID
  m_seq->begin( ).
  m_seq_prot->set_client_sequence( m_seq ).
  gv_seq = m_seq->get_id( ).

  TRY.
      CALL METHOD gr_proxy_download->download_vip433
        EXPORTING
          input  = gt_vip433_input
        IMPORTING
          output = gt_vip433_output.

*  end sequencing and commit work
      m_seq->end( ).
      cl_soap_tx_factory=>commit_work( ).

    CATCH cx_ai_system_fault INTO gs_rif_ex.
      gv_msg_error = gs_rif_ex->get_text( ).
      gv_msg_type = 'I'.

  ENDTRY.

ENDFORM.

FORM f_download_vip435.
* ============================================================================
*  Envia dados para API: DOWNLOADVIP435
* ============================================================================
  CLEAR: gv_msg_error,gv_msg_type.
  CLEAR: gt_vip435_output.

  TRY.
      CREATE OBJECT gr_proxy_download
        EXPORTING
          logical_port_name = 'ZRDV_DOWNLOAD_PORT'.

    CATCH cx_ai_system_fault INTO gs_rif_ex.
      gv_msg_error = gs_rif_ex->get_text( ).
      gv_msg_type = 'I'.
  ENDTRY.

*  generation of the sequence protocol and the sequence
  m_seq_prot ?= gr_proxy_download->get_protocol( if_wsprotocol=>sequence ).
  m_seq = m_seq_prot->create_persistent_sequence( ).

*  START SEQUENCING AND GET ID
  m_seq->begin( ).
  m_seq_prot->set_client_sequence( m_seq ).
  gv_seq = m_seq->get_id( ).

  TRY.
      CALL METHOD gr_proxy_download->download_vip435
        EXPORTING
          input  = gt_vip435_input
        IMPORTING
          output = gt_vip435_output.

*  end sequencing and commit work
      m_seq->end( ).
      cl_soap_tx_factory=>commit_work( ).

    CATCH cx_ai_system_fault INTO gs_rif_ex.
      gv_msg_error = gs_rif_ex->get_text( ).
      gv_msg_type = 'I'.

  ENDTRY.

ENDFORM.

FORM f_download_vip798.
* ============================================================================
*  Envia dados para API: DOWNLOADVIP798
* ============================================================================
  CLEAR: gv_msg_error,gv_msg_type.
  CLEAR: gt_vip798_output.

  TRY.
      CREATE OBJECT gr_proxy_download
        EXPORTING
          logical_port_name = 'ZRDV_DOWNLOAD_PORT'.

    CATCH cx_ai_system_fault INTO gs_rif_ex.
      gv_msg_error = gs_rif_ex->get_text( ).
      gv_msg_type = 'I'.
  ENDTRY.

*  generation of the sequence protocol and the sequence
  m_seq_prot ?= gr_proxy_download->get_protocol( if_wsprotocol=>sequence ).
  m_seq = m_seq_prot->create_persistent_sequence( ).

*  START SEQUENCING AND GET ID
  m_seq->begin( ).
  m_seq_prot->set_client_sequence( m_seq ).
  gv_seq = m_seq->get_id( ).

  TRY.
      CALL METHOD gr_proxy_download->download_vip798
        EXPORTING
          input  = gt_vip798_input
        IMPORTING
          output = gt_vip798_output.

*  end sequencing and commit work
      m_seq->end( ).
      cl_soap_tx_factory=>commit_work( ).

    CATCH cx_ai_system_fault INTO gs_rif_ex.
      gv_msg_error = gs_rif_ex->get_text( ).
      gv_msg_type = 'I'.

  ENDTRY.

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
  CLEAR: gt_viceri_output.

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
