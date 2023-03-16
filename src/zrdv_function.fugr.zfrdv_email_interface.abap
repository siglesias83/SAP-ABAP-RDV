FUNCTION zfrdv_email_interface .
*"----------------------------------------------------------------------
*"*"Interface local:
*"  EXPORTING
*"     REFERENCE(RETURN) LIKE  BAPIRETURN1 STRUCTURE  BAPIRETURN1
*"  TABLES
*"      ZTRDV STRUCTURE  ZTRDV001
*"----------------------------------------------------------------------
*--------------------------------------------------------------------*
* INTERNAL TABLE
*--------------------------------------------------------------------*

*Tabelas Internas
  DATA: lt_ztrdv     TYPE TABLE OF ztrdv001,
        lt_grp_email TYPE TABLE OF ztrdv005,
        lt_email     TYPE TABLE OF ztrdv005.

*Estruturas
  DATA: ls_ztrdv     TYPE ztrdv001,
        ls_grp_email TYPE ztrdv005.

*--------------------------------------------------------------------*
* EMAIL
*--------------------------------------------------------------------*
  DATA: gf_objtxt     TYPE solisti1,
        gt_objtxt     TYPE TABLE OF solisti1,
        gr_request    TYPE REF TO cl_bcs,
        gv_subject    TYPE so_obj_des,
        gr_recipient  TYPE REF TO if_recipient_bcs,
        gr_sender     TYPE REF TO if_sender_bcs,
        gr_document   TYPE REF TO cl_document_bcs,
        gr_exception  TYPE REF TO cx_bcs,
        gt_recipients TYPE TABLE OF ad_smtpadr,
        gv_recipient  TYPE ad_smtpadr,
        l_address     TYPE so_rec_ext,
        l_char(20)    TYPE c.

*--------------------------------------------------------------------*
* FUNCTION - ENVIAR EMAIL
*--------------------------------------------------------------------*

  " Seleciona grupos de email
  SELECT * FROM ztrdv005
    WHERE tipo = '0'
    INTO TABLE @lt_grp_email.
  CHECK sy-subrc IS INITIAL.
  SORT lt_grp_email BY empresa.
  DELETE ADJACENT DUPLICATES FROM lt_grp_email COMPARING empresa.

  " Cria mensagens para grupos de email
  LOOP AT lt_grp_email INTO ls_grp_email.
    CLEAR:gt_recipients , lt_ztrdv, gt_objtxt .

    " Seleciona destinatários para grupo técnico
    SELECT email FROM ztrdv005
      WHERE ( empresa = @ls_grp_email-empresa )
        AND tipo = '0'
      APPENDING TABLE @gt_recipients.
    CHECK sy-subrc IS INITIAL.

    " Seleciona dados para grupo
    IF ls_grp_email-empresa = '*'.
      lt_ztrdv = ztrdv[].
    ELSE.
      LOOP AT ztrdv INTO ls_ztrdv WHERE empresa = ls_grp_email-empresa.
        APPEND ls_ztrdv TO lt_ztrdv.
      ENDLOOP.
    ENDIF.
    CHECK NOT lt_ztrdv IS INITIAL.

    " Set the Body background colour
    gf_objtxt-line = '<body bgcolor = "WHITE">'.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR gf_objtxt.
    " Set font color and its type
    CONCATENATE '<FONT COLOR = "BLACK" face="Calibri">' '<p>' INTO gf_objtxt-line.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR gf_objtxt.

    " Prepare mail body
    CONCATENATE '<p>' 'Bom dia.' '</p>' INTO gf_objtxt-line.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR gf_objtxt.

    gf_objtxt-line = space.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR gf_objtxt.

    CONCATENATE  sy-datum+6(2)  '/'  sy-datum+4(2) '/' sy-datum+0(4) INTO l_char.
    CONCATENATE '<p>'
                '    Segue erros processamento download arquivos dia: '  l_char '.'
                '</p>'
                   INTO gf_objtxt-line SEPARATED BY space.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR:  gf_objtxt, l_char.

    gf_objtxt-line = '<center>'.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR  gf_objtxt.

    " Header Table
    gf_objtxt-line = '<TABLE  width= "100%" border="1">'.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR  gf_objtxt.

    CONCATENATE '<TR ><td align = "CENTER" BGCOLOR = "#596468">'
                '<FONT COLOR = "WHITE"><B>Data</B> </FONT>'
                '</td>'  INTO gf_objtxt-line.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR  gf_objtxt.

    CONCATENATE '<td align = "CENTER" BGCOLOR = "#596468">'
                '<FONT COLOR = "WHITE"><B>Hora</B> </FONT>'
                '</td>'  INTO gf_objtxt-line.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR  gf_objtxt.

    CONCATENATE '<td align = "CENTER" BGCOLOR = "#596468">'
                '<FONT COLOR = "WHITE"><B>Empresa</B> </FONT>'
                '</td>'  INTO gf_objtxt-line.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR  gf_objtxt.


    CONCATENATE '<td align = "CENTER" BGCOLOR = "#596468">'
                '<FONT COLOR = "WHITE"><B>Interface</B> </FONT>'
                '</td>'  INTO gf_objtxt-line.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR  gf_objtxt.

    CONCATENATE '<td align = "CENTER" BGCOLOR = "#596468">'
                '<FONT COLOR = "WHITE"><B>Arquivo</B> </FONT>'
                '</td>'  INTO gf_objtxt-line.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR  gf_objtxt.

    CONCATENATE '<td align = "CENTER" BGCOLOR = "#596468">'
                '<FONT COLOR = "WHITE"><B>Mensagem</B> </FONT>'
                '</td></tr>'  INTO gf_objtxt-line.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR  gf_objtxt.

    " Data Table
    LOOP AT lt_ztrdv INTO ls_ztrdv.
      WRITE: ls_ztrdv-data TO l_char DD/MM/YYYY.
      CONCATENATE '<TR><td align = "LEFT">'
                  '<FONT COLOR = "BLACK">' l_char '</FONT>'
                  '</td>'  INTO gf_objtxt-line.
      APPEND gf_objtxt TO gt_objtxt.
      CLEAR:  gf_objtxt, l_char.

      CONCATENATE ls_ztrdv-hora(2) ':' ls_ztrdv-hora(2) ':' ls_ztrdv-hora+4(2) INTO l_char.
      CONCATENATE '<td align = "LEFT">'
                  '<FONT COLOR = "BLACK">' l_char '</FONT>'
                  '</td>'  INTO gf_objtxt-line.
      APPEND gf_objtxt TO gt_objtxt.
      CLEAR:  gf_objtxt, l_char.

      CONCATENATE '<td align = "LEFT">'
                  '<FONT COLOR = "BLACK">' ls_ztrdv-empresa '</FONT>'
                  '</td>'  INTO gf_objtxt-line.
      APPEND gf_objtxt TO gt_objtxt.
      CLEAR:  gf_objtxt.

      CONCATENATE '<td align = "LEFT">'
                  '<FONT COLOR = "BLACK">' ls_ztrdv-interface '</FONT>'
                  '</td>'  INTO gf_objtxt-line.
      APPEND gf_objtxt TO gt_objtxt.
      CLEAR:  gf_objtxt.

      CONCATENATE '<td align = "LEFT">'
                  '<FONT COLOR = "BLACK">' ls_ztrdv-arquivo '</FONT>'
                  '</td>'  INTO gf_objtxt-line.
      APPEND gf_objtxt TO gt_objtxt.
      CLEAR:  gf_objtxt.

      REPLACE 'SoapFaulCodeName:' WITH '' INTO ls_ztrdv-mensagem.
      REPLACE 'SoapFaulCodeNamespace:' WITH ' ' INTO ls_ztrdv-mensagem.
      CONCATENATE '<td align = "LEFT">'
                  '<FONT COLOR = "BLACK">' ls_ztrdv-mensagem+0(197) '</FONT>'
                  '</td></tr>'  INTO gf_objtxt-line.
      APPEND gf_objtxt TO gt_objtxt.
      CLEAR  gf_objtxt.
    ENDLOOP.

    gf_objtxt-line = '</TABLE>'.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR  gf_objtxt.
    gf_objtxt-line = '</center>'.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR  gf_objtxt.

    gf_objtxt-line =   '<br>Obrigado!<br />'.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR gf_objtxt.

    gf_objtxt-line = '<br><br><b><center><i><font color = "BLUE">Este e-mail é gerado automáticamente, não responder.'.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR gf_objtxt.

    gf_objtxt-line = '</FONT></body>'.
    APPEND gf_objtxt TO gt_objtxt.
    CLEAR gf_objtxt.

    TRY.
        gr_request = cl_bcs=>create_persistent( ).

        " Create necessary parameters for e-mail
        gv_subject = 'RDV - Erro download arquivos BB'.

        gr_document = cl_document_bcs=>create_document(
          i_type = 'HTM'
          i_text = gt_objtxt
          i_subject = gv_subject ).

        " Set the document to e-mail body
        gr_request->set_document( gr_document ).

        " Set sender
        gr_sender = cl_cam_address_bcs=>create_internet_address(
          i_address_string = 'rdv_bb@eurofarma.com'
          i_address_name = 'RDV_BB' ).
        gr_request->set_sender( gr_sender ).

        " Set receivers
        LOOP AT gt_recipients INTO DATA(gs_recipient).
          gr_recipient = cl_cam_address_bcs=>create_internet_address( gs_recipient ).
          gr_request->add_recipient( gr_recipient ).
        ENDLOOP.

        " Send e-mail
        gr_request->send( ).

        " Commit to send email
        COMMIT WORK.

        " Exception handling
      CATCH cx_bcs INTO gr_exception.
        return-message = gr_exception->get_text( ).
        CONCATENATE 'Email Interface -' return-message INTO return-message SEPARATED BY space.
        return-type = 'E'.
    ENDTRY.
  ENDLOOP.

ENDFUNCTION.
