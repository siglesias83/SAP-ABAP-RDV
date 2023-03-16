*&---------------------------------------------------------------------*
*& Include          ZFI_RDV_BB_REPROCESS_TOP
*&---------------------------------------------------------------------*

*--------------------------------------------------------------------*
* TABLES
*--------------------------------------------------------------------*
TABLES: t001, cskt, ztrdv002.

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
* GLOBAL STRUCTURES
*--------------------------------------------------------------------*
DATA: gs_rif_ex TYPE REF TO cx_root,
      gs_return TYPE bapireturn1.

*--------------------------------------------------------------------*
* GLOBAL TABLES
*--------------------------------------------------------------------*
DATA: gt_viceri_input  TYPE zrdv_send_viceri_request,
      gt_viceri_output TYPE zrdv_send_viceri_response.

*----------------------------------------------------------------------
* SERVICE VARIABLES
*----------------------------------------------------------------------
DATA: gr_proxy_viceri TYPE REF TO zrdv_co_viceri,
      m_seq_prot      TYPE REF TO if_wsprotocol_sequence,
      m_seq           TYPE REF TO if_ws_client_sequence,
      l_wsprot        TYPE REF TO if_wsprotocol,
      gv_seq          TYPE srt_seq_id.

*----------------------------------------------------------------------
* CONSTANTS
*---------------------------------------------------------------------
DATA: bandeira(2) TYPE c VALUE 'BB'.
