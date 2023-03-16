*&---------------------------------------------------------------------*
*& Include          ZFI_RDV_BB_PROCESS_TOP
*&---------------------------------------------------------------------*

*--------------------------------------------------------------------*
* TABLES
*--------------------------------------------------------------------*
TABLES: t001 , csks, ztrdv007.

*--------------------------------------------------------------------*
* TYPES
*--------------------------------------------------------------------*
TYPES: ty_bukrs     TYPE RANGE OF bukrs.

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
        campo31 type string,
        campo32 type string,
        campo33 type string,
        campo34 type string,
        campo35 type string,
        campo36 type string,
        campo37 type string,
        campo38 type string,
        campo39 type string,
        campo40 type string,
        campo41 type string,
        campo42 type string,
        campo43 type string,
        campo44 type string,
        campo45 type string,
        campo46 type string,
        campo47 type string,
        campo48 type string,
        campo49 type string,
        campo50 type string,
       end of ty_quebra.

*--------------------------------------------------------------------*
* GLOBAL VARIABLES
*--------------------------------------------------------------------*
DATA: gv_msg_error    TYPE string,
      gv_msg_type(1)  TYPE c,
      gv_cartao       TYPE ad_smtpadr,
      gv_pernr        TYPE pa0002-pernr,
      gv_cpf          TYPE stcd2,
      gv_cpf_nr       TYPE pbr_cpfnr,
      gv_data_criacao TYPE dats,
      gv_count        TYPE i.

*--------------------------------------------------------------------*
* GLOBAL RANGES
*--------------------------------------------------------------------*
DATA: gr_arquivo TYPE RANGE OF zrdv_arq.

*--------------------------------------------------------------------*
* GLOBAL STRUCTURES
*--------------------------------------------------------------------*
DATA: gs_int_log TYPE ztrdv001,
      gs_rif_ex  TYPE REF TO cx_root,
      gs_arquivo TYPE ZRDV_LISTA,
      gs_bukrs   TYPE LINE OF ty_bukrs,
      gs_return  TYPE bapireturn1.

data: gs_quebra  type ty_quebra.

data: gs_sort      type lvc_s_sort,
      gs_layout    type lvc_s_layo,
      gs_print     type lvc_s_prnt,
      gs_alv       type zsrdv007  .       "Estrutura com os campo do relatório

*--------------------------------------------------------------------*
* GLOBAL TABLES
*--------------------------------------------------------------------*
DATA: gt_ztrdv001       TYPE TABLE OF ztrdv001,
      gt_return         TYPE table of bapireturn1,
      gt_lista_input    type zrdv_lista_downloads_visa,
      gt_lista_output   type zrdv_lista_downloads_visa_resp,
      gt_downarq_input  TYPE ZRDV_DOWNLOAD_VISA,
      gt_downarq_output TYPE ZRDV_DOWNLOAD_VISA_RESPONSE,
      gt_viceri_input   TYPE zrdv_send_viceri_request,
      gt_viceri_output  TYPE zrdv_send_viceri_response.


data: gt_bloco_0   type table of ty_quebra,
      gt_bloco_3   type table of ty_quebra,
      gt_bloco_4   type table of ty_quebra,
      gt_bloco_5   type table of ty_quebra,
      gt_bloco_16  type table of ty_quebra.


data: gt_fieldcat   type lvc_t_fcat,
*      gt_select     type table of zsrdv007, "Estrutura com os campo do relatório
*      gt_processa_s type table of zsrdv007, "Estrutura com os campo do relatório
      gt_alv        type table of ztrdv007, "Estrutura com os campo do relatório
      gt_processa   type table of ztrdv007, "Estrutura com os campo do relatório
      gt_sort       type lvc_t_sort
      .


*----------------------------------------------------------------------
* SERVICE VARIABLES
*----------------------------------------------------------------------
data: gr_proxy_lista    type ref to zrdv_co_lista_downloads_visa,
      gr_proxy_download type ref to zrdv_co_download_visa,
      gr_proxy_viceri   TYPE REF TO zrdv_co_viceri,
      m_seq_prot        TYPE REF TO if_wsprotocol_sequence,
      m_seq             TYPE REF TO if_ws_client_sequence,
      l_wsprot          TYPE REF TO if_wsprotocol,
      gv_seq            TYPE srt_seq_id.

*----------------------------------------------------------------------
* CONSTANTS
*---------------------------------------------------------------------
DATA: bandeira(2) TYPE c VALUE 'VI'.

*----------------------------------------------------------------------
* CONSTANTS
*---------------------------------------------------------------------
 RANGES: r_cc FOR pa0105-usrid.

  r_cc-sign   = 'I'  .
  r_cc-option = 'CP' .
  r_cc-low    = 'VI*'.

  APPEND r_cc.
*----------------------------------------------------------------------*
* Container -----------------------------------------------------------*
*----------------------------------------------------------------------*
data: go_container type ref to cl_gui_custom_container,
      go_alv       type ref to cl_gui_alv_grid.
