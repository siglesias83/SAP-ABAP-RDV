*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTRDV002........................................*
DATA:  BEGIN OF STATUS_ZTRDV002                      .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTRDV002                      .
CONTROLS: TCTRL_ZTRDV002
            TYPE TABLEVIEW USING SCREEN '9000'.
*.........table declarations:.................................*
TABLES: *ZTRDV002                      .
TABLES: ZTRDV002                       .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
