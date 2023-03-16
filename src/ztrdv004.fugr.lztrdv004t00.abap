*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTRDV004........................................*
DATA:  BEGIN OF STATUS_ZTRDV004                      .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTRDV004                      .
CONTROLS: TCTRL_ZTRDV004
            TYPE TABLEVIEW USING SCREEN '9000'.
*.........table declarations:.................................*
TABLES: *ZTRDV004                      .
TABLES: ZTRDV004                       .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
