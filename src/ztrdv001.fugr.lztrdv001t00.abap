*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTRDV001........................................*
DATA:  BEGIN OF STATUS_ZTRDV001                      .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTRDV001                      .
CONTROLS: TCTRL_ZTRDV001
            TYPE TABLEVIEW USING SCREEN '9000'.
*.........table declarations:.................................*
TABLES: *ZTRDV001                      .
TABLES: ZTRDV001                       .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
