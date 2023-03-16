*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTRDV005........................................*
DATA:  BEGIN OF STATUS_ZTRDV005                      .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTRDV005                      .
CONTROLS: TCTRL_ZTRDV005
            TYPE TABLEVIEW USING SCREEN '9000'.
*.........table declarations:.................................*
TABLES: *ZTRDV005                      .
TABLES: ZTRDV005                       .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
