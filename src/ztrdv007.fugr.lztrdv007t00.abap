*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTRDV007........................................*
DATA:  BEGIN OF STATUS_ZTRDV007                      .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTRDV007                      .
CONTROLS: TCTRL_ZTRDV007
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTRDV007                      .
TABLES: ZTRDV007                       .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
