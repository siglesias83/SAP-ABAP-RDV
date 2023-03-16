*&---------------------------------------------------------------------*
*& Include          ZFI_RDV_BB_PROCESS_TOP
*&---------------------------------------------------------------------*

*--------------------------------------------------------------------*
* TABLES
*--------------------------------------------------------------------*
TABLES: t001 , csks.

*--------------------------------------------------------------------*
* TYPES
*--------------------------------------------------------------------*
TYPES: ty_bukrs     TYPE RANGE OF bukrs.

*--------------------------------------------------------------------*
* GLOBAL VARIABLES
*--------------------------------------------------------------------*
DATA: gv_msg_error    TYPE string,
      gv_msg_type(1)  TYPE c,
      gv_cartao       TYPE ad_smtpadr,
      gv_pernr        TYPE persno,
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
      gs_arquivo TYPE zrdv_arquivos,
      gs_bukrs   TYPE LINE OF ty_bukrs,
      gs_return  TYPE bapireturn1.

*--------------------------------------------------------------------*
* GLOBAL TABLES
*--------------------------------------------------------------------*
DATA: gt_ztrdv001      TYPE TABLE OF ztrdv001,
      gt_return        TYPE TABLE OF bapireturn1,
      gt_lista_input   TYPE zrdv_lista_downloads_request,
      gt_lista_output  TYPE zrdv_lista_downloads_response,
      gt_vip433_input  TYPE zrdv_download_vip433request,
      gt_vip433_output TYPE zrdv_download_vip433response,
      gt_viceri_input  TYPE zrdv_send_viceri_request,
      gt_viceri_output TYPE zrdv_send_viceri_response,
      gt_vip435_input  TYPE zrdv_download_vip435request,
      gt_vip435_output TYPE zrdv_download_vip435response,
      gt_vip798_input  TYPE zrdv_download_vip798request,
      gt_vip798_output TYPE zrdv_download_vip798response.

*----------------------------------------------------------------------
* SERVICE VARIABLES
*----------------------------------------------------------------------
DATA: gr_proxy_lista    TYPE REF TO zrdv_co_lista_downloads,
      gr_proxy_download TYPE REF TO zrdv_co_download,
      gr_proxy_viceri   TYPE REF TO zrdv_co_viceri,
      m_seq_prot        TYPE REF TO if_wsprotocol_sequence,
      m_seq             TYPE REF TO if_ws_client_sequence,
      l_wsprot          TYPE REF TO if_wsprotocol,
      gv_seq            TYPE srt_seq_id.

*----------------------------------------------------------------------
* CONSTANTS
*---------------------------------------------------------------------
DATA: bandeira(2) TYPE c VALUE 'BB'.
