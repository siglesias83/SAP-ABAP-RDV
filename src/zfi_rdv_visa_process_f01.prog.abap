*&---------------------------------------------------------------------*
*& Include          ZFI_RDV_BB_PROCESS_F01
*&---------------------------------------------------------------------*
FORM f_lista_downloads.
* ============================================================================
*  Envia dados para API: LISTA DOWNLOADS
* ============================================================================
  CLEAR: gv_msg_error,gv_msg_type.
  CLEAR: gt_lista_output.

  TRY.
      CREATE OBJECT gr_proxy_lista
        EXPORTING
          logical_port_name = 'ZRDV_LISTADOWNLOAD_VISA_PORT'.

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
      CALL METHOD gr_proxy_lista->lista_downloads_visa
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
FORM f_download_visa.
* ============================================================================
*  Envia dados para API: DOWNLOADVISA
* ============================================================================
  CLEAR: gv_msg_error,gv_msg_type.
  CLEAR: gt_downarq_output.

  TRY.
      CREATE OBJECT gr_proxy_download
        EXPORTING
          logical_port_name = 'ZRDV_DOWNLOAD_VISA_PORT'.

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
      CALL METHOD gr_proxy_download->download_visa
        EXPORTING
          input  = gt_downarq_input
        IMPORTING
          output = gt_downarq_output.

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

  gv_cpf_nr = gv_cpf.

* Busca Cedula de Identidade de RH
  SELECT SINGLE a~pernr
    FROM pa0002 AS a INNER JOIN pa0000 AS b
    ON a~pernr = b~pernr
    AND a~perid EQ @gv_cpf_nr
    AND a~endda GE @sy-datum
    AND a~begda LE @sy-datum
    AND b~stat2 EQ '3'
    AND b~endda GE @sy-datum
    AND b~begda LE @sy-datum
    INTO @gv_pernr.

* Busca PERNR nos dados de fornecedor
  IF sy-subrc NE 0.

    SELECT SINGLE b~pernr
      FROM lfa1 AS a
        INNER JOIN lfb1 AS b
          ON a~lifnr EQ b~lifnr
      WHERE a~stcd1 EQ @gv_cpf_nr AND
            b~bukrs EQ @s_bukrs-low
      INTO @gv_pernr.

  ENDIF.

  IF gv_pernr IS NOT INITIAL.

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
*    gs_return-message = 'Não possivel cadastrar cartão.'.
    gs_return-message = 'Funcionário não localizado, não foi possivel cadastrar cartão.'.
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
*&---------------------------------------------------------------------*
*& Form F_QUEBRA_BLOCOS
*&---------------------------------------------------------------------*
*& Quebra de Blocos do Arquivo
*&---------------------------------------------------------------------*
FORM f_quebra_blocos .

  DATA: lv_tab_field TYPE c VALUE cl_abap_char_utilities=>horizontal_tab,
        lv_append    TYPE char2.

  FREE: gt_bloco_0, gt_bloco_3, gt_bloco_4, gt_bloco_5, gt_bloco_16.
  CLEAR lv_append.

  LOOP AT gt_downarq_output-arquivo
     INTO DATA(ls_arq).

    SPLIT ls_arq-linha AT lv_tab_field
      INTO gs_quebra-campo1
           gs_quebra-campo2
           gs_quebra-campo3
           gs_quebra-campo4
           gs_quebra-campo5
           gs_quebra-campo6
           gs_quebra-campo7
           gs_quebra-campo8
           gs_quebra-campo9
           gs_quebra-campo10
           gs_quebra-campo11
           gs_quebra-campo12
           gs_quebra-campo13
           gs_quebra-campo14
           gs_quebra-campo15
           gs_quebra-campo16
           gs_quebra-campo17
           gs_quebra-campo18
           gs_quebra-campo19
           gs_quebra-campo20
           gs_quebra-campo21
           gs_quebra-campo22
           gs_quebra-campo23
           gs_quebra-campo24
           gs_quebra-campo25
           gs_quebra-campo26
           gs_quebra-campo27
           gs_quebra-campo28
           gs_quebra-campo29
           gs_quebra-campo30
           gs_quebra-campo31
           gs_quebra-campo32
           gs_quebra-campo33
           gs_quebra-campo34
           gs_quebra-campo35
           gs_quebra-campo36
           gs_quebra-campo37
           gs_quebra-campo38
           gs_quebra-campo39
           gs_quebra-campo40
           gs_quebra-campo41
           gs_quebra-campo42
           gs_quebra-campo43
           gs_quebra-campo44
           gs_quebra-campo45
           gs_quebra-campo46
           gs_quebra-campo47
           gs_quebra-campo48
           gs_quebra-campo49
           gs_quebra-campo50.

    CASE lv_append.
      WHEN '0'.
        APPEND gs_quebra TO gt_bloco_0.

      WHEN '3'.
        APPEND gs_quebra TO gt_bloco_3.

      WHEN '4'.
        APPEND gs_quebra TO gt_bloco_4.

      WHEN '5'.
        APPEND gs_quebra TO gt_bloco_5.

      WHEN '16'.
        APPEND gs_quebra TO gt_bloco_16.

    ENDCASE.

    IF gs_quebra-campo1 EQ '9'.

      CLEAR lv_append.
      CONTINUE.

    ELSEIF gs_quebra-campo1 EQ '6' OR gs_quebra-campo1 EQ '8'.

      CASE gs_quebra-campo5.
        WHEN '0'.
          APPEND gs_quebra TO gt_bloco_0.

        WHEN '3'.
          APPEND gs_quebra TO gt_bloco_3.
          lv_append = '3'.

        WHEN '4'.
          APPEND gs_quebra TO gt_bloco_4.
          lv_append = '4'.

        WHEN '5'.
          APPEND gs_quebra TO gt_bloco_5.
          lv_append = '5'.

        WHEN '16'.
          APPEND gs_quebra TO gt_bloco_16.
          lv_append = '16'.

      ENDCASE.

    ENDIF.

  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
FORM f_process_visa_t3.
*&---------------------------------------------------------------------*

* ============================================================================
*  Processamento de dados arquivo T3
* ============================================================================
  TYPES: BEGIN OF linetype,
           sign   TYPE c LENGTH 1,
           option TYPE c LENGTH 2,
           low    TYPE zrdv_seq,
           high   TYPE zrdv_seq,
         END OF linetype.

  DATA: lr_cartao   TYPE RANGE OF sysid,
        ls_ztrdv009 TYPE ztrdv009,
        lt_ztrdv009 TYPE TABLE OF ztrdv009.

* Busca dados do header do Bloco 3 ( sempre inicia com 8 )
  READ TABLE gt_bloco_3 INTO DATA(ls_t3_header) WITH KEY campo1 = '8'.

  ls_ztrdv009-mandt         = sy-mandt.
  ls_ztrdv009-data          = sy-datum.
  ls_ztrdv009-hora          = sy-uzeit.
  ls_ztrdv009-empresa       = gs_bukrs-low.
  ls_ztrdv009-arquivo       = gs_arquivo-arquivo.
  ls_ztrdv009-remessa       = ls_t3_header-campo3.
  ls_ztrdv009-cod_cliente   = ls_t3_header-campo2.

***********************************************************
* Registro Cartão
***********************************************************
  " Seleciona cartões cadastrados
  SELECT 'I' AS sign, 'EQ' AS option, usrid AS low FROM pa0105
    WHERE subty EQ '0011'
      AND usrid IN @r_cc
    INTO TABLE @lr_cartao.

  SORT gt_bloco_3 BY campo3.
  DELETE ADJACENT DUPLICATES FROM gt_bloco_3 COMPARING campo3.

* Valida se cartão já cadastrado
  LOOP AT gt_bloco_3 INTO DATA(ls_t3) WHERE campo1 EQ '4'.


    IF ls_t3-campo2 CS 'CC'.
* Retira CC do campo da Cedula
      REPLACE 'CC' IN ls_t3-campo2 WITH ''.

* Formata campo
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = ls_t3-campo2
        IMPORTING
          output = ls_t3-campo2.

* Formata Campo
      gv_cpf              = ls_t3-campo2.

    ENDIF.

    IF ls_t3-campo2 CS 'CE'.
* Retira CC do campo da Cedula
      REPLACE 'CE' IN ls_t3-campo2 WITH ''.

* Formata campo
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = ls_t3-campo2
        IMPORTING
          output = ls_t3-campo2.

* Formata Campo
      gv_cpf              = ls_t3-campo2.

    ENDIF.

* Formata Campo
    gv_cartao           = bandeira && '000' && ls_t3-campo3.
    ls_ztrdv009-cedula        = gv_cpf   .
    ls_ztrdv009-cartao        = gv_cartao.
    ls_ztrdv009-nome_portador = ls_t3-campo40.


* Numeração Desconhecida
    IF gv_cpf IS INITIAL.

      ls_ztrdv009-mensagem = 'Numeração Desconhecida'.
      ls_ztrdv009-cod_ret = '500'.
      APPEND ls_ztrdv009 TO lt_ztrdv009.
      CONTINUE.

    ENDIF.

    " Registra novo cartão para cpf
    IF NOT gv_cartao IN lr_cartao AND NOT gv_cpf IS INITIAL.

      PERFORM f_registra_cartao.

      " Dados para tabela de logs
      IF NOT gs_return-message IS INITIAL.

        ls_ztrdv009-mensagem = gs_return-message.
        ls_ztrdv009-cod_ret = '500'.
        APPEND ls_ztrdv009 TO lt_ztrdv009.

      ELSE.

        ls_ztrdv009-mensagem = gs_return-message.
        ls_ztrdv009-cod_ret = '200'.
        APPEND ls_ztrdv009 TO lt_ztrdv009.

      ENDIF.

    ENDIF.

  ENDLOOP.

  " Grava Logs
  IF lt_ztrdv009[] IS NOT INITIAL.

    MODIFY ztrdv009 FROM TABLE lt_ztrdv009.
    COMMIT WORK.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form F_PROCESS_VISA_T5
*&---------------------------------------------------------------------*
*& Envio de Informações para Viceri
*&---------------------------------------------------------------------*
FORM f_process_visa_t5 .

* ============================================================================
*  Processamento de dados arquivo T5
* ============================================================================

  TYPES: BEGIN OF linetype,
           sign   TYPE c LENGTH 1,
           option TYPE c LENGTH 2,
           low    TYPE zrdv_seq,
           high   TYPE zrdv_seq,
         END OF linetype.

  DATA: lr_cartao        TYPE RANGE OF sysid,
        lr_200           TYPE RANGE OF zrdv_seq_visa,
        lr_500           TYPE RANGE OF zrdv_seq_visa,
        lr_aux           TYPE RANGE OF zrdv_seq_visa,
        ls_aux           TYPE linetype,
        lt_operation     TYPE TABLE OF zrdv_vip433tipo05oper_type,
        ls_ztrdv007      TYPE ztrdv007,
        lt_ztrdv007      TYPE TABLE OF ztrdv007,
        ls_ztrdv006      TYPE ztrdv006,
        ls_vip433_op     TYPE zrdv_vip433tipo05oper_type,
        ls_item          TYPE zrdv_viceri_item_type,
        ls_viceri_return TYPE zrdv_viceri_return_type,
        lv_index         TYPE i,
        lv_tabix         TYPE sy-tabix,
        lv_index_end     TYPE i,
        lv_sequence(10)  TYPE n,
        lv_perid(40)     TYPE c,
        lv_transacao     TYPE zrdv_seq_visa.


* Busca informações do Header do Bloco
  READ TABLE gt_bloco_5 INTO DATA(ls_t5_header) WITH KEY campo1 = '8'.

* Move Informações para Tabela Interna SAP

  CLEAR ls_ztrdv007.

***********************************************************
* Envio dados Viceri
***********************************************************

  " Seleciona OrganizationUnitId Viceri
  SELECT SINGLE *
  FROM ztrdv006
  INTO ls_ztrdv006
  WHERE empresa     IN s_bukrs
    AND cod_cliente EQ ls_t5_header-campo2.

  " Seleciona cartões cadastrados
  SELECT pernr, usrid FROM pa0105
    WHERE subty EQ '0011'
      AND usrid IN @r_cc
    INTO TABLE @DATA(lt_cartao).

  SORT BY lt_cartao.
  DELETE ADJACENT DUPLICATES FROM lt_cartao.

  " Seleciona dados Funcionarios
  SELECT p1~pernr, p1~sname, p2~perid
    FROM pa0001 AS p1
      INNER JOIN pa0002 AS p2
        ON p1~pernr = p2~pernr
    INTO TABLE @DATA(lt_nome_nif)
    FOR ALL ENTRIES IN @lt_cartao
    WHERE p1~pernr EQ @lt_cartao-pernr.

  SORT BY lt_nome_nif.
  DELETE ADJACENT DUPLICATES FROM lt_nome_nif.

  "Busca todas as operações
  SELECT *
    FROM zfatope
    INTO TABLE @DATA(lt_tp_ope).

  DELETE gt_bloco_5 WHERE campo1 NE '4' AND campo2 IN s_cc.
  lv_index_end = lines( gt_bloco_5 ).


  LOOP AT gt_bloco_5 INTO DATA(ls_t5) WHERE campo2 IN s_cc.

    lv_index_end = lv_index_end - 1.


* Dados de Header
    ls_ztrdv007-mandt       = sy-mandt.
    ls_ztrdv007-data        = sy-datum.
    ls_ztrdv007-hora        = sy-uzeit.
    ls_ztrdv007-empresa     = gs_bukrs-low.
    ls_ztrdv007-ciclo       = ls_t5-campo6.
    ls_ztrdv007-arquivo     = gs_arquivo-arquivo .
    ls_ztrdv007-remessa     = ls_t5_header-campo3.
    ls_ztrdv007-dt_remessa  = gv_data_criacao    .
    ls_ztrdv007-cod_cliente = ls_t5_header-campo2.

*  Monta tabela da leitura do arquivo.
    ls_ztrdv007-tp_operacao = ls_t5-campo18. "TpOperação

* Data Efetiva
    ls_ztrdv007-data_conf   = ls_t5-campo19+4(4) && "Data Efetiva
                              ls_t5-campo19(2) &&
                              ls_t5-campo19+2(2).

*   Formata Campo Valor
    ls_item-valor = ls_t5-campo15.
    DATA(lv_len)  = strlen( ls_item-valor ).

    IF lv_len GT 2.
      DATA(lv_antes_vir) = lv_len - 2.
      ls_ztrdv007-valor_orig = ls_item-valor(lv_antes_vir) && '.' && ls_item-valor+lv_antes_vir(2).
    ELSE.
      ls_ztrdv007-valor_orig = ls_item-valor.
    ENDIF.

* Busca Moeda
    SELECT SINGLE waers
    FROM tcurc
    INTO ls_ztrdv007-cod_moeda_orig
    WHERE altwr EQ ls_t5-campo16.

    IF sy-subrc EQ 0.
      ls_ztrdv007-cod_moeda_fat = ls_ztrdv007-cod_moeda_orig.

    ENDIF.

    ls_ztrdv007-cidade_transacao      = ls_t5-campo10.    "Cidade
    ls_ztrdv007-uftransacao           = ls_t5-campo11.    "Estado
    ls_ztrdv007-fornecedor            = ls_t5-campo9 .    "Fornecedor
    ls_ztrdv007-cartao                = ls_t5-campo2 .    "Numero Cartão
    ls_ztrdv007-tp_operacao           = ls_t5-campo18.    "Tp Operação


* Valida se OrgUnit esta cadastra
    IF NOT ls_ztrdv006-unit_id IS INITIAL.
      ls_ztrdv007-organization_unit_id  = ls_ztrdv006-unit_id.
    ELSE.
      " Logs para tabela
      CONCATENATE : TEXT-M02 ls_ztrdv007-cod_cliente INTO
      ls_ztrdv007-mensagem SEPARATED BY space.
      ls_ztrdv007-cod_ret = '500'.
    ENDIF.

* Valida se operação esta cadastrada
    READ TABLE lt_tp_ope INTO DATA(ls_tp_ope) WITH KEY cod_trans = ls_ztrdv007-tp_operacao.

    IF sy-subrc EQ 0.
      ls_ztrdv007-id_tipo_transacao     = ls_tp_ope-id_tipo_transacao.
      ls_ztrdv007-shkzg                 = ls_tp_ope-shkzg.
    ELSE.
      " Logs para tabela
      CONCATENATE : 'Tp.Operacion' ls_ztrdv007-tp_operacao 'no cadastrada ZFATOPE'
      INTO ls_ztrdv007-mensagem SEPARATED BY space.
      ls_ztrdv007-cod_ret = '500'.
    ENDIF.

* Formata campo CC
    ls_item-nr_cartao             = bandeira && '000' && ls_t5-campo2.

* Busca Funcionario Cartão
    READ TABLE lt_cartao INTO DATA(ls_cartao) WITH KEY usrid = ls_item-nr_cartao.

    IF sy-subrc NE 0 OR ls_cartao-pernr IS INITIAL.

      " Logs para tabela
      ls_ztrdv007-mensagem = TEXT-M01. "'Funcionário/Cartão não encontrado'.
      ls_ztrdv007-cod_ret = '500'.

    ELSE.

* Busca dados do Funcionario
      READ TABLE lt_nome_nif INTO DATA(ls_nome_nif) WITH KEY pernr = ls_cartao-pernr.

      IF sy-subrc EQ 0.

        clear: lv_perid.
        lv_perid = ls_nome_nif-perid.

        CALL FUNCTION 'SF_SPECIALCHAR_DELETE'
          EXPORTING
            with_specialchar    = lv_perid
          IMPORTING
            without_specialchar = lv_perid
          EXCEPTIONS
            result_word_empty   = 1
            OTHERS              = 2.
        IF sy-subrc <> 0.
* Implement suitable error handling here
        ENDIF.

        ls_ztrdv007-nome_portador         = ls_nome_nif-sname.
        ls_ztrdv007-cedula_identidade     = lv_perid.

      ELSE.
        " Logs para tabela
        ls_ztrdv007-mensagem = TEXT-M01. "'Funcionário/Cartão não encontrado'.
        ls_ztrdv007-cod_ret = '500'.
      ENDIF.
    ENDIF.

    CLEAR:lv_sequence.
    lv_sequence = ls_t5-campo5.

* Concatenate para a montagem do numero da transação -
    ls_ztrdv007-nr_transacao  = ls_t5-campo2          && "Numero Cartão
                                ls_ztrdv007-data_conf && "Data Transação
                                ls_t5-campo4          && "Numero da referencia
                                lv_sequence.             "Numero da Sequencia



    IF ls_ztrdv007-cod_ret IS INITIAL
      AND ls_tp_ope-integra_rdv EQ 'S'.

* Monta Tabela Envio RDV
      MOVE-CORRESPONDING ls_ztrdv007 TO ls_item.

      ls_item-debito_credito    = ls_tp_ope-debito_credito  .
      ls_item-data              = ls_ztrdv007-data_conf     .
      ls_item-data_cotacao      = ls_ztrdv007-data_conf     .
      ls_item-valor             = ls_t5-campo15             .
      ls_item-moeda_original    = ls_ztrdv007-cod_moeda_orig.
      ls_item-moeda_faturamento = ls_ztrdv007-cod_moeda_orig.
      ls_item-valor_cotacao     = ls_t5-campo15             .
      ls_item-valor_convertido  = ls_t5-campo15             .
      ls_item-saldo             = ls_t5-campo15             .
      ls_item-cpf               = '00000000000'             .
      ls_item-comentario        = ls_ztrdv007-fornecedor    .
      ls_item-nm_container      = ls_ztrdv007-arquivo       .

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
        EXPORTING
          input  = ls_ztrdv007-cartao
        IMPORTING
          output = ls_item-nr_cartao.


      CONDENSE: ls_item-nome_portador, ls_item-cidade_transacao, ls_item-uftransacao,
                ls_item-fornecedor   , ls_item-tipo_atividade  , ls_item-comentario ,
                ls_item-debito_credito.

      APPEND ls_item TO gt_viceri_input-item.
      lv_index     = lv_index + 1    .

      "Grava Tabela de Log
      APPEND ls_ztrdv007 TO lt_ztrdv007.
      CLEAR  ls_ztrdv007.

      IF lv_index_end = 0 OR ( lv_index = p_max AND NOT p_max IS INITIAL ).

        " Envia dados viceri
        PERFORM f_send_viceri.

        " Retorno erro Viceri
        IF gv_msg_error IS INITIAL.

* Classifica tabela interna
          SORT gt_viceri_output-return BY nr_transacao.

          LOOP AT gt_viceri_input-item INTO ls_item.

            MOVE ls_item-nr_transacao TO lv_transacao.

            READ TABLE gt_viceri_output-return INTO ls_viceri_return WITH KEY status_code = '500'
                                                                              nr_transacao = ls_item-nr_transacao.

            IF sy-subrc IS INITIAL.

              READ TABLE lt_ztrdv007 INTO ls_ztrdv007 WITH KEY nr_transacao = ls_item-nr_transacao.

              IF sy-subrc EQ 0.
                lv_tabix             = sy-tabix.
                ls_ztrdv007-mensagem = ls_viceri_return-message.
                ls_ztrdv007-cod_ret = '500'.
                MODIFY lt_ztrdv007 FROM ls_ztrdv007 INDEX lv_tabix.
                CLEAR: ls_ztrdv007.
              ENDIF.

            ELSE.

              READ TABLE lt_ztrdv007 INTO ls_ztrdv007 WITH KEY nr_transacao = ls_item-nr_transacao.

              IF sy-subrc EQ 0.
                lv_tabix             = sy-tabix.
                ls_ztrdv007-mensagem = 'OK'.
                ls_ztrdv007-cod_ret = '200'.
                MODIFY lt_ztrdv007 FROM ls_ztrdv007 INDEX lv_tabix.
                CLEAR: ls_ztrdv007.
              ENDIF.

            ENDIF.
          ENDLOOP.
        ELSE.
          " Gravar todas as linha como erro
          LOOP AT gt_viceri_input-item INTO ls_item.

            MOVE ls_item-nr_transacao TO lv_transacao.

            READ TABLE lt_ztrdv007 INTO ls_ztrdv007 WITH KEY nr_transacao = ls_item-nr_transacao.

            IF sy-subrc EQ 0.

              lv_tabix             = sy-tabix.
              ls_ztrdv007-mensagem = gv_msg_error.
              ls_ztrdv007-cod_ret  = '500'.

              MODIFY lt_ztrdv007 FROM ls_ztrdv007 INDEX lv_tabix.
              CLEAR  ls_ztrdv007.

            ENDIF.

          ENDLOOP.

        ENDIF.

        CLEAR: lv_index , gt_viceri_input.

      ELSE. "Limpa Dados

        CLEAR: ls_ztrdv007, ls_item,
               ls_tp_ope  , ls_nome_nif.

      ENDIF.


    ELSE.

      "Grava Tabela de Log
      APPEND ls_ztrdv007  TO lt_ztrdv007.
      CLEAR: ls_ztrdv007, ls_item, ls_tp_ope, ls_nome_nif.

    ENDIF.

  ENDLOOP.

  IF lt_ztrdv007[] IS NOT INITIAL.
    MODIFY ztrdv007 FROM TABLE lt_ztrdv007.
    COMMIT WORK AND WAIT.
  ENDIF.

ENDFORM.
