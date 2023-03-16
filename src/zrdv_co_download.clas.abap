class ZRDV_CO_DOWNLOAD definition
  public
  inheriting from CL_PROXY_CLIENT
  create public .

public section.

  methods CONSTRUCTOR
    importing
      !LOGICAL_PORT_NAME type PRX_LOGICAL_PORT_NAME optional
    raising
      CX_AI_SYSTEM_FAULT .
  methods DOWNLOAD_VIP433
    importing
      !INPUT type ZRDV_DOWNLOAD_VIP433REQUEST
    exporting
      !OUTPUT type ZRDV_DOWNLOAD_VIP433RESPONSE
    raising
      CX_AI_SYSTEM_FAULT .
  methods DOWNLOAD_VIP435
    importing
      !INPUT type ZRDV_DOWNLOAD_VIP435REQUEST
    exporting
      !OUTPUT type ZRDV_DOWNLOAD_VIP435RESPONSE
    raising
      CX_AI_SYSTEM_FAULT .
  methods DOWNLOAD_VIP798
    importing
      !INPUT type ZRDV_DOWNLOAD_VIP798REQUEST
    exporting
      !OUTPUT type ZRDV_DOWNLOAD_VIP798RESPONSE
    raising
      CX_AI_SYSTEM_FAULT .
protected section.
private section.
ENDCLASS.



CLASS ZRDV_CO_DOWNLOAD IMPLEMENTATION.


  method CONSTRUCTOR.

  super->constructor(
    class_name          = 'ZRDV_CO_DOWNLOAD'
    logical_port_name   = logical_port_name
  ).

  endmethod.


  method DOWNLOAD_VIP433.

  data:
    ls_parmbind type abap_parmbind,
    lt_parmbind type abap_parmbind_tab.

  ls_parmbind-name = 'INPUT'.
  ls_parmbind-kind = cl_abap_objectdescr=>importing.
  get reference of INPUT into ls_parmbind-value.
  insert ls_parmbind into table lt_parmbind.

  ls_parmbind-name = 'OUTPUT'.
  ls_parmbind-kind = cl_abap_objectdescr=>exporting.
  get reference of OUTPUT into ls_parmbind-value.
  insert ls_parmbind into table lt_parmbind.

  if_proxy_client~execute(
    exporting
      method_name = 'DOWNLOAD_VIP433'
    changing
      parmbind_tab = lt_parmbind
  ).

  endmethod.


  method DOWNLOAD_VIP435.

  data:
    ls_parmbind type abap_parmbind,
    lt_parmbind type abap_parmbind_tab.

  ls_parmbind-name = 'INPUT'.
  ls_parmbind-kind = cl_abap_objectdescr=>importing.
  get reference of INPUT into ls_parmbind-value.
  insert ls_parmbind into table lt_parmbind.

  ls_parmbind-name = 'OUTPUT'.
  ls_parmbind-kind = cl_abap_objectdescr=>exporting.
  get reference of OUTPUT into ls_parmbind-value.
  insert ls_parmbind into table lt_parmbind.

  if_proxy_client~execute(
    exporting
      method_name = 'DOWNLOAD_VIP435'
    changing
      parmbind_tab = lt_parmbind
  ).

  endmethod.


  method DOWNLOAD_VIP798.

  data:
    ls_parmbind type abap_parmbind,
    lt_parmbind type abap_parmbind_tab.

  ls_parmbind-name = 'INPUT'.
  ls_parmbind-kind = cl_abap_objectdescr=>importing.
  get reference of INPUT into ls_parmbind-value.
  insert ls_parmbind into table lt_parmbind.

  ls_parmbind-name = 'OUTPUT'.
  ls_parmbind-kind = cl_abap_objectdescr=>exporting.
  get reference of OUTPUT into ls_parmbind-value.
  insert ls_parmbind into table lt_parmbind.

  if_proxy_client~execute(
    exporting
      method_name = 'DOWNLOAD_VIP798'
    changing
      parmbind_tab = lt_parmbind
  ).

  endmethod.
ENDCLASS.
