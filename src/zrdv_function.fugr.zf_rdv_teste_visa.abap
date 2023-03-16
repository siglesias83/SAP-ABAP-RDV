FUNCTION ZF_RDV_TESTE_VISA.
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     REFERENCE(ZT_TESTE) TYPE  ZTT_91_TEXT_PAGO
*"----------------------------------------------------------------------


*  DATA: gr_proxy_lista    TYPE REF TO zrdv_co_lista_downloads,
*        gr_proxy_download TYPE REF TO zrdv_co_download_visa.
*
*data:
*INPUT  TYPE ZRDV_DOWNLOAD_VISA,
*OUTPUT  TYPE ZRDV_DOWNLOAD_VISA_RESPONSE.
*DATA: lt_soli TYPE soli_tab.
*
*
*Data: lv_xstring  TYPE xstring,       "Xstring
*      lv_len TYPE i,                  "Length
*      lt_content  TYPE soli_tab,      "Content
*      lv_string   TYPE string,        "Text
*      lv_base64   TYPE string.        "Base64
*
*  TRY.
*      CREATE OBJECT gr_proxy_download
*        EXPORTING
*          logical_port_name = 'ZRDV_DOWNLOAD_VISA_PORT'.
*
**    CATCH cx_ai_system_fault INTO gs_rif_ex.
**      gv_msg_error = gs_rif_ex->get_text( ).
**      gv_msg_type = 'I'.
*  ENDTRY.
*
*
*  input-nome = '6_10021160_900441048_100_20220720091213.PGP'.
*
*  TRY.
*      CALL METHOD gr_proxy_download->download_visa
*        EXPORTING
*          input  = INPUT
*        IMPORTING
*          output = OUTPUT.
*
***  end sequencing and commit work
**      m_seq->end( ).
**      cl_soap_tx_factory=>commit_work( ).
**
**    CATCH cx_ai_system_fault INTO gs_rif_ex.
**      gv_msg_error = gs_rif_ex->get_text( ).
**      gv_msg_type = 'I'.
*
*  ENDTRY.

*  CALL FUNCTION 'CONVERT_STRING_TO_TABLE'
*    EXPORTING
**      i_string         = lv_base64_pdf
*      i_string         = OUTPUT-linha
*      i_tabline_length = 255
*    TABLES
*      et_table         = lt_soli.



*Convert Base64 string to XString.
*
*    CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
*      EXPORTING
*        INPUT         = OUTPUT-linha
*     IMPORTING
*       OUTPUT         = lv_xstring
*     EXCEPTIONS
*       FAILED         = 1
*       OTHERS         = 2.
*
**Convert Text to Binary
*    CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
*      EXPORTING
*        buffer        = lv_xstring
*      IMPORTING
*        output_length = lv_len
*      TABLES
*        binary_tab    = lt_content.
*
**Convert Binary to String
*    CALL FUNCTION 'SCMS_BINARY_TO_STRING'
*      EXPORTING
*        input_length = lv_len
*      IMPORTING
*        text_buffer  = lv_string
*      TABLES
*        binary_tab   = lt_content
*      EXCEPTIONS
*        failed       = 1
*        OTHERS       = 2.
*
*
*
*
*
*
*  data: lv_zstring  type xstring.
*
*  CALL FUNCTION 'SCMS_BASE64_DECODE_STR'
*    EXPORTING
*      input          = OUTPUT-linha
**     UNESCAPE       = 'X'
*   IMPORTING
*     OUTPUT         = lv_zstring
**   EXCEPTIONS
**     FAILED         = 1
**     OTHERS         = 2
*            .
*  IF sy-subrc <> 0.
** Implement suitable error handling here
*  ENDIF.
*
*
*  CALL FUNCTION 'SCMS_XSTRING_TO_BINARY'
*    EXPORTING
*      buffer                = lv_zstring
**     APPEND_TO_TABLE       = ' '
**   IMPORTING
**     OUTPUT_LENGTH         =
*    tables
*      binary_tab            = lt_soli
*            .
*
*

  types: begin of ty_quebra,
          campo1  type string,
          campo2  type string,
          campo3  type string,
          campo4  type string,
          campo5  type string,
          campo6  type string,
          campo7  type string,
          campo8  type string,
          campo9  type string,
          campo10 type string,
          campo11 type string,
          campo12 type string,
          campo13 type string,
          campo14 type string,
          campo15 type string,
          campo16 type string,
          campo17 type string,
          campo18 type string,
          campo19 type string,
          campo20 type string,
          campo21 type string,
          campo22 type string,
          campo23 type string,
          campo24 type string,
          campo25 type string,
          campo26 type string,
          campo27 type string,
          campo28 type string,
          campo29 type string,
          campo30 type string,
         end of ty_quebra.

   data: gt_bloco_0   type table of ty_quebra,
         gt_bloco_3   type table of ty_quebra,
         gt_bloco_4   type table of ty_quebra,
         gt_bloco_5   type table of ty_quebra,
         gt_bloco_16  type table of ty_quebra.

   data: ls_quebra type ty_quebra.

*   data: W_TAB_FIELD TYPE c VALUE cl_abap_char_utilities=>CR_LF.
   data: W_TAB_FIELD TYPE c VALUE cl_abap_char_utilities=>HORIZONTAL_TAB.


   loop at ZT_TESTE
      into data(ls_teste).

     data(lv_len) = strlen( ls_teste ).

     lv_len = lv_len - 18.

     data(lv_nome) = ls_teste+lv_len(6).


   endloop.

ENDFUNCTION.
