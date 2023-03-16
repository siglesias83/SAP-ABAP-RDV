*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTRDV003........................................*
DATA:  BEGIN OF STATUS_ZTRDV003                      .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTRDV003                      .
CONTROLS: TCTRL_ZTRDV003
            TYPE TABLEVIEW USING SCREEN '9000'.
*.........table declarations:.................................*
TABLES: *ZTRDV003                      .
TABLES: ZTRDV003                       .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
