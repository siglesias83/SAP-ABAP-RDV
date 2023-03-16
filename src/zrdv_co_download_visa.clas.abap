class ZRDV_CO_DOWNLOAD_VISA definition
  public
  inheriting from CL_PROXY_CLIENT
  create public .

public section.

  methods CONSTRUCTOR
    importing
      !LOGICAL_PORT_NAME type PRX_LOGICAL_PORT_NAME optional
    raising
      CX_AI_SYSTEM_FAULT .
  methods DOWNLOAD_VISA
    importing
      !INPUT type ZRDV_DOWNLOAD_VISA
    exporting
      !OUTPUT type ZRDV_DOWNLOAD_VISA_RESPONSE
    raising
      CX_AI_SYSTEM_FAULT .
protected section.
private section.
ENDCLASS.



CLASS ZRDV_CO_DOWNLOAD_VISA IMPLEMENTATION.


  method CONSTRUCTOR.

  super->constructor(
    class_name          = 'ZRDV_CO_DOWNLOAD_VISA'
    logical_port_name   = logical_port_name
  ).

  endmethod.


  method DOWNLOAD_VISA.

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
      method_name = 'DOWNLOAD_VISA'
    changing
      parmbind_tab = lt_parmbind
  ).

  endmethod.
ENDCLASS.
