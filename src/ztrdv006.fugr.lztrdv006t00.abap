*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTRDV006........................................*
DATA:  BEGIN OF STATUS_ZTRDV006                      .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTRDV006                      .
CONTROLS: TCTRL_ZTRDV006
            TYPE TABLEVIEW USING SCREEN '9000'.
*.........table declarations:.................................*
TABLES: *ZTRDV006                      .
TABLES: ZTRDV006                       .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
