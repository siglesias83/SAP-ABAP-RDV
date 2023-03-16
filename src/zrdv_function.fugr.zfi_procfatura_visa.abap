FUNCTION zfi_procfatura_visa.
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     VALUE(ZFATIN_VISA) TYPE  ZFATIN_VISA
*"  EXPORTING
*"     VALUE(ZFATOUT) TYPE  ZFATOUT
*"----------------------------------------------------------------------

  TYPES: BEGIN OF y_lfa1       ,
           lifnr TYPE lfa1-lifnr,
           stcd1 TYPE lfa1-stcd1,
         END OF y_lfa1         .

  TYPES: BEGIN OF y_lfb1        ,
           bukrs TYPE lfb1-bukrs,
           lifnr TYPE lfa1-lifnr,
         END OF y_lfb1          .

  TYPES: BEGIN OF y_but000            ,
           partner TYPE but000-partner,
         END OF y_but000         .

  TYPES: BEGIN OF y_fatin_aux                     ,
           cod_cliente TYPE zfi_fatin-cod_cliente,
           remessa     TYPE zfi_fatin-remessa,
           dt_remessa  TYPE zfi_fatin-dt_remessa,
           cedula      TYPE zfi_fatin_visa-cedula,
           num_cartao  TYPE zfi_fatin-num_cartao,
           valor       TYPE zfi_fatin-valor,
           kostl       TYPE zfi_fatin-kostl,
         END OF y_fatin_aux.

** TABELAS INTERNAS
  DATA: gt_tabin           TYPE TABLE OF zfi_fatin_visa,
        gt_tabin_aux       TYPE TABLE OF y_fatin_aux,
        gt_tabout          TYPE TABLE OF zfi_ret,
        gt_ztparam         TYPE TABLE OF ztparam,
        gt_oper            TYPE TABLE OF zfatope,
        gt_lfa1            TYPE TABLE OF y_lfa1,
        gt_lfb1            TYPE TABLE OF y_lfb1,
        gt_but000          TYPE TABLE OF y_but000,
        gt_accountgl       TYPE STANDARD TABLE OF bapiacgl09,
        gt_accountpayable  TYPE STANDARD TABLE OF bapiacap09,
        gt_currency_amount TYPE STANDARD TABLE OF bapiaccr09,
        gt_return          TYPE STANDARD TABLE OF bapiret2 WITH HEADER LINE.

** WORK-AREA
  DATA: wa_tabin           TYPE zfi_fatin_visa,
        wa_t001            TYPE t001,
        wa_ztrdv006        TYPE ztrdv006,
        wa_tabin_aux       TYPE y_fatin_aux,
        wa_oper            TYPE zfatope,
        wa_lfa1            TYPE y_lfa1,
        wa_lfb1            TYPE y_lfb1,
        wa_tabout          TYPE zfi_ret,
        wa_ztparam         TYPE ztparam,
        wa_bkpf            TYPE bkpf,
        wa_but000          TYPE y_but000,
        wa_header          TYPE bapiache09,
        wa_accountpayable  TYPE bapiacap09,
        wa_accountgl       TYPE bapiacgl09,
        wa_currency_amount TYPE bapiaccr09.

** VARIAVEIS E CONSTANTS
  CONSTANTS: c_500(3) TYPE c VALUE '500',
             c_200(3) TYPE c VALUE '200'.

  DATA: vg_buzei(10) TYPE n,
        vg_dtven     TYPE bseg-zfbdt,
        vg_tabix     TYPE sy-tabix,
        vg_bktxt     TYPE bkpf-bktxt,
        vg_belnr     TYPE bkpf-belnr,
        vg_vltot     TYPE bseg-wrbtr,
        vg_tarif     TYPE bseg-wrbtr,
        vg_impos     TYPE bseg-wrbtr,
        vg_anuid     TYPE bseg-wrbtr,
        vg_anuid_est TYPE bseg-wrbtr.

********************************
** Move Tabela Interna
********************************

  gt_tabin = zfatin_visa.


* Busca Conta Contabil Banco x Empresa para processamento
  SELECT *
  INTO TABLE gt_ztparam
  FROM ztparam
  WHERE sistema  = 'FIPAR'
    AND tipopar  = 'CC_FATURA'.

  IF NOT gt_tabin[] IS INITIAL.

* Busca Código Empresa
    READ TABLE gt_tabin INTO wa_tabin INDEX 1.

    READ TABLE gt_ztparam INTO wa_ztparam WITH KEY sistema  = 'FIPAR'
                                                   tipopar  = 'CC_FATURA'
                                                   valorpar = wa_tabin-cod_cliente.

* Seleciona dados da empresa
    SELECT SINGLE *
    FROM t001
    INTO wa_t001
    WHERE bukrs EQ wa_ztparam-valorpar2.


* Busca Operações Cadastradas para parceiro bancario
    SELECT *
    FROM zfatope
    INTO TABLE gt_oper
    WHERE cod_cliente EQ '0000000000'.

    IF sy-subrc NE 0.

      MOVE-CORRESPONDING wa_tabin TO  wa_tabout. " SIGLESIAS 13.06.2022
      wa_tabout-msg_ret    = TEXT-e02.
      wa_tabout-codretorno = c_500.
      APPEND wa_tabout TO gt_tabout.
      CLEAR  wa_tabout.

    ELSE.

* Busca Informações Fornecedor para Processamento Brasil
      SELECT lifnr stcd1
      INTO TABLE gt_lfa1
      FROM lfa1
      FOR ALL ENTRIES IN gt_tabin
      WHERE stcd1 EQ gt_tabin-cedula.

      IF sy-subrc EQ 0.

        SORT   gt_lfa1 BY stcd1.
        DELETE gt_lfa1 WHERE stcd1 EQ space.

        IF NOT gt_lfa1[] IS INITIAL.

* Valida se Fornecedor não esta bloqueado
          SELECT partner
          FROM but000
          INTO TABLE gt_but000
          FOR ALL ENTRIES IN gt_lfa1
          WHERE partner EQ gt_lfa1-lifnr
            AND xdele   EQ space
            AND xblck   EQ space
            AND not_released EQ space.

          IF sy-subrc EQ 0.

            LOOP AT gt_lfa1 INTO wa_lfa1.

              vg_tabix = sy-tabix.

              READ TABLE gt_but000 INTO wa_but000 WITH KEY partner = wa_lfa1-lifnr.

              IF sy-subrc NE 0.

                DELETE gt_lfa1 INDEX vg_tabix.

              ENDIF.

            ENDLOOP.
          ENDIF.

* Valida Fornecedor Empresa
          SELECT bukrs lifnr
          INTO TABLE gt_lfb1
          FROM lfb1
          FOR ALL ENTRIES IN gt_lfa1
          WHERE bukrs EQ wa_ztparam-valorpar2
            AND lifnr EQ gt_lfa1-lifnr.

        ENDIF.

      ENDIF.
******************************
******* Monta Valores totais de Cada Fatura
******************************
      CLEAR: vg_tabix.
      SORT   gt_tabin BY kostl cedula cod_trans.
      SORT   gt_oper  BY cod_trans.

      LOOP AT gt_tabin INTO wa_tabin.


*****************************************
* Valida se lançamento já foi realizado
*****************************************
        CLEAR      : vg_bktxt.
        CONCATENATE: wa_tabin-remessa '-' wa_tabin-kostl INTO vg_bktxt.

        SELECT SINGLE belnr
        INTO vg_belnr
        FROM bkpf
        WHERE bukrs EQ wa_ztparam-valorpar2
          AND bktxt EQ vg_bktxt
          AND stblg EQ space.

        IF sy-subrc NE 0.

******************************
** Caso seja Troca de Centro de custo - Gera Lançamento
******************************
          IF NOT wa_tabin_aux-kostl IS INITIAL
            AND wa_tabin_aux-kostl NE wa_tabin-kostl.


            CLEAR: vg_buzei          , wa_header         ,
                   wa_accountpayable , wa_tabout         ,
                   gt_accountpayable , gt_accountgl      ,
                   gt_currency_amount, gt_return         .

            LOOP AT gt_tabin_aux INTO wa_tabin_aux.

              vg_tabix = sy-tabix.

              READ TABLE gt_ztparam INTO wa_ztparam WITH KEY sistema  = 'FIPAR'
                                                             tipopar  = 'CC_FATURA'
                                                             valorpar = wa_tabin_aux-cod_cliente.

              IF sy-subrc EQ 0.

                READ TABLE gt_lfa1 INTO wa_lfa1 WITH KEY stcd1 = wa_tabin_aux-cedula.

                IF sy-subrc EQ 0.

                  READ TABLE gt_lfb1 INTO wa_lfb1 WITH KEY lifnr = wa_lfa1-lifnr
                                                           bukrs = wa_ztparam-valorpar2.

                  IF sy-subrc EQ 0.

* Debito
                    vg_buzei = vg_buzei + 1.
                    wa_accountpayable-itemno_acc = vg_buzei.
                    wa_accountpayable-vendor_no  = wa_lfb1-lifnr.
                    wa_accountpayable-item_text  = TEXT-m09.
                    wa_accountpayable-alloc_nmbr = wa_tabin_aux-num_cartao.
                    wa_accountpayable-sp_gl_ind  = 'C'.
                    APPEND wa_accountpayable TO gt_accountpayable.
                    CLEAR  wa_accountpayable.

                    wa_currency_amount-itemno_acc = vg_buzei.
                    wa_currency_amount-currency   = wa_t001-waers. "TEXT-p05.
                    wa_currency_amount-amt_doccur = wa_tabin_aux-valor .
                    APPEND wa_currency_amount TO gt_currency_amount.
                    CLEAR  wa_currency_amount.


                  ELSE. "Fornecedor Empresa

                    MOVE-CORRESPONDING wa_tabin_aux TO  wa_tabout.
                    wa_tabout-msg_ret    = TEXT-m06.
                    wa_tabout-codretorno = c_500.
                    APPEND wa_tabout TO gt_tabout.
                    CLEAR  wa_tabout.


                  ENDIF.


                ELSE. "Fornecedor

                  MOVE-CORRESPONDING wa_tabin_aux TO  wa_tabout.
                  wa_tabout-msg_ret    = TEXT-m05.
                  wa_tabout-codretorno = c_500.
                  APPEND wa_tabout TO gt_tabout.
                  CLEAR  wa_tabout.

                ENDIF.

              ELSE. "Conta

                MOVE-CORRESPONDING wa_tabin_aux TO  wa_tabout.
                wa_tabout-msg_ret    = TEXT-m04.
                wa_tabout-codretorno = c_500.
                APPEND wa_tabout TO gt_tabout.
                CLEAR  wa_tabout.

              ENDIF.

            ENDLOOP.

****************************
* MONTA HEADER GERAÇÃO DO DOCUMENTO
****************************
            wa_header-username    = sy-uname.
            wa_header-comp_code   = wa_ztparam-valorpar2.
            wa_header-doc_date    = wa_tabin_aux-dt_remessa.
            wa_header-pstng_date  = wa_tabin_aux-dt_remessa.
            wa_header-ref_doc_no  = TEXT-t01.
            wa_header-doc_type    = wa_ztparam-valorpar3.

            CONCATENATE: wa_tabin_aux-remessa '-' wa_tabin_aux-kostl INTO wa_header-header_txt .

* Monta Dt. vencimento
            CONCATENATE: wa_tabin_aux-dt_remessa+0(6) wa_ztparam-valorpar4
                         INTO vg_dtven.

* Numero Fornecedor Banco
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
              EXPORTING
                input  = wa_ztparam-valorpar1
              IMPORTING
                output = wa_accountpayable-vendor_no.

            vg_buzei = vg_buzei + 1.
            wa_accountpayable-itemno_acc = vg_buzei.
            wa_accountpayable-item_text  = TEXT-m09      .
            wa_accountpayable-bline_date = vg_dtven      .
            wa_accountpayable-pmnttrms   = TEXT-c01      .
            APPEND wa_accountpayable TO gt_accountpayable.
            CLEAR  wa_accountpayable.

            wa_currency_amount-itemno_acc = vg_buzei.
            wa_currency_amount-currency   = wa_t001-waers. "TEXT-p05.
            wa_currency_amount-amt_doccur = vg_vltot * -1.
            APPEND wa_currency_amount TO gt_currency_amount.
            CLEAR  wa_currency_amount.


******Tarifa*************
            IF NOT vg_tarif IS INITIAL.

              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                EXPORTING
                  input  = wa_ztparam-valorpar5
                IMPORTING
                  output = wa_accountgl-gl_account.

              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                EXPORTING
                  input  = wa_ztparam-valorpar6
                IMPORTING
                  output = wa_accountgl-costcenter.

              vg_buzei = vg_buzei + 1.
              wa_accountgl-itemno_acc = vg_buzei.
              wa_accountgl-item_text  = TEXT-m11.
              APPEND wa_accountgl TO gt_accountgl.
              CLEAR wa_accountgl.

              wa_currency_amount-itemno_acc = vg_buzei.
              wa_currency_amount-currency   = wa_t001-waers. "TEXT-p05.
              wa_currency_amount-amt_doccur = vg_tarif .
              APPEND wa_currency_amount TO gt_currency_amount.
              CLEAR  wa_currency_amount.

            ENDIF.

******Imposto*************
            IF NOT vg_impos IS INITIAL.

              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                EXPORTING
                  input  = wa_ztparam-valorpar7
                IMPORTING
                  output = wa_accountgl-gl_account.

              CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
                EXPORTING
                  input  = wa_ztparam-valorpar6
                IMPORTING
                  output = wa_accountgl-costcenter.

              vg_buzei = vg_buzei + 1.
              wa_accountgl-itemno_acc = vg_buzei.
              wa_accountgl-item_text  = TEXT-m11.
              APPEND wa_accountgl TO gt_accountgl.
              CLEAR wa_accountgl.

              wa_currency_amount-itemno_acc = vg_buzei.
              wa_currency_amount-currency   = wa_t001-waers. "TEXT-p05.
              wa_currency_amount-amt_doccur = vg_impos .
              APPEND wa_currency_amount TO gt_currency_amount.
              CLEAR  wa_currency_amount.

            ENDIF.

            CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
              EXPORTING
                documentheader = wa_header
              TABLES
                accountgl      = gt_accountgl
                accountpayable = gt_accountpayable
                currencyamount = gt_currency_amount
                return         = gt_return.

            READ TABLE gt_return INDEX 1.

            IF gt_return-type EQ 'S'.

              CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' " DESTINATION 'QA1CLNT500'
                EXPORTING
                  wait   = 'X'
                IMPORTING
                  return = gt_return.

              READ TABLE gt_return INDEX 1.

              "MOVE-CORRESPONDING wa_tabin_aux TO  wa_tabout. " wa_tabin -> wa_tabin_aux SIGLESIAS 13.06.2022
              wa_tabout-kostl = wa_tabin_aux-kostl. " SIGLESIAS 20.06.2022
              wa_tabout-codretorno = c_200.
              wa_tabout-idsap      = gt_return-message_v2.
              APPEND wa_tabout TO gt_tabout.
              CLEAR  wa_tabout.

            ELSE.

              READ TABLE gt_return INDEX 2.

              "MOVE-CORRESPONDING wa_tabin_aux TO  wa_tabout. " SIGLESIAS 13.06.2022
              wa_tabout-kostl = wa_tabin_aux-kostl. " SIGLESIAS 20.06.2022
              wa_tabout-msg_ret    = gt_return-message.
              wa_tabout-codretorno = c_500.
              APPEND wa_tabout TO gt_tabout.
              CLEAR  wa_tabout.

            ENDIF.

****************************
* LIMPA WORK-AREA E ATUALIZA COM NOVO REGISTRO
****************************
            CLEAR: wa_tabin_aux, gt_tabin_aux[],
                   vg_vltot    , vg_tarif      .

            READ TABLE gt_oper INTO wa_oper WITH KEY cod_trans = wa_tabin-cod_trans.

            IF sy-subrc EQ 0.

              IF wa_tabin-shkzg EQ 'C'.
                wa_tabin-valor = wa_tabin-valor * -1.
              ENDIF.


              CASE wa_oper-indicador.

                WHEN '1'. "Despesa
                  vg_vltot = vg_vltot + wa_tabin-valor.
                  vg_tarif = vg_tarif + wa_tabin-valor.


                WHEN '2'. "Cartão
                  vg_vltot = vg_vltot + wa_tabin-valor.

                  MOVE-CORRESPONDING wa_tabin TO   wa_tabin_aux.
                  COLLECT wa_tabin_aux        INTO gt_tabin_aux.


                WHEN '4'. "Imposto
                  vg_vltot = vg_vltot + wa_tabin-valor.
                  vg_impos = vg_impos + wa_tabin-valor.


                WHEN OTHERS.

              ENDCASE.
            ENDIF.

          ELSE.

            READ TABLE gt_oper INTO wa_oper WITH KEY cod_trans = wa_tabin-cod_trans.

            IF sy-subrc EQ 0.

              IF wa_tabin-shkzg EQ 'C'.
                wa_tabin-valor = wa_tabin-valor * -1.
              ENDIF.

              CASE wa_oper-indicador.

                WHEN '1'. "Despesa
                  vg_vltot = vg_vltot + wa_tabin-valor.
                  vg_tarif = vg_tarif + wa_tabin-valor.

                WHEN '2'. "Cartão
                  vg_vltot = vg_vltot + wa_tabin-valor.

                  MOVE-CORRESPONDING wa_tabin TO   wa_tabin_aux.
                  COLLECT wa_tabin_aux        INTO gt_tabin_aux.

                WHEN '4'. "Imposto
                  vg_vltot = vg_vltot + wa_tabin-valor.
                  vg_impos = vg_impos + wa_tabin-valor.


                WHEN OTHERS.

              ENDCASE.

            ENDIF.

          ENDIF.

**** Caso já exista o Lançamento
        ELSE.
**** Caso já exista o lançamento

          "MOVE-CORRESPONDING wa_tabin TO wa_tabout. " SIGLESIAS 09.06.2022
          wa_tabout-kostl = wa_tabin-kostl. " SIGLESIAS 20.06.2022
          CONCATENATE : TEXT-e01 '-' vg_belnr INTO wa_tabout-msg_ret SEPARATED BY space.
          wa_tabout-codretorno = c_500.
          APPEND wa_tabout TO gt_tabout.
          CLEAR  wa_tabout.

          DELETE gt_tabin WHERE kostl EQ wa_tabin-kostl.

        ENDIF.

      ENDLOOP.

*****************************************
* Ultimo registro
*****************************************
      CLEAR: vg_buzei          , wa_header         ,
             wa_accountpayable , wa_tabout         ,
             gt_accountpayable , gt_accountgl      ,
             gt_currency_amount, gt_return         .

      IF NOT gt_tabin_aux[] IS INITIAL.

        LOOP AT gt_tabin_aux INTO wa_tabin_aux.

          vg_tabix = sy-tabix.

          READ TABLE gt_ztparam INTO wa_ztparam WITH KEY sistema  = 'FIPAR'
                                                         tipopar  = 'CC_FATURA'
                                                         valorpar = wa_tabin_aux-cod_cliente.

          IF sy-subrc EQ 0.

            READ TABLE gt_lfa1 INTO wa_lfa1 WITH KEY stcd1 = wa_tabin_aux-cedula.

            IF sy-subrc EQ 0.

              READ TABLE gt_lfb1 INTO wa_lfb1 WITH KEY lifnr = wa_lfa1-lifnr
                                                       bukrs = wa_ztparam-valorpar2.

              IF sy-subrc EQ 0.

* Debito
                vg_buzei = vg_buzei + 1.
                wa_accountpayable-itemno_acc = vg_buzei.
                wa_accountpayable-vendor_no  = wa_lfb1-lifnr.
                wa_accountpayable-item_text  = TEXT-m09.
                wa_accountpayable-alloc_nmbr = wa_tabin_aux-num_cartao.
                wa_accountpayable-sp_gl_ind  = 'C'.
                APPEND wa_accountpayable TO gt_accountpayable.
                CLEAR  wa_accountpayable.

                wa_currency_amount-itemno_acc = vg_buzei.
                wa_currency_amount-currency   = wa_t001-waers. "TEXT-p05.
                wa_currency_amount-amt_doccur = wa_tabin_aux-valor .
                APPEND wa_currency_amount TO gt_currency_amount.
                CLEAR  wa_currency_amount.


              ELSE. "Fornecedor Empresa

                MOVE-CORRESPONDING wa_tabin_aux TO  wa_tabout.
                wa_tabout-msg_ret    = TEXT-m06.
                wa_tabout-codretorno = c_500.
                APPEND wa_tabout TO gt_tabout.
                CLEAR  wa_tabout.


              ENDIF.


            ELSE. "Fornecedor

              MOVE-CORRESPONDING wa_tabin_aux TO  wa_tabout.
              wa_tabout-msg_ret    = TEXT-m05.
              wa_tabout-codretorno = c_500.
              APPEND wa_tabout TO gt_tabout.
              CLEAR  wa_tabout.

            ENDIF.

          ELSE. "Conta

            MOVE-CORRESPONDING wa_tabin_aux TO  wa_tabout.
            wa_tabout-msg_ret    = TEXT-m04.
            wa_tabout-codretorno = c_500.
            APPEND wa_tabout TO gt_tabout.
            CLEAR  wa_tabout.

          ENDIF.

        ENDLOOP.

****************************
* MONTA HEADER GERAÇÃO DO DOCUMENTO
****************************
        wa_header-username    = sy-uname.
        wa_header-comp_code   = wa_ztparam-valorpar2.
        wa_header-doc_date    = wa_tabin_aux-dt_remessa.
        wa_header-pstng_date  = wa_tabin_aux-dt_remessa.
        wa_header-ref_doc_no  = TEXT-t01.
        wa_header-doc_type    = wa_ztparam-valorpar3.

        CONCATENATE: wa_tabin_aux-remessa '-' wa_tabin_aux-kostl INTO wa_header-header_txt .

* Monta Dt. vencimento
        CONCATENATE: wa_tabin_aux-dt_remessa+0(6) wa_ztparam-valorpar4
                     INTO vg_dtven.

* Numero Fornecedor Banco
        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING
            input  = wa_ztparam-valorpar1
          IMPORTING
            output = wa_accountpayable-vendor_no.

        vg_buzei = vg_buzei + 1.
        wa_accountpayable-itemno_acc = vg_buzei.
        wa_accountpayable-item_text  = TEXT-m09      .
        wa_accountpayable-bline_date = vg_dtven      .
        wa_accountpayable-pmnttrms   = TEXT-c01      .
        APPEND wa_accountpayable TO gt_accountpayable.
        CLEAR  wa_accountpayable.

        wa_currency_amount-itemno_acc = vg_buzei.
        wa_currency_amount-currency   = wa_t001-waers. "TEXT-p05.
        wa_currency_amount-amt_doccur = vg_vltot * -1.
        APPEND wa_currency_amount TO gt_currency_amount.
        CLEAR  wa_currency_amount.


******Tarifa*************
        IF NOT vg_tarif IS INITIAL.

          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = wa_ztparam-valorpar5
            IMPORTING
              output = wa_accountgl-gl_account.

          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = wa_ztparam-valorpar6
            IMPORTING
              output = wa_accountgl-costcenter.

          vg_buzei = vg_buzei + 1.
          wa_accountgl-itemno_acc = vg_buzei.
          wa_accountgl-item_text  = TEXT-m11.
          APPEND wa_accountgl TO gt_accountgl.
          CLEAR wa_accountgl.

          wa_currency_amount-itemno_acc = vg_buzei.
          wa_currency_amount-currency   = wa_t001-waers. "TEXT-p05.
          wa_currency_amount-amt_doccur = vg_tarif .
          APPEND wa_currency_amount TO gt_currency_amount.
          CLEAR  wa_currency_amount.

        ENDIF.

******Imposto*************
        IF NOT vg_impos IS INITIAL.

          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = wa_ztparam-valorpar7
            IMPORTING
              output = wa_accountgl-gl_account.
**
**          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
**            EXPORTING
**              input  = wa_ztparam-valorpar6
**            IMPORTING
**              output = wa_accountgl-costcenter.

          vg_buzei = vg_buzei + 1.
          wa_accountgl-itemno_acc = vg_buzei.
          wa_accountgl-item_text  = TEXT-m11.
          APPEND wa_accountgl TO gt_accountgl.
          CLEAR wa_accountgl.

          wa_currency_amount-itemno_acc = vg_buzei.
          wa_currency_amount-currency   = wa_t001-waers. "TEXT-p05.
          wa_currency_amount-amt_doccur = vg_impos .
          APPEND wa_currency_amount TO gt_currency_amount.
          CLEAR  wa_currency_amount.

        ENDIF.


        CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
          EXPORTING
            documentheader = wa_header
          TABLES
            accountgl      = gt_accountgl
            accountpayable = gt_accountpayable
            currencyamount = gt_currency_amount
            return         = gt_return.

        READ TABLE gt_return INDEX 1.

        IF gt_return-type EQ 'S'.

          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' " DESTINATION 'QA1CLNT500'
            EXPORTING
              wait   = 'X'
            IMPORTING
              return = gt_return.

          READ TABLE gt_return INDEX 1.

          "MOVE-CORRESPONDING wa_tabin_aux TO  wa_tabout. " SIGLESIAS 13.06.2022
          wa_tabout-kostl = wa_tabin_aux-kostl. " SIGLESIAS 20.06.2022
          wa_tabout-codretorno = c_200.
          wa_tabout-idsap      = gt_return-message_v2.
          APPEND wa_tabout TO gt_tabout.
          CLEAR  wa_tabout.

        ELSE.

          READ TABLE gt_return INDEX 2.

          "MOVE-CORRESPONDING wa_tabin_aux TO  wa_tabout. " SIGLESIAS 13.06.2022
          wa_tabout-kostl = wa_tabin_aux-kostl. " SIGLESIAS 20.06.2022
          wa_tabout-msg_ret    = gt_return-message.
          wa_tabout-codretorno = c_500.
          APPEND wa_tabout TO gt_tabout.
          CLEAR  wa_tabout.

        ENDIF.

      ENDIF.

    ENDIF.

  ELSE.

********************************
** Se informações vazia
********************************
    wa_tabout-msg_ret    = TEXT-m08.
    wa_tabout-codretorno = c_500.
    APPEND wa_tabout TO gt_tabout.
    CLEAR  wa_tabout.

  ENDIF.

  zfatout = gt_tabout[].

ENDFUNCTION.
